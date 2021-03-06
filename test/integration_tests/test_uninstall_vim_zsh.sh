#!/bin/bash


run_test() {
     echo "checking that uninstalling a previously installed package works"
     exe_sans -d "${BASE_DIR}/test/repo" -t "${TEMP_LOCAL}/" -B desktop1 -y install vim zsh

     exe -d "${BASE_DIR}/test/repo" -t "${TEMP_LOCAL}/" -B desktop1 -y remove vim zsh

     # make sure it exited ok
     local last="$?"
     [[ "$last" != "0" ]] && return $last

     # check the linked files don't exist any more
     assert "vimrc should be removed" ! -e "${TEMP_LOCAL}/.vimrc" || return 1
     assert "zshrc should be removed" ! -e "${TEMP_LOCAL}/.zshrc" || return 1
     assert "filetype.vim should be removed" ! -e "${TEMP_LOCAL}/.vim/filetype.vim" || return 1
     assert ".vim/ directory should not be removed" -d "${TEMP_LOCAL}/.vim/" || return 1

     return 0
}
