set signcolumn=yes
set updatetime=250

"" git����
" g]�őO�̕ύX�ӏ��ֈړ�����
nnoremap g[ :GitGutterPrevHunk<CR>
" g[�Ŏ��̕ύX�ӏ��ֈړ�����
nnoremap g] :GitGutterNextHunk<CR>
nnoremap gu :GitGutterUndoHunk<CR>
" gh��diff���n�C���C�g����
nnoremap gh :GitGutterLineHighlightsToggle<CR>
" gp�ŃJ�[�\���s��diff��\������
nnoremap gp :GitGutterPreviewHunk<CR>

" �L���̐F��ύX����
highlight GitGutterAdd ctermfg=green
highlight GitGutterChange ctermfg=blue
highlight GitGutterDelete ctermfg=red
