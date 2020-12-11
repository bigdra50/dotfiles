" https://sy-base.com/myrobotics/vim/neovim-neoterm/
let g:neoterm_autoinsert = 1
let g:neoterm_autoscroll = 1
" # let g:neoterm_split_on_tnew = 1
let g:neoterm_default_mod = "belowright"

function! NTermInNewTab()
	let l:tmp = g:neoterm_default_mod
	let g:neoterm_default_mod = "tab"
	Tnew
	let g:neoterm_default_mod = l:tmp
endfunction

function! NTermCurrentDir()
	let l:cmd = "cd " .expand("%:p:h")
	call neoterm#exec({ 'cmd': [ cmd , '' ] })
	Topen
endfunction

function! NTermCMake()
	let l:cmd = "cd " .expand("%:p:h")
	let l:cmd = l:cmd . " && source ~/.config/nvim/scripts/AutoCMake.sh"
	call neoterm#exec({ 'cmd': [ cmd , '' ] })
	Topen
endfunction

function! NTermCatkinMake()
	let l:cmd = "roscd"
	let l:cmd = l:cmd . " && catkin_make"
	call neoterm#exec({ 'cmd': [ cmd , '' ] })
	Topen
endfunction

function! NTermPython( ... )
	if expand("%:e") != 'py'
		echo '[error] Invalid file extension.'
		return
	endif
	let l:cmd = "python " .expand("%:p")
	for arg in a:000
		let l:cmd = l:cmd . " " . arg
		"let l:cmd.cmd = [ l:cmd.cmd, arg ]
	endfor
	call neoterm#exec({ 'cmd': [ cmd ] })
	"T python l:cmd
	Topen
endfunction

function! NTermTexCompile()
	if expand("%:e") != 'tex'
		echo '[error] Invalid file extension.'
		return
	endif
	let l:cmd = "cd " .expand("%:p:h")
	let l:cmd = l:cmd . " && platex " . expand("%:p")
	let l:cmd = l:cmd . " && dvipdfmx " . expand("%:p:r") . ".dvi"
	call neoterm#exec({ 'cmd': [ cmd , '' ] })
	Topen
endfunction

function! GitPush( comment )
	let l:cmd = "cd " .expand("%:p:h")
	let l:cmd = l:cmd . " && source ~/.config/nvim/scripts/GitPush.sh " . a:comment
	call neoterm#exec({ 'cmd': [ cmd , '' ] })
	Topen
endfunction

function! UpdateConfig()
	let l:cmd = "cd ~/.config/nvim"
	let l:cmd = l:cmd . " && git pull"
	call neoterm#exec({ 'cmd': [ cmd , '' ] })
	Topen
	" execute "source ~/.config/nvim/init.vim"
endfunction

function! NTermMulti( v_num, h_num )
	let l:tmp = g:neoterm_default_mod
	let g:neoterm_default_mod = "tab"
	Tnew
	" # vertical split
	let g:neoterm_default_mod = "vertical"
	for i in range( a:h_num - 1 )
		Tnew
	endfor
	" # holizontal split
	let g:neoterm_default_mod = "aboveleft"
	for i in range( a:h_num )
		for i in range( a:v_num - 1 )
			Tnew
		endfor
		" # move to left window
		execute "winc l"
	endfor
	" # move to top-left window
	execute "winc t"
	let g:neoterm_default_mod = l:tmp
endfunction

function! NTermHolizontalSplit()
	let l:tmp = g:neoterm_default_mod
	let g:neoterm_default_mod = "aboveleft"
	Tnew
	let g:neoterm_default_mod = l:tmp
endfunction

function! NTermVerticalSplit()
	let l:tmp = g:neoterm_default_mod
	let g:neoterm_default_mod = "vertical"
	Tnew
	let g:neoterm_default_mod = l:tmp
endfunction

nnoremap <silent> <c-t><c-t> :Ttoggle<CR>
tnoremap <silent> <c-t><c-t> <C-\><C-n>:Ttoggle<CR>
nnoremap <c-t><c-h> :call NTermHolizontalSplit()<CR>
nnoremap <c-t><c-v> :call NTermVerticalSplit()<CR>

command! CMake                call NTermCMake()
command! CatkinMake           call NTermCatkinMake()
command! -nargs=* Python      call NTermPython(<f-args>)
"command! -nargs=* Python      :T python %:p <f-args>
command! TexCompile           call NTermTexCompile()
command! UpdateConfig         call UpdateConfig()
command! -nargs=1 GitPush     call GitPush(<f-args>)
command! -nargs=+ NTermMulti  call NTermMulti(<f-args>)
command! NTermMulti4          call NTermMulti(2,2)
command! NTermMulti6          call NTermMulti(3,2)
command! NTermMulti8          call NTermMulti(4,2)
