#!/usr/bin/env bash

# To promote and sign a release that has been prepared by the build slaves, use:
#  release.sh

# To _only_ sign an existing release, use:
#  release.sh -s vx.y.z

set -e

webhost=direct.nodejs.org
webuser=dist
promotablecmd=dist-promotable
promotecmd=dist-promote
signcmd=dist-sign
customsshkey="" # let ssh and scp use default key
signversion=""

while getopts ":i:s:" option; do
    case "${option}" in
        i)
            customsshkey="-i ${OPTARG}"
            ;;
        s)
            signversion="${OPTARG}"
            ;;
        \?)
            echo "Invalid option -$OPTARG."
            exit 1
            ;;
        :)
            echo "Option -$OPTARG takes a parameter."
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

################################################################################
## Select a GPG key to use

echo "# Selecting GPG key ..."

# TODO(gib): My key shows up as two keys (it has a sec and an ssb line).
gpgkey=$(gpg --list-secret-keys --keyid-format SHORT | awk -F'( +|/)' '/^(sec|ssb)/{print $3}')
keycount=$(echo $gpgkey | wc -w)

if [ $keycount -eq 0 ]; then
  echo 'Need at least one GPG key, please make one with `gpg --gen-key`'
  echo 'You will also need to submit your key to a public keyserver, e.g.'
  echo '  https://sks-keyservers.net/i/#submit'
  exit 1
elif [ $keycount -ne 1 ]; then
  echo -e 'You have multiple GPG keys:\n'

  gpg --list-secret-keys

  while true; do
    echo $gpgkey | awk '{ for(i = 1; i <= NF; i++) { print i ") " $i; } }'
    echo -n 'Select a key: '
    read keynum

    if $(test "$keynum" -eq "$keynum" > /dev/null 2>&1); then
      _gpgkey=$(echo $gpgkey | awk '{ print $'${keynum}'}')
      keycount=$(echo $_gpgkey | wc -w)
      if [ $keycount -eq 1 ]; then
        echo ""
        gpgkey=$_gpgkey
        break
      fi
    fi
  done
fi

gpgfing=$(gpg --keyid-format 0xLONG --fingerprint $gpgkey | grep 'Key fingerprint =' | awk -F' = ' '{print $2}' | tr -d ' ')

if ! test "$(grep $gpgfing README.md)"; then
  echo 'Error: this GPG key fingerprint is not listed in ./README.md'
  exit 1
fi

echo "Using GPG key: $gpgkey"
echo "  Fingerprint: $gpgfing"


################################################################################
## Create and sign checksums file for a given version

function sign {
  echo -e "\n# Creating SHASUMS256.txt ..."

  local version=$1

  if ! git tag -v $version 2>&1 | grep "${gpgkey}" | grep key > /dev/null; then
    # TODO(gib): The key no longer shows up in the tag, not sure why.
    # My key: 77984A986EBC2AA786BC0F66B01FBB92821C587A
    # v8.9.0 tag: Git-EVTag-v0-SHA512: 03320c6f1f1431c9831753babe053d30b6b75dad8c01e76809537cb6dbe3a80fbfcd0a1661e6bef
98defdd5ad38e5c9996b7ab9bedd980981d92aaeae973ccd
    echo "Could not find signed tag for \"${version}\" or GPG key is not yours"
    exit 1
  fi

  ghtaggedversion=$(curl -sL https://raw.githubusercontent.com/nodejs/node/${version}/src/node_version.h \
      | awk '/define NODE_(MAJOR|MINOR|PATCH)_VERSION/{ v = v "." $3 } END{ v = "v" substr(v, 2); print v }')
  if [ "${version}" != "${ghtaggedversion}" ]; then
    echo "Could not find tagged version on github.com/nodejs/node, did you push your tag?"
    exit 1
  fi

  shapath=$(ssh ${customsshkey} ${webuser}@${webhost} $signcmd nodejs $version)

  if ! [[ ${shapath} =~ ^/.+/SHASUMS256.txt$ ]]; then
    echo 'Error: No SHASUMS file returned by sign!'
    exit 1
  fi

  echo -e "\n# Signing SHASUMS for ${version}..."

  shafile=$(basename $shapath)
  shadir=$(dirname $shapath)
  tmpdir="/tmp/_node_release.$$"

  mkdir -p $tmpdir

  scp ${customsshkey} ${webuser}@${webhost}:${shapath} ${tmpdir}/${shafile}

  gpg --default-key $gpgkey --clearsign --digest-algo SHA256 ${tmpdir}/${shafile}
  gpg --default-key $gpgkey --detach-sign --digest-algo SHA256 ${tmpdir}/${shafile}

  echo "Wrote to ${tmpdir}/"

  echo -e "Your signed ${shafile}.asc:\n"

  cat ${tmpdir}/${shafile}.asc

  echo ""

  while true; do
    echo -n "Upload files? [y/n] "
    yorn=""
    read yorn

    if [ "X${yorn}" == "Xn" ]; then
      break
    fi

    if [ "X${yorn}" == "Xy" ]; then
      scp ${customsshkey} ${tmpdir}/${shafile} ${tmpdir}/${shafile}.asc ${tmpdir}/${shafile}.sig ${webuser}@${webhost}:${shadir}/
      break
    fi
  done

  rm -rf $tmpdir
}


if [ -n "${signversion}" ]; then
    sign ${signversion}
    exit 0
fi

# else: do a normal release & promote

################################################################################
## Look for releases to promote

echo -e "\n# Checking for releases ..."

promotable=$(ssh ${customsshkey} ${webuser}@${webhost} $promotablecmd nodejs)

if [ "X${promotable}" == "X" ]; then
  echo "No releases to promote!"
  exit 0
fi

echo -e "Found the following releases / builds ready to promote:\n"
echo "$promotable" | sed 's/^/ * /'
echo ""

versions=$(echo "$promotable" | cut -d: -f1)

################################################################################
## Promote releases

for version in $versions; do
  while true; do
    files=$(echo "$promotable" | grep "^${version}" | sed 's/^'${version}': //')
    echo -n "Promote ${version} files (${files})? [y/n] "
    yorn=""
    read yorn

    if [ "X${yorn}" == "Xn" ]; then
      break
    fi

    if [ "X${yorn}" != "Xy" ]; then
      continue
    fi

    echo -e "\n# Promoting ${version}..."

    ssh ${customsshkey} ${webuser}@${webhost} $promotecmd nodejs $version

    sign $version

    break
  done
done
