set nocompatible              " be iMproved, required
set encoding=utf-8
filetype off                  " required
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

Plugin 'tpope/vim-fugitive'
Plugin 'scrooloose/nerdtree'
Plugin 'valloric/youcompleteme'
Plugin 'sirver/ultisnips'
Plugin 'honza/vim-snippets'
Plugin 'scrooloose/nerdcommenter'
Plugin 'lervag/vimtex'
Plugin 'dracula/vim', { 'name': 'dracula' }
Plugin 'eleanor-clifford/jupyter-vim'
Plugin 'eleanor-clifford/jupytext.vim'
Plugin 'vim-airline/vim-airline'
Plugin 'lambdalisue/battery.vim'
Plugin 'puremourning/vimspector'
Plugin 'junegunn/fzf'
Plugin 'junegunn/fzf.vim'
Plugin 'dag/vim-fish'
"Plugin 'pandysong/ghost-text.vim', { 'do': ':GhostInstall' }
Plugin 'ap/vim-css-color'
Plugin 'skywind3000/asyncrun.vim'
Plugin 'powerman/vim-plugin-AnsiEsc'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
" General {{{
syntax enable
set termguicolors
colorscheme dracula
hi Normal ctermbg=NONE
hi Normal guibg=NONE
set foldmethod=marker
set mouse=a
let mapleader = " "
let maplocalleader = " "
command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
		\ | wincmd p | diffthis
set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab
set number
augroup numbertoggle
	autocmd BufEnter,FocusGained * set relativenumber
	autocmd BufLeave,FocusLost   * set norelativenumber
augroup END
set noshowmode
set shortmess+=F
set is hls
set nohlsearch

" }}}
" Indent {{{
function IndentFile()
	let winview = winsaveview()
	silent :w
	call system('indent -nbad -bap -nbc -bbo -hnl -br -brs -c33 -cd33 -ncdb -ce -ci4 -cli0 -d0 -di1 -nfc1 -i4 -ip0 -l80 -lp -npcs -nprs -npsl -sai -saf -saw -ncs -nsc -sob -nfca -cp33 -nss -ts4 -il1 '.expand('%:t'))
	:e
	" Make templates work properly
	if &filetype == 'cpp'
		" Fuck this there are too many edge cases
		silent! :%s/\v ?\< ?([^\<\>]*[^\<\> ]) ?\> ?/<\1> /g
		silent! :%s/\v(\<[^\<\>]*[^\<\> ]*\>) ([\(\)\[\]\{\};])/\1\2/g
	endif
	silent :w
	call winrestview(winview)
endfunction
command Indent call IndentFile()
" }}}
" Clipboard {{{
map <leader>pa ggdG"+p
map <leader>pi ggdG"+p:Indent<CR>
map <leader>ya gg"+yG
" }}}
" NERDTree {{{
"autocmd StdinReadPre * let s:std_in=1
"autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
" }}}
" TermPDF {{{
let g:current_page = 0
let g:total_pages = 0
let g:termpdf_lastcalled = 0
function TermPDF(file) abort
	" Implement some basic throttling
	let time = str2float(reltimestr(reltime())) * 1000.0
	if time - g:termpdf_lastcalled > 1000
		call system('kitty @ kitten termpdf.py ' . a:file)
		" Remember the last opened page but don't fail when the number of
		" pages has changed
		let g:total_pages = str2nr(system("pdfinfo " . a:file . " | grep Pages | sed 's/[^0-9]*//'"))
		if g:current_page == 0
			let g:current_page = 1
		elseif g:current_page <= g:total_pages
			call system('sleep 0.2 && tpdfc goto ' . g:current_page)
		else
			let g:current_page = 1
		endif
		let g:termpdf_lastcalled = time
	endif
endfunction

function TermPDFNext() abort
	if g:current_page < g:total_pages
		call system('tpdfc forward 1')
		let g:current_page += 1
	endif
endfunction

function TermPDFPrev() abort
	if g:current_page > 1
		call system('tpdfc back 1')
		let g:current_page -= 1
	endif
endfunction

function TermPDFEnd() abort
	call system('tpdfc last')
endfunction

function TermPDFClose() abort
	call system('kitty @ close-window --match title:termpdf')
endfunction
function TermPDFAutoUpdateIfChanged(timer)
	if filereadable(getcwd().'/.jupyter-pdf-changed')
		call TermPDF(getcwd().'/jupyter_plots.pdf')
		call system('rm '.getcwd().'/.jupyter-pdf-changed')
		if g:current_page < g:total_pages
			call TermPDFEnd()
		endif
	endif
endfunction
let g:timerid = -1
function TermPDFAutoUpdateStart()
	if g:timerid == -1
		let g:timerid = timer_start(1000, 'TermPDFAutoUpdateIfChanged', {'repeat': -1})
	endif
endfunction
function TermPDFAutoUpdateStop()
	if g:timerid != -1
		timer_stop(g:timerid)
	endif
