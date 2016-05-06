#!/bin/bash -e

# handle arguments
while [ $# -gt 0 ]; do
  case "$1" in
    -p|--progress) PROGRESS="$2"; shift ;;
    -p=*) PROGRESS="${1#-p=}" ;;
    --progress=*) PROGRESS="${1#--progress=}" ;;
    --logfile) LOGFILE="$2"; shift ;;
    --logfile=*) LOGFILE="${1#--logfile=}" ;;
    *) echo "Unknown parameters $@" && exit 1;;
  esac
  shift
done

# Set default progress indicator to classic
PROGRESS=${PROGRESS:-classic}

# Add log to npm command if set
if [ -n "$LOGFILE" ]; then
  LOG="| tee ../$LOGFILE"
fi

# always change the working directory to the project's root directory
cd $(dirname $0)/..

# pass a $NODE environment variable from something like Makefile
# it should point to either ./node or ./node.exe, depending on the platform
if [ -z $NODE ]; then
  echo "No node executable provided. Bailing." >&2
  exit 0
fi

rm -rf test-npm

# make a copy of deps/npm to run the tests on
cp -r deps/npm test-npm

cd test-npm

# do a rm first just in case deps/npm contained these
rm -rf npm-cache npm-tmp npm-prefix
mkdir npm-cache npm-tmp npm-prefix

# set some npm env variables to point to our new temporary folders
export npm_config_cache="$(pwd)/npm-cache"
export npm_config_prefix="$(pwd)/npm-prefix"
export npm_config_tmp="$(pwd)/npm-tmp"

# ensure npm always uses the local node
export PATH="$(../$NODE -p 'require("path").resolve("..")'):$PATH"
unset NODE

# make sure the binaries from the non-dev-deps are available
node cli.js rebuild
# install npm devDependencies and run npm's tests
node cli.js install --ignore-scripts
# run the tests with logging if set
echo node cli.js run-script test-node -- --reporter=$PROGRESS $LOG
node cli.js run-script test-node -- --reporter=$PROGRESS $LOG

# clean up everything one single shot
cd .. && rm -rf test-npm
