" Plugins {{{
call plug#begin('~/.config/nvim/plugged')

" General stuff
Plug 'dracula/vim', { 'name': 'dracula' }
Plug 'skywind3000/asyncrun.vim'
Plug 'scrooloose/nerdcommenter'
Plug 'vim-airline/vim-airline'
Plug 'puremourning/vimspector'
Plug 'junegunn/vim-emoji'
Plug 'vim-scripts/vis'

" Neovim stuff
Plug 'neovim/nvim-lspconfig'
Plug 'tjdevries/nlua.nvim'
Plug 'nvim-lua/lsp_extensions.nvim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'

" Completion
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
Plug 'quangnguyen30192/cmp-nvim-ultisnips'

" Git
Plug 'tpope/vim-fugitive'

" GitHub
Plug 'pwntester/octo.nvim'
Plug 'kyazdani42/nvim-web-devicons'

" Snippets
Plug 'sirver/ultisnips'
Plug 'honza/vim-snippets'

" Functionality
Plug 'peterhoeg/vim-qml'
Plug 'lervag/vimtex'
Plug 'https://git.sr.ht/~ecc/vim-venus'
Plug 'eleanor-clifford/vim-qalc'
Plug 'eleanor-clifford/vim-dirdiff'
Plug 'dhruvasagar/vim-table-mode'
Plug 'thinca/vim-ref'
Plug 'ujihisa/ref-hoogle'
Plug 'dbeniamine/vim-mail'
Plug 'ellisonleao/glow.nvim'
Plug 'ThePrimeagen/harpoon'
Plug 'adelarsq/vim-matchit'

Plug 'mattn/webapi-vim'
"Plug 'kana/vim-metarw' " breaks paths with : in them
"Plug 'eleanor-clifford/vim-metarw-gdrive'

" Syntax
Plug 'chikamichi/mediawiki.vim'
Plug 'vim-pandoc/vim-pandoc-syntax'
Plug 'dag/vim-fish'
Plug 'ap/vim-css-color'
Plug 'octol/vim-cpp-enhanced-highlight'
Plug 'powerman/vim-plugin-AnsiEsc'
Plug 'tkztmk/vim-vala'

" External
Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }

call plug#end()
" }}}
" General {{{

" Enable local configs
set exrc
set secure " disallow :autocmd, shell, and write commands in local config

" Colors
syntax         enable
colorscheme    dracula
highlight      Normal ctermbg=NONE
highlight      Normal guibg=NONE
set            termguicolors

" Formatting
set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab
set textwidth=79
augroup WhitespaceFormatting
	autocmd!
	autocmd BufWritePre * call TrimWhitespace()
augroup END
let g:python_recommended_style = 0 " Fuck PEP who tf made this default

if system("echo $SHLVL") == 1
	call DontLetMeExit()
endif

fun! GetSyntax()
	let s = synID(line('.'), col('.'), 1)
	echo synIDattr(s, 'name') . ' -> ' . synIDattr(synIDtrans(s), 'name')
endfun
command! GetSyntax :call GetSyntax()

fun! DontLetMeExit()
	cabbrev q <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'close' : 'q')<CR>
	cabbrev wq <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'w\|close' : 'q')<CR>
	cabbrev qa <c-r>=('call DontExit()')<CR>
	cabbrev wqa <c-r>=('call DontExit()')<CR>
	cabbrev x <c-r>=('call DontExit()')<CR>
	cabbrev xa <c-r>=('call DontExit()')<CR>
endfun

fun! DontExit()
	echom "You opened me with exec. You probably don't want to do that."
endfun

" Visual
set incsearch nohlsearch
set foldmethod=marker
set noshowmode
set nowrap
set number
set guicursor=
set list
set listchars=tab:\|\ >
let g:no_man_maps = 1

fun! SetNumber()
	" Help files/terminal files don't need numbering
	if &filetype == "help" || &buftype == "terminal"
		set nonumber
		set norelativenumber
	else
		set number
		set relativenumber
	endif
endfun
autocmd BufEnter,FocusGained * call SetNumber()
autocmd BufLeave,FocusLost   * set norelativenumber
set scrolloff=8
set signcolumn=yes
set colorcolumn=80,120

fun! WrapMode()
	set tw=0
	set wrap
	set linebreak
	set columns=100
	autocmd VimResized * if (&columns > 100) | set columns=100 | endif
endfun
command! Wrap :call WrapMode()

