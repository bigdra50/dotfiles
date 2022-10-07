let g:ale_linters = {'elm': ['elm_ls']}
let g:ale_fixers = {'elm':['elm-format']}
let g:ale_elm_ls_use_global = 1
let g:ale_elm_ls_executable = "$HOME/.config/yarn/global/node_modules/.bin/elm-language-server"
let g:ale_elm_ls_elm_path = "$HOME/.config/yarn/global/node_modules/.bin/elm"
let g:ale_elm_ls_elm_format_path = "$HOME/.config/yarn/global/node_modules/.bin/elm-format"
let g:ale_elm_ls_elm_test_path = "$HOME/.config/yarn/global/node_modules/elm-test"
let g:ale_elm_format_options = "--yes --elm-version=0.19.1"
