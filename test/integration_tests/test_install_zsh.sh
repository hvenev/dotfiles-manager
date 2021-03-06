#!/bin/bash


run_test() {
     echo "checking that a general install of a different package works as expected"
     exe -d "${BASE_DIR}/test/repo" -t "${TEMP_LOCAL}/" -B desktop1 -y install zsh

     # make sure it exited ok
     local last="$?"
     [[ "$last" != "0" ]] && return $last

     # check the linked files exist
     echo "next two assertations should fail - we don't want to install the vim package"
     assert_link "${TEMP_LOCAL}/.vimrc" "${BASE_DIR}/test/repo/vim/hosts/desktop1/files/.vimrc" && return 1
     assert_link "${TEMP_LOCAL}/.vim/filetype.vim" "${BASE_DIR}/test/repo/vim/files/.vim/filetype.vim" && return 1

     assert_link "${TEMP_LOCAL}/.zshrc" "${BASE_DIR}/test/repo/zsh/files/.zshrc" || return 1

     return 0
}