" Misc
set undodir=~/.local/share/nvim/undo
set undofile
set hidden
set shortmess+=F
set nrformats+=alpha

" Avoid showing message extra message when using completion
set shortmess+=c

command! DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
		\ | wincmd p | diffthis
command! Cd cd %:p:h

function! Scratch()
    vsplit
    noswapfile hide enew
    setlocal buftype=nofile
    setlocal bufhidden=hide
endfunction

command! Scratch :call Scratch()

function NoFormatting()
	set tw=0
	augroup EmailFormatting
		autocmd!
	augroup END
	augroup WhitespaceFormatting
		autocmd!
	augroup END
endfun
command! NoFormatting :call NoFormatting()
" }}}
" Cheatsheet {{{
command! -nargs=+ Help :call Help(<q-args>)
fun! Help(args)
	let argsl = split(a:args, ' ')
	execute 'AsyncRun -mode=term curl cht.sh/'.argsl[0].'/'.join(argsl[1:], '+')
endfun
" }}}
" Modeline {{{
" https://vim.fandom.com/wiki/Modeline_magic
" Append modeline after last line in buffer.
" Use substitute() instead of printf() to handle '%%s' modeline in LaTeX
" files.
function! AppendModeline()
  let l:modeline = printf(" vim: set ts=%d sw=%d tw=%d %set :",
        \ &tabstop, &shiftwidth, &textwidth, &expandtab ? '' : 'no')
  let l:modeline = substitute(&commentstring, "%s", l:modeline, "")
  call append(line("$"), l:modeline)
endfunction
command AppendModeline call AppendModeline()
" }}}
" Make {{{
"
fun! ExecInTerm1(cmd)
	lua require("harpoon.term").gotoTerminal(1)
	exec "norm! A" . "" . a:cmd . "\n"
endfun

let g:asyncrun_open=5
autocmd! BufWritePost $MYVIMRC nested source %
fun! MakeAndRun()
	fun! s:r(cmd)
		"execute ':AsyncRun -mode=term '.a:cmd
		"norm! k
		execute ':AsyncRun '.a:cmd
	endfun

	:AsyncStop
	while g:asyncrun_status == 'running'
		sleep 1
	endwhile

	"lua require("harpoon.term").gotoTerminal(1)
	if filereadable('start.sh')
		call s:r("./start.sh")
	elseif filereadable('Makefile')
		call s:r("make")

		"if filereadable(expand('%:r'))
			"call system('./'.expand('%:r').'>stdout.txt 2>stderr.txt&')
		"endif
	elseif &filetype == 'python'
		call s:r('python3 '.expand('%'))
	elseif &filetype == 'lua'
		call s:r('lua '.expand('%'))
	elseif &filetype == 'sh'
		call s:r('./'.expand('%'))
	elseif &filetype == 'venus'
		call venus#Make()
	"elseif &filetype == 'tex'
		"s:r('pdflatex '.expand('%'))
		"while g:asyncrun_status == 'running'
			"sleep 1
		"endwhile
		"call venus#OpenZathura()
	else
		echom "I don't know how to make this"
	endif

endfun
fun! Make()
	if &filetype == 'markdown'
		call venus#PandocMake()
	else
		:make
	endif
endfun
" }}}
" Filetype {{{
autocmd FileType verilog set ts=8
" }}}
" Network stuff {{{
command! -nargs=1 Curl :r !curl -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36" -fsSL <q-args>
command! -nargs=1 Gurl :r !gmni gemini://<q-args> -j once
" }}}
" Project Specific {{{
" Config {{{
fun! ConfigGitHelper(arg)
	if substitute(getcwd(), '.*/', '', '') == '.config'
		if filereadable("gith.sh")
			execute "AsyncRun ./gith.sh --".a:arg
		else
			echo "git helper not readable"
		endif
	else
		echo "Not in config directory"
	endif
endfun
fun! ConfigInstaller(arg)
	if substitute(getcwd(), '.*/', '', '') == '.config'
		if filereadable("install.sh")
			execute "AsyncRun ./install.sh --".a:arg
		else
			echo "installer not readable"
		endif
	else
		echo "Not in config directory"
	endif
