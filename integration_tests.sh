#!/usr/bin/env bash


# http://www.ostricher.com/2014/10/the-right-way-to-get-the-directory-of-a-bash-script/
get_script_dir () {
     SOURCE="${BASH_SOURCE[0]}"
     while [ -h "$SOURCE" ]; do
          DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
          SOURCE="$( readlink "$SOURCE" )"
          [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
     done
     $( cd -P "$( dirname "$SOURCE" )" )
     pwd
}

export BASE_DIR="$(get_script_dir)"
cd "$BASE_DIR" || exit 1
echo "BASE_DIR: $BASE_DIR"

[[ -n "$KCOV_BIN" ]] || KCOV_BIN=kcov
echo "Using kcov executable: $KCOV_BIN"

# temporary local directory
export TEMP_LOCAL="${BASE_DIR}/local"

if [ ! -f "${BASE_DIR}/target/debug/dotfiles-manager" ]; then
     echo "Could not found executable! Please run cargo build first!"
     exit 1
fi

# use this to run the executable
# generates code coverage data with every run
# slow but comprehensive
exe() {
     local previous="$(pwd)"
     cd "$BASE_DIR"
     local coverage_dir="target/cov/$(uuidgen)"
     mkdir -p "$coverage_dir"
     $KCOV_BIN --exclude-pattern=/.cargo,/usr/lib --verify "$coverage_dir" "${BASE_DIR}/target/debug/dotfiles-manager" "$@"
     cd "$previous"
}

# assert helper functions
# inspiration from rcm test helpers - https://github.com/thoughtbot/rcm/blob/master/test/helper.sh
assert() {
  local msg="$1"; shift
  test "$@" || { echo "Failed assertion: $msg"; return 1; }
  return 0
}

assert_fail() {
  local msg="$1"; shift
  test "$@" && { echo "Failed assertion: $msg"; return 1; }
  return 0
}


assert_link() {
  local from="$1" to="$2"
  local target="$(readlink "$from")"

  assert "$from should be a symlink" -h "$from" || return 1
  assert "$from should resolve to $to, resolved to $target" "$target" = "$to" || return 1
  return 0
}

echo ":: Setup complete, begin tests."

count=0
TESTS_DIR="${BASE_DIR}/test/integration_tests"
for filename in ${TESTS_DIR}/*; do

     rm -rf "$TEMP_LOCAL"
     mkdir -p "$TEMP_LOCAL"

     # each test file should be a bash script with no global variables,
     # defining a `run_test` function
     # variables to use:
     # - exe          | the binary to run for the dotfiles manager
     # - TEMP_LOCAL   | the local directory to do stuff in - make files, etc - reset after each test
     # - BASE_DIR     | root directory of project
     echo ""
     echo ":: Running test $(basename $filename)"
     source "${filename}"
     run_test

     # check the return value - if non-zero, we want to exit with that value
     # but still run the rest of the tests
     LAST=$?
     if [ "$LAST" != "0" ]; then
          echo ""
          echo ":: Test failed with return code ${LAST}"
          ((count++))
     fi
done

CODE=0
if [ "$count" != "0" ]; then
     [ "$count" != "1" ] && plural="s"
     echo ""
     echo ":: ${count} test${plural} failed!"
     CODE=1
else
     echo ""
     echo ":: All tests successful!"
fi

# cleanup
rm -rf "$TEMP_LOCAL"
exit "$CODE"
