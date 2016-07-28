#Port of tools/test-npm.sh to windows

# Handle parameters
param (
  [string]$progress = "classic",
  [string]$logfile
)

#always change the working directory to the project's root directory
$dp0 = (Get-Item -Path ".\" -Verbose).FullName
cd $~dp0\..

# Use rmdir to get around long file path issues
Cmd /C "rmdir /S /Q test-npm"
Remove-Item test-npm.tap -ErrorAction SilentlyContinue

#make a copy of deps/npm to run the tests on
Copy-Item deps\npm test-npm -Recurse
cd test-npm

# do a rm first just in case deps/npm contained these
Remove-Item npm-cache -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item npm-tmp -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item npm-prefix -Force -Recurse -ErrorAction SilentlyContinue

New-Item -ItemType directory -Path npm-cache
New-Item -ItemType directory -Path npm-tmp
New-Item -ItemType directory -Path npm-prefix

#set some npm env variables to point to our new temporary folders
$pwd = (Get-Item -Path ".\" -Verbose).FullName
Set-Variable -Name npm_config_cache -value ("$pwd\npm-cache") -Scope Global
Set-Variable -Name npm_config_prefix -value ("$pwd\npm-prefix") -Scope Global
Set-Variable -Name npm_config_tmp -value ("$pwd\npm-tmp") -Scope Global

#ensure npm always uses the local node
Set-Variable -Name NODEPATH -value (Get-Item -Path "..\Release" -Verbose).FullName
$env:Path = ("$NODEPATH;$env:Path")
Remove-Variable -Name NODEPATH -ErrorAction SilentlyContinue

#make sure the binaries from the non-dev-deps are available
node cli.js rebuild
#install npm devDependencies and run npm's tests
node cli.js install --ignore-scripts

#run the tests with logging if set
if ($logfile -eq $null)
{
  node cli.js run-script test-node -- --reporter=$progress
} else {
  node cli.js run-script test-node -- --reporter=$progress  2>&1 | Tee-Object -FilePath "..\$logfile"
}

#clean up everything in one single shot
cd ..
Cmd /C "rmdir /S /Q test-npm"
