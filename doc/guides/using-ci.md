# How to use the Node.js Continuous Integration server

This guide contains information about how to run and maintain the Node.js test
suites through the CI.

## Basics

To see all the available jobs, choose [the `All`
tab](https://ci.nodejs.org/view/All/). Make sure you have logged in with
Github. By default everyone has view access, build/edit access depends on which
[@nodejs/ teams](https://github.com/orgs/nodejs/teams) you are a
member of. The CI, along with other Node.js infrastructure, is maintained by
the [Build WG][]. For more info on who has what access, see [access.md][].

The key job is [`node-test-pull-request`][], which is used to run the test
suite against Node Pull Requests.

## CI Jobs

- [`node-test-pull-request`][] is the standard CI run we do to check Pull
  Requests. It triggers `node-test-commit`, whose subjobs run `make run-ci`
  (see the [Makefile][]) on Unix, or `vcbuild.bat release nosign x64` and
  `vcbuild.bat release nosign x64 noprojgen nobuild test-ci` (see
  [vcbuild.bat][]) on Windows.

- [`node-test-linter`][] only runs the linter targets, which is useful for
  changes that only affect comments or documentation.

- [`citgm-smoker`][] uses [`CitGM`][] to allow you to run `npm install && npm
  test` on a large selection of common modules. This is useful to check whether
  a change will cause breakage in the ecosystem. To test Node.JS ABI changes
  you can run [`citgm-abi-smoker`][]. For more info see the [CitGM
  repo][`CitGM`].

- [`node-stress-single-test`][] is designed to allow one to run a group of
  tests over and over on a specific platform to confirm that the test is
  reliable.

- [`node-test-commit-v8-linux`][] is designed to allow validation of changes to
  the copy of V8 in the Node.js tree by running the standard V8 tests. It
  should be run whenever the level of V8 within Node.js is updated or new
  patches are floated on V8.

- [`*-continuous-integration`][] runs the test suite for one of the other
  projects within the Node foundation (or the `nodejs` GitHub organisation).

[Build WG]: https://github.com/nodejs/build
[Makefile]: https://github.com/nodejs/node/blob/master/Makefile
[`*-continuous-integration`]: https://ci.nodejs.org/job/citgm-continuous-integration
[`CitGM`]: https://github.com/nodejs/citgm
[`citgm-abi-smoker`]: https://ci.nodejs.org/job/citgm-abi-smoker/
[`citgm-smoker`]: https://ci.nodejs.org/job/citgm-smoker/
[`node-stress-single-test`]: https://ci.nodejs.org/job/node-stress-single-test/
[`node-test-commit-v8-linux`]: https://ci.nodejs.org/job/node-test-commit-v8-linux/
[`node-test-linter`]: https://ci.nodejs.org/job/node-test-linter/
[`node-test-pull-request`]: https://ci.nodejs.org/job/node-test-pull-request/
[access.md]: https://github.com/nodejs/build/blob/master/doc/access.md
[the `All` tab]: https://ci.nodejs.org/view/ALL/
[vcbuild.bat]: https://github.com/nodejs/node/blob/master/vcbuild.bat
