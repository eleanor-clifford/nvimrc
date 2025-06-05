com! Act80char nnoremap i gk|nnoremap e gj|set columns=86|set wrap|set linebreak
" Visual Selection {{{
" public domain code by stack overflow user FocusedWolf
" https://stackoverflow.com/a/6271254
fun! s:get_visual_selection()
	" Why is this not a built-in Vim script function?!
	let [line_start, column_start] = getpos("'<")[1:2]
	let [line_end, column_end] = getpos("'>")[1:2]
	let lines = getline(line_start, line_end)
	if len(lines) == 0
		return ''
	endif
	let lines[-1] = lines[-1][:column_end - (&selection == 'inclusive' ? 1 : 2)]
	let lines[0] = lines[0][column_start - 1:]
	return join(lines, "\n")
endfun
" }}}
" Alignment {{{
fun! AlignWhitespaceFile(delim, aligner, splitregex)
	let file = getline(0, line("$"))
	let aligned = s:AlignWhitespaceLines(
				\ file, a:delim, a:aligner, a:splitregex)
	" This seems easier to do than a substitute or delete/put
	for i in range(len(aligned))
		call setline(i+1, aligned[i])
	endfor
endfun

fun! AlignWhitespaceVisual(delim, aligner, splitregex)
	let [line_start, column_start] = getpos("'<")[1:2]
	let [line_end, column_end] = getpos("'>")[1:2]
	let selection = split(s:get_visual_selection(), "\n")
	let aligned = s:AlignWhitespaceLines(selection, a:delim,
	                                   \ a:aligner, a:splitregex)
	" This seems easier to do than a substitute or delete/put
	for i in range(len(aligned))
		call setline(line_start + i, aligned[i])
	endfor
endfun

fun! s:AlignWhitespaceLines(lines, delim, aligner, splitregex)
	" Only align if there if there are tabs after non-whitespace
	" Don't expect this to also remove trailing whitespace
	" Fix | in regex
	let splitregex = substitute(a:splitregex, '|', '\\|', 'g')
	let aligned = a:lines
	let last = []
	let current_depth = 0
	let matches = [''] " dummy
	let testlist = range(len(a:lines))
	call map(testlist, '-1')
	while matches != testlist
		let last = aligned[:]
		" Find longest line and get matches for later
		let longest = -1
		let matches = []
		for line in aligned
			let m = match(line, '\S\zs\s*\%('.splitregex.'\)\s*\S',
						\ current_depth)
			" we'll need these later
			let matches = matches + [m]
			if m > longest
				let longest = m
			endif
		endfor
		" Set the depth for the next pass
		let current_depth = longest + 1
		" Apply alignment
		for i in range(len(aligned))
			let line = aligned[i]
			let matchstart = matches[i]
			let matchend = match(line,
					\ '\S\s*\%('.splitregex.'\)\s*\zs\S', matchstart-1)
			" Do nothing if there are no matches on the line
			if matchstart != -1 && matchend >= matchstart
				let newline = line[:matchstart-1]
						\ . repeat(a:aligner,longest - matchstart)
						\ . a:delim . line[matchend:]
				let aligned[i] = newline
			endif
		endfor
	endwhile
	return aligned
endfun

" }}}
" Indent {{{
fun! IndentFile()
	let winview = winsaveview()
	silent :w
	call system("indent -nbad -bap -nbc -bbo -hnl -br -brs -c33 -cd33 -ncdb "
	          \."-ce -ci4 -cli0 -d0 -di1 -nfc1 -i4 -ip0 -l80 -lp -npcs -nprs "
	          \."-npsl -sai -saf -saw -ncs -nsc -sob -nfca -cp33 -nss -ts4 -il1 "
	          \.expand('%:t'))
	:e
	" Make templates work properly
	if &filetype == 'cpp'
		" Fuck this there are too many edge cases
		silent! :%s/\v ?\< ?([^\<\>]*[^\<\> ]) ?\> ?/<\1> /g
		silent! :%s/\v(\<[^\<\>]*[^\<\> ]*\>) ([\(\)\[\]\{\};])/\1\2/g
	endif
	silent :w
	call winrestview(winview)
endfun
command! Indent call IndentFile()
" }}}
" Trim {{{
fun! TrimWhitespace()
	let l:line = line('.')
	let l:save = winsaveview()
	keeppatterns %s/\(^--\)\@<!\s\+$//eg " in email, ^-- should end with a space
	call winrestview(l:save)
	echo l:line
	execute ':'.l:line
endfun
" }}}
" Email {{{
let s:indent = '%(\> *)*'

fun! FormatEmailRead()
	" Yeah, I am big brain
	set textwidth=78
	silent g/\v^%(Cc|Bcc|Reply-To):\s*$/d " Remove empty unnecessary headers
	"silent g/\v^(%(\> *)*)$\n\zs^\1.{60,}$\ze\n^\1$/norm! gqj " reflow text

	" Rewrite 'Doe, John A' to 'John A Doe' or 'John Doe'. I am being petty --
	" it's generally best to leave things unchanged, but Imperial College's
	" systems reformat them into this, so I'm reformatting them back

	let s:email_match = '[^@]*\@imperial.ac.uk'

	let s:h = '%(From|To|Cc|Bcc):'         " header
	let s:fn = '([a-zA-Z-]+)( [a-zA-Z])*'  " first name and optional initial
	let s:ln = '([a-zA-Z- ]+)'             " last name
	let s:lnfn = s:ln.', '.s:fn            " Doe, John A B
	let s:replace = '\2 \1'                " no initial (or '\2\3 \1' for initial)

	" rfc822, quote
	let s:matches = [
		\ '^'.s:h.'\s*\zs"'.s:lnfn.'"\ze\s*\<'.s:email_match.'\>\s*,?\s*',
		\ '^'.s:indent.'%(On.*, )?\zs'.s:lnfn.'\ze\s*wrote:\s*$',
	\ ]

	for m in s:matches
		silent execute '%s/\v'.m.'/'.s:replace.'/e'
	endfor
endfun

fun! FormatEmailWrite()
	" Just accept it, my regex skills are glorious
	set textwidth=78
	let _i   = s:indent
	"let _i  = '' " don't format quoted

	let _h = '^'._i.'\s*[-_]+.*\n'
	" Don't want to join intentionally split things, for now I will assume
	" anything >60 chars can be split
	let g:paragraph_specifier  =
		\ '\v^('._i.')\s*$\n%('._h.')@!'
		\.'\zs%(^\1\s*[^>].{60,}$\ze\n)+%(^\1\s*[^>].*$\ze\n)%(^\1\s*$)+'
	while search(g:paragraph_specifier) != 0
		execute 's/\v^'._i.'\s*[^ ].*\zs\n^'._i.'/ /'
	endwhile
endfun

fun! Reply80()
	" Turn off auto wrap and stuff
	augroup EmailFormatting
		autocmd!
	augroup END
	" Remove double replies
	%s/\v%(^\>\s*\n)?%(^%(\> *){2,}.*\n)+(^\>\s*\n)?/\r/
endfun
command Reply80 call Reply80()

augroup EmailFormatting
	autocmd! BufWritePre *.eml            call FormatEmailWrite()
	autocmd! BufReadPost *.eml            call FormatEmailRead()
	autocmd! BufWritePre /tmp/mutt*       call FormatEmailWrite()
	autocmd! BufReadPost /tmp/mutt*       call FormatEmailRead()
	autocmd! BufWritePre /tmp/neomutt*    call FormatEmailWrite()
	autocmd! BufReadPost /tmp/neomutt*    call FormatEmailRead()
augroup END
" }}}