endfun
" }}}
" Website {{{
fun! BlogInit(title) abort
	let name = join(split(system("echo -n '".
					\ substitute(tolower(a:title), "'", "", "g")
					\."' | tr -d '[:punct:]'")
				\, ' '), '-')

	cd ~/projects/ellie.clifford.lol
	exe "silent !mkdir -p blog/".name
	let fname = 'blog/'.name.'/index.md'

	" exec "lua require('harpoon.term').sendCommand(1, 'firefox localhost:3000/blog/".name." & npm run dev\\n')"

	if ! filereadable(fname)
		" This is a bit awkward unfortunately
		execute 'edit ' . fname
		let header = [
					\ '---',
					\ 'title: "'.a:title.'"',
					\ 'excerpt: ""',
					\ 'createdAt: "'.system("date +'%Y-%m-%d' | tr -d '\n'").'"',
					\ '---',
					\ '',
				\]

		call append(0, header)
		call append('$', "<!-- vi: set sts=2 sw=2 et :-->")
		norm! Gkk
	else
		execute 'edit ' . fname
	endif
endfun
fun! BlogGeminiInit() abort
	"" sanity checks
	if match(expand("%:p"), "ellie\.clifford\.lol/blog/.*\.md") == -1
		echom "Start from markdown"
		return 1
	endif
	!$(dirname %)/../../scripts/build.sh --blog

	let g:blizpath = substitute(
				\ substitute(expand("%:p"), ".md$", ".bliz", ""),
				\ "blog/", "bliz/blog/", "")
	execute ":e " . g:blizpath
endfun
"fun! BlogPlainInit() abort
	"" sanity checks
	"if match(expand("%:p"), "ellie\.clifford\.lol/blog/.*\.bliz") == -1
		"echom "Start with the gemini version"
		"return 1
	"endif
	"if filereadable(substitute(expand("%:p"), ".bliz$", ".txt", ""))
		"echom "Will not overwrite file"
		"return 1
	"endif
	"exe ":!cp " . expand("%:p") . " " . substitute(expand("%:p"), ".bliz$", ".txt", "")
	"exe ":e " . substitute(expand("%:p"), ".bliz$", ".txt", "")
	":%s/=> \([^ ]*\) \(.*\)/\2: \1/
"endfun
"fun! BlogPublish() abort
	"" sanity checks
	"if match(expand("%:p"), "ellie\.clifford\.lol/blog/.*\.md") == -1
		"echom "Not a valid path"
		"return 1
	"endif
	"let blizpath = substitute(expand("%:p"), ".md$", ".bliz", "")
	"if ! filereadable(blizpath)
		"echom "No gemini version exists"
	"endif
	"execute "!scp " . blizpath . " pip:bliz/serve/blog/"
	"!npm run all
	""execute '!'.substitute(expand('%:p'), 'blog\/[^/]*\.md$',
				""\ 'scripts\/sendmail.sh ', '') . expand('%')
"endfun
"fun! BlogEmailTest() abort
	"" sanity checks
	"if match(expand("%:p"), "ellie\.clifford\.lol/blog/.*\.md") == -1
		"echom "Not a valid path"
		"return 1
	"endif
	"execute '!'.substitute(expand('%:p'), 'blog\/[^/]*\.md$',
				"\ 'scripts\/sendmail.sh ', '') . expand('%') . ' --test'
"endfun
"fun! WebInit()
	"cd ~/projects/https-ellie.clifford.lol
	"lua require('harpoon.term').sendCommand(1, 'firefox localhost:3000 & npm run dev\n')
	"edit pages/index.js
"endfun
"fun! WebPublishAndCommit()
	"AsyncRun npm run all
	"Git
"endfun
command! -nargs=+ Blog :call BlogInit(<q-args>)
command! BlogGemini :call BlogGeminiInit()
command! BlogPlain :call BlogPlainInit()
"command! BlogEmailTest :call BlogEmailTest()
"command! BlogPublish :call BlogPublish()
command! Web :call WebInit()
command! WebPublish :call WebPublishAndCommit()
" }}}
" }}}
" Plugin Config {{{
" Vimtex {{{
fun! VimtexCallback()
	echo "TODO: Make this open zathura"
endfun
fun! VimtexExit()
	:VimtexClean
	" Remove extra auxiliary files that I don't particularly care about
	call system("rm *.run.xml *.bbl *.synctex.gz")
endfun
augroup vimtex
	autocmd VimLeave *.tex call VimtexExit()
	autocmd User VimtexEventCompileSuccess call VimtexCallback()
	autocmd InsertLeave *.tex :w
augroup END
let g:vimtex_view_automatic = 0

