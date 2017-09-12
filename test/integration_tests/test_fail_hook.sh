#!/bin/bash

run_test() {
     echo "checking hook failed"
     out=$(exe -d "${BASE_DIR}/test/repo" -t "${TEMP_LOCAL}/" -B hook_fail_host install vim 2>&1)

     echo $out | grep -e 'Hook failed: ' || return 1

     return 0
}