endfunction
" }}}
" Vimtex {{{
let g:tex_flavor = 'latex'
let g:vimtex_view_automatic = 0
function VimtexCallback()
	call TermPDF(escape(b:vimtex.out()," "))
endfunction
function VimtexExit()
	call TermPDFClose()
	:VimtexClean
	" Remove extra auxiliary files that I don't particularly care about
	call system("rm *.run.xml *.bbl *.synctex.gz")
endfunction
augroup vimtex
	autocmd VimLeave *.tex call VimtexExit()
	autocmd User VimtexEventCompileSuccess call VimtexCallback()
	autocmd InsertLeave *.tex :w
	" <C-PgUp> and <C-PgDn>
	autocmd FileType tex,markdown nnoremap [5;5~ :call TermPDFPrev()<CR>
	autocmd FileType tex,markdown nnoremap [6;5~ :call TermPDFNext()<CR>
	autocmd FileType markdown call TermPDFAutoUpdateStart()
augroup END
" }}}
" Jupyter {{{
function JupyterStart()
	call system('kitty @ kitten jupyter.py '.getcwd())
	:JupyterConnect
endfunction
function JupyterExit()
	call TermPDFClose()
	call system('pkill -9 jupyter && kitty @ close-window --match title:vimjupyter')
endfunction
function JupyterCompile()
	silent execute "w"
	call system('pandoc '.expand('%:t:r').'.md -o jupyter_notebook.pdf -V geometry:margin=1in')
	call TermPDF(getcwd().'/jupyter_notebook.pdf')
endfunction
"function JupyterRunAllIntoMarkdown()
	""call system('pkill -9 jupyter')
	""call JupyterStart()
	"normal gg
	"let flags = "c"
	"while search("```python", flags) != 0
		"call jupyter#SendCell()
		"call search("```")
		"call system("sleep 0.5")
		"call append(line('.'),matchstr(readfile('.jupyter-out'),"OUT["))
		"let flags = ""
	"endwhile
"endfunction
"let g:jupyter_monitor_console = 1
let g:jupyter_mapkeys = 0
let b:jupyter_kernel_type = 'python'
let g:jupyter_cell_separators = ['```py','```']
let g:markdown_fenced_languages = ['python']
augroup jupyter
	autocmd VimLeave *.ipynb call JupyterExit()
	autocmd BufEnter *.ipynb call jupyter#load#MakeStandardCommands()
	autocmd BufEnter *.ipynb set filetype=markdown.python
augroup END
" }}}
" YouCompleteMe {{{
au VimEnter * let g:ycm_semantic_triggers.tex=g:vimtex#re#youcompleteme
let g:ycm_filetype_blacklist={'cpp': 1, 'notes': 1, 'unite': 1, 'tagbar': 1, 'pandoc': 1, 'qf': 1, 'vimwiki': 1, 'text': 1, 'infolog': 1, 'mail': 1}
" }}}
" Make {{{
let g:asyncrun_open=10
autocmd! BufWritePost $MYVIMRC nested source %
function MakeAndRun()
	if filereadable('start.sh')
		"call system('./start.sh >stdout.txt 2>stderr.txt&')
		:AsyncStop
		while g:asyncrun_status == 'running'
			sleep 1
		endwhile
		:AsyncRun ./start.sh
	elseif &filetype == 'python'
		execute ':AsyncRun python3 '.expand('%:t')
		"call system('python3 '.expand('%:t').'>stdout.txt 2>stderr.txt&')
	elseif &filetype == 'sh'
		execute ':AsyncRun ./'.expand('%:t')
		"call system('python3 '.expand('%:t').'>stdout.txt 2>stderr.txt&')
	elseif &filetype == 'markdown'
		"call system('pandoc '.expand('%:t:r').'.md -o '.expand('%:t:r').'.pdf -V geometry:margin=1in --pdf-engine=xelatex')
		execute ':AsyncRun pandoc '.expand('%:t:r').'.md -o '.expand('%:t:r').'.pdf -V geometry:margin=1in --pdf-engine=xelatex')
		while g:asyncrun_status == 'running'
			sleep 1
		endwhile
		call TermPDF(getcwd().'/'.expand('%:t:r').'.pdf')
	else
		" Assumes makefile exists and binary filename is current filename
		" minus extension
		:AsyncRun make
		while g:asyncrun_status == 'running'
			sleep 1
		endwhile
		call system('./'.expand('%:r').'>stdout.txt 2>stderr.txt&')
	endif
endfunction
" }}}
" Airline {{{
let g:airline#extensions#whitespace#mixed_indent_algo = 2
" }}}
" Keyboard Mappings {{{
" General {{{
noremap n h
noremap N H
noremap e j
noremap E J
noremap i k
noremap I K
noremap o l
noremap O L
noremap k o
noremap K O
noremap l e
noremap L E
noremap h i
noremap H I
noremap j n
noremap J N
noremap <Leader>k za
map <leader>i :Indent<CR>
"map <esc> <esc>:nohlsearch<CR>
" }}}
" Splits {{{
noremap <leader>s  <C-W>
noremap <leader>ss <C-W>s<C-W>j
noremap <leader>sv <C-W>v<C-W>l
noremap <leader>sn <C-W>h
noremap <leader>sN <C-W>H
noremap <leader>se <C-W>j
noremap <leader>sE <C-W>J
noremap <leader>si <C-W>k
noremap <leader>sI <C-W>K
noremap <leader>so <C-W>l
noremap <leader>sO <C-W>L
noremap <leader>sk <C-W>o
noremap <leader>sK <C-W>O
noremap <leader>sl <C-W>e
noremap <leader>sL <C-W>E
noremap <leader>sh <C-W>i
noremap <leader>sH <C-W>I
noremap <leader>sj <C-W>n
noremap <leader>sJ <C-W>N
" }}}
" Make {{{
noremap <Leader>mm :wa <bar> make <CR>
noremap <Leader>mr :wa <bar> call MakeAndRun() <CR>
" }}}
" Terminal {{{
tnoremap <Esc> <C-\><C-n>
tnoremap <Esc><Esc> <C-\><C-n>
set timeout timeoutlen=1000  " Default
set ttimeout ttimeoutlen=100  " Set by defaults.vim
noremap <Leader>tt :call term_start($SHELL, {'curwin' : 1})<CR>
noremap <Leader>ts :term<CR>
noremap <Leader>tv :vertical term<CR>
" }}}
" {{{ NERDTree
noremap <Leader>n  :NERDTreeToggle<CR>
let g:NERDTreeMapActivateNode='k'
let g:NERDTreeMapOpenSplit='s'
let g:NERDTreeMapOpenVSplit='v'
let g:NERDTreeMapToggleHidden='H'
let g:NERDTreeMapOpenRecursively='0'
let g:NERDTreeMapOpenExpl='l'
" }}}
" Ultisnips {{{
let g:UltiSnipsExpandTrigger="<c-e>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"
" }}}
" Vimtex {{{
nnoremap <Leader>lx :call TermPDFClose()<CR>
" }}}
" Jupyter {{{
" Run current file
nnoremap <leader>jr :JupyterRunFile<CR>
nnoremap <leader>ji :PythonImportThisFile<CR>

" Change to directory of current file
nnoremap <leader>jd :JupyterCd %:p:h<CR>

" Send a selection of lines
nnoremap <leader>jx :call jupyter#SendCell() <bar> /```py<CR>
nnoremap <leader>je :JupyterSendRange<CR>
nmap     <leader>je <Plug>JupyterRunTextObj
vmap     <leader>je <Plug>JupyterRunVisual

nnoremap <leader>ju :JupyterUpdateShell<CR>

" Debugging maps
nnoremap <leader>jb :PythonSetBreak<CR>

" Kitty side panel
nnoremap <leader>jj :call JupyterStart()<CR>
nnoremap <leader>jp :call JupyterCompile()<CR>
nnoremap <leader>jq :call JupyterExit()<CR>

" goto cell
nnoremap <leader>jc /```py<CR>
nnoremap <leader>jC ?```py<CR>
" run all
nnoremap <leader>ja :%g/```py/JupyterSendCell<CR>G
" }}}
" YouCompleteMe {{{
" Avoid confilict with vimspector
let ycm_key_detailed_diagnostics = '<leader>yd'
" }}}
" Vimspector {{{
nnoremap <leader>dd :call vimspector#Launch()<CR>
nmap <leader>d<space>  <Plug>VimspectorContinue
nmap <leader>ds <Plug>VimspectorStop
nmap <leader>dr <Plug>VimspectorRestart
nmap <leader>dp <Plug>VimspectorPause
nmap <leader>dbb <Plug>VimspectorToggleBreakpoint
nmap <leader>dbc <Plug>VimspectorToggleConditionalBreakpoint
nmap <leader>dbf <Plug>VimspectorAddFunctionBreakpoint
nmap <leader>de <Plug>VimspectorStepOver
nmap <leader>do <Plug>VimspectorStepInto
nmap <leader>di <Plug>VimspectorStepOut
nmap <leader>dc <Plug>VimspectorRunToCursor
nmap <leader>dq :VimspectorReset<CR>
" }}}
" fzf {{{
nnoremap <leader>f :GFiles<CR>
nnoremap <leader>F :Files<CR>
" }}}
" Fugitive {{{
let g:nremap = {
\	'o': 'k',
\	'O': 'K',
\	'e': 'l',
\	'E': 'L',
\	'i': 'h',
\	'I': 'H',
\	'n': 'j',
\	'N': 'J',
\}
let g:oremap = {
\	'o': 'k',
\	'O': 'K',
\	'e': 'l',
\	'E': 'L',
\	'i': 'h',
\	'I': 'H',
\	'n': 'j',
\	'N': 'J',
\}
let g:xremap = {
\	'o': 'k',
\	'O': 'K',
\	'e': 'l',
\	'E': 'L',
\	'i': 'h',
\	'I': 'H',
\	'n': 'j',
\	'N': 'J',
\}
" }}}
" }}}