" fucking vimtex
xnoremap  <nowait> ic           <nop>
xnoremap  <nowait> ie           <nop>
xnoremap  <nowait> im           <nop>
xnoremap  <nowait> iP           <nop>
xnoremap  <nowait> i$           <nop>
xnoremap  <nowait> id           <nop>
onoremap  <nowait> ic           <nop>
onoremap  <nowait> ie           <nop>
onoremap  <nowait> im           <nop>
onoremap  <nowait> iP           <nop>
onoremap  <nowait> i$           <nop>
onoremap  <nowait> id           <nop>

xnoremap  hc           <Plug>(vimtex-ic)
xnoremap  he           <Plug>(vimtex-ie)
xnoremap  hm           <Plug>(vimtex-im)
xnoremap  hP           <Plug>(vimtex-iP)
xnoremap  h$           <Plug>(vimtex-i$)
xnoremap  hd           <Plug>(vimtex-id)
onoremap  hc           <Plug>(vimtex-ic)
onoremap  he           <Plug>(vimtex-ie)
onoremap  hm           <Plug>(vimtex-im)
onoremap  hP           <Plug>(vimtex-iP)
onoremap  h$           <Plug>(vimtex-i$)
onoremap  hd           <Plug>(vimtex-id)
" }}}
" Venus {{{
let g:pandoc_defaults_file   = '~/.config/pandoc/pandoc.yaml'
let g:pandoc_headers      = '~/.config/pandoc/headers'
let g:pandoc_highlight_file  = '~/.config/pandoc/dracula.theme'
let g:pandoc_options         = '--citeproc'
let g:venus_pandoc_callback  = ['venus#OpenZathura']
let g:venus_ignorelist       = ['README.md']
let g:markdown_fenced_languages = ['tex', 'python', 'sh', 'haskell', 'c', 'html', 'json', 'javascript', 'yaml']
command! Open :call venus#OpenZathura()
" }}}
" Airline {{{
let g:airline_extensions = ['quickfix', 'netrw', 'term', 'csv', 'branch', 'fugitiveline', 'nvimlsp', 'po', 'wordcount', 'searchcount']
let g:airline#extensions#wordcount#filetypes = '\vasciidoc|help|mail|markdown|markdown.pandoc|org|rst|tex|text|venus'
" }}}
" Codi {{{
fun! s:qalc_preproc(line)
	return substitute(a:line, '\n', '', 'g')
endfun
let g:codi#interpreters = {
	\ 'qalc': {
		\ 'bin': 'qalc',
		\ 'prompt': '^> ',
		\ 'preprocess': function('s:qalc_preproc'),
		\ },
	\ }
" }}}
" Completion {{{
set completeopt=menu,menuone,noselect
" }}}
" Lspconfig {{{
"lua require('lspconfig').pyright.setup{capabilities = capabilities}

lua << EOF
require('lspconfig').pylsp.setup{
	capabilities = capabilities,
	settings = {
		pylsp = {
			plugins = {
				pycodestyle = {
					ignore = {
						'E101', -- indentation contains mixed spaces and tabs
						'E111', -- indentation is not a multiple of 4
						'E114', -- indentation is not a multiple of 4 (comment)
						'E116', -- unexpected indentation (comment)
						'E127', -- continuation line over-indented for visual indent
						'E131', -- continuation line unaligned for hanging intent
						'W191', -- indentation contains tabs
						'E201', -- whitespace after '('
						'E221', -- multiple spaces before operator
						'E241', -- multiple spaces after ':'
						'E251', -- unexpected spaces around keyword / parameter equals
						'E272', -- multiple spaces before keyword
						'E303', -- too many blank lines
						'E741', -- ambiguous variable name
						'W503', -- line break before binary operator
						'W504', -- line break after binary operator
					},
					maxLineLength = 100
				}
			}
		}
	}
}
EOF

lua require('lspconfig').bashls.setup{capabilities = capabilities}
lua require('lspconfig').gopls.setup{capabilities = capabilities}
lua require('lspconfig').biome.setup{capabilities = capabilities}
lua require('lspconfig').vimls.setup{capabilities = capabilities}
lua require('lspconfig').clangd.setup{capabilities = capabilities}
lua require('lspconfig').csharp_ls.setup{capabilities = capabilities}
lua require('lspconfig').hls.setup{capabilities = capabilities}
lua require('lspconfig').lua_ls.setup{capabilities = capabilities}
lua require('lspconfig').phpactor.setup{capabilities = capabilities}
lua require('lspconfig').lua_ls.setup{capabilities = capabilities}
lua require('lspconfig').qmlls.setup{capabilities = capabilities}
lua require('lspconfig').rust_analyzer.setup{capabilities = capabilities}
" }}}
" Telescope {{{
lua require('telescope').load_extension('octo')
" }}}
" Ref {{{
let g:ref_pydoc_cmd =
	\ executable('pydoc') ? 'pydoc' :
	\ executable('python') ? 'python -m pydoc' :
	\ executable('pydoc3') ? 'pydoc3' :
	\ executable('python3') ? 'python3 -m pydoc' :
	\ ""

command! -nargs=+ Rpy :Ref pydoc <args>
command! -nargs=+ Rnp :Ref pydoc numpy.<args>
command! -nargs=+ Rplt :Ref pydoc matplotlib.pyplot.<args>
command! -nargs=+ Rhs :Ref hoogle <args>
" }}}
" Mail {{{
let g:VimMailContactsProvider=['khard']
let g:VimMailSpellLangs=['en']
let g:VimMailDoNotMap=1

fun! s:mailCompleteMaybe()

	" Check we are in a valid line
	if match(getline("."), 'To:\|Cc:\|Bcc:') == 0
		let cursorpos = getpos(".")
		call cursor(0, cursorpos[2] - 1) " move cursorpos back 1 (onto word)
		if strlen(expand('<cword>')) > 1
			return "\<C-x>\<C-o>"
		endif
	endif
endfun

augroup MailCompletion
	autocmd!
	autocmd FileType mail inoremap <expr> <Tab> <SID>mailCompleteMaybe()
augroup END
" }}}
" Glow {{{
let g:glow_border="rounded"
let g:glow_width=80
" }}}
" Firenvim {{{
fun! FirenvimSetup()
	let g:firenvim_config.localSettings["https?://[^/]+\\.slack\\.com/"] = { 'takeover': 'never', 'priority': 1 }
	set autowriteall wrap linebreak
	set textwidth=0
	set colorcolumn=
	nnoremap
endfun

command! Fire :call FirenvimSetup()

if exists("g:started_by_firenvim") && g:started_by_firenvim
	call FirenvimSetup()
endif

" }}}
" Octo {{{
lua require"octo".setup({})
" }}}
" Mystra {{{
command! -nargs=+ MC  :call MystraCite(<q-args>)
command! -nargs=+ MCO :call MystraCiteOnly(<q-args>)
command! -nargs=+ MB  :call MystraBibtex(<q-args>)

fun! MystraBibtex(args)
	execute ".!mystra show --local --bibtex ".a:args
endfun

fun! MystraCiteOnly(args)
	execute "silent norm! a=substitute(system('mystra show --local --bibtex-id ".a:args."'), '\\n$', '', '')\n"
endfun
fun! MystraCite(args)
	call MystraCiteOnly(a:args)
	edit bibliography.bib
	call append(line('$'), "")
	$
	call MystraBibtex(a:args)
	edit #
endfun
" }}}
" {{{ nerdcommenter
let g:NERDDefaultAlign = 'left'
let g:NERDCustomDelimiters = {
	\	'openscad': { 'left': '//' },
	\ }
" }}}
" }}}
" Keyboard Mappings {{{
" General {{{
let mapleader = " "
let maplocalleader = " "
nnoremap <silent> <leader>v<leader> :edit ~/.config/nvim/init.vim<CR>
" Why is this not default, I don't get it
noremap Y y$
noremap <silent> <leader>j :next<CR>
noremap <silent> <leader>J :prev<CR>

noremap n h
noremap e gj
noremap <nowait> i gk
noremap o l
noremap k o
noremap l e
noremap h i
noremap j n

noremap N H
noremap E J
noremap I K
noremap O L
noremap K O
noremap L E
noremap H I
noremap J N
noremap <leader>k za
" }}}
" Clipboard {{{
nnoremap <leader>pa ggdG"+p
nnoremap <leader>pi ggdG"+p:Indent<CR>
nnoremap <leader>ya gg"+yG
" }}}
" Format {{{
nnoremap <leader>o :call   AlignWhitespaceFile('  ',' ','\t')<CR>
" Let the strategy be more aggressive for visual selection
vnoremap <leader>o :call AlignWhitespaceVisual('  ',' ','  \|\t')<CR>
noremap <leader>i :Indent<CR>
"noremap <leader>u :%s/’/'/ge|%s/“/"/ge|%s/”/"/ge|%s/…/.../ge<CR>
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
noremap <Leader>mm :wa <bar> call Make() <CR>
noremap <Leader>mr :wa <bar> call MakeAndRun() <CR>
" }}}
" Terminal {{{
tnoremap <c-w> <C-\><C-n>
"tnoremap <Esc> <C-\><C-n>
"tnoremap <Esc><Esc> <C-\><C-n>
"set timeout timeoutlen=1000  " Default
"set ttimeout ttimeoutlen=100  " Set by defaults.vim
"noremap <Leader>tt :call termopen('zsh')<CR>
"noremap <Leader>ts :term<CR>
"noremap <Leader>tv :vertical term<CR>
" }}}
" Location/Quickfix List {{{
nnoremap <leader>l :call ToggleList(0)<CR>
nnoremap <leader>q :call ToggleList(1)<CR>

" Thanks prime
let g:qfix_open = 0
let g:loclist_open = 0
fun! ToggleList(global)
    if a:global
        if g:qfix_open == 1
            let g:qfix_open = 0
            cclose
        else
            let g:qfix_open = 1
            copen
        end
    else
        if g:loclist_open == 1
            let g:loclist_open = 0
            lclose
        else
            let g:loclist_open = 1
            lopen
        end
    endif
endfun

" }}}
" LSP {{{
" The original g commands are whack, seriously
nnoremap gd :lua  vim.lsp.buf.definition()<CR>
nnoremap gf :lua  vim.lsp.buf.code_action()<CR>
nnoremap gi :lua  vim.lsp.buf.implementation()<CR>
nnoremap gj :lua  vim.lsp.buf.references()<CR>
nnoremap gl :call LSP_open_loclist()<CR>
nnoremap gn :lua  vim.diagnostic.goto_next()<CR>
nnoremap gr :lua  vim.lsp.buf.rename()<CR>
nnoremap gs :lua  vim.lsp.buf.signature_help()<CR>
nnoremap gt :lua  vim.lsp.buf.type_definition()<CR>
nnoremap ge :lua  vim.diagnostic.open_float(nil, {focus=false})<CR>

fun! LSP_open_loclist()
	lua vim.lsp.diagnostic.set_loclist()
	let g:loclist_open = 1
endfun

" }}}
" Plugin Keymaps {{{
" Venus {{{
vnoremap <silent> <leader>vo :!pandoc -f markdown -t latex<CR>
" }}}
" Emoji {{{
set completefunc=emoji#complete
" Replace emoji with utf-8
nnoremap <leader>e :%s/:\([^ :]\+\):/\=emoji#for(submatch(1), submatch(0))/g<CR>
" Start emoji completion automatically
"inoremap : :<C-X><C-U>
" }}}
" Ultisnips {{{
let g:UltiSnipsExpandTrigger="<c-e>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"
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
" Telescope {{{
nnoremap <leader>f  <cmd>Telescope git_files<CR>
nnoremap <leader>F  <cmd>Telescope find_files<CR>
nnoremap <leader>b  <cmd>Telescope buffers<CR>
nnoremap <leader>ps <cmd>Telescope grep_string<CR>
" }}}
" Fugitive {{{
augroup Fugitive
	autocmd!
	autocmd FileType fugitive
				\ nnoremap <buffer> tr :call ConfigGitHelper("reset")<CR>
	autocmd FileType fugitive
				\ nnoremap <buffer> tp :call ConfigGitHelper("push")<CR>
	autocmd FileType fugitive
				\ nnoremap <buffer> tg :call ConfigGitHelper("pull")<CR>
	autocmd FileType fugitive
				\ nnoremap <buffer> tu :call ConfigInstaller("update")<CR>
augroup END
noremap <leader>g :Git<CR>
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
" Mail {{{
nnoremap <LocalLeader>a :call vimmail#spelllang#SwitchSpellLangs()<CR>
" }}}
" Harpoon {{{
nnoremap <silent> <leader>m :lua require("harpoon.mark").add_file()<CR>
nnoremap <silent> <leader>! :lua require("harpoon.term").gotoTerminal(1)<CR>
nnoremap <silent> <leader>£ :lua require("harpoon.term").gotoTerminal(2)<CR>
nnoremap <silent> <leader>% :lua require("harpoon.term").gotoTerminal(3)<CR>
nnoremap <silent> <leader>& :lua require("harpoon.term").gotoTerminal(4)<CR>
" }}}
" }}}
" }}}
