function! s:SendToTerm(what)
  call term_sendkeys('', a:what)
  return ''
endfunc

let s:term_set_default_mapping = 1
if exists("g:term_set_default_mapping")
  let s:term_set_default_mapping = g:term_set_default_mapping
endif

if (has('nvim') || v:version >= 801) && s:term_set_default_mapping
  " Leave terminal with Ctrl-q
  tnoremap <C-q>  <C-\><C-n>

  " Make Neovim supporting the Ctrl-w mapping like Vim does
  " tnoremap <C-w> <C-w>
  tnoremap <C-w><C-w> <cmd>wincmd w<CR>
  tnoremap <C-w>w <cmd>wincmd w<CR>
  tnoremap <C-w>p <cmd>wincmd p<CR>

  tnoremap <C-w>h <cmd>wincmd h<CR>
  tnoremap <C-w>j <cmd>wincmd j<CR>
  tnoremap <C-w>k <cmd>wincmd k<CR>
  tnoremap <C-w>l <cmd>wincmd l<CR>

  " Make <kbd>Ctrl-v</kbd> paste the content of the clipboard into the terminal
  tnoremap <expr> <C-v> getreg('*')

  " Make <kbd>Ctrl-Enter</kbd> passed correctly into the terminal
  tnoremap <expr> <C-Cr> <SID>SendToTerm("\<Esc>\<Cr>")
endif

function! s:TermGo(...) abort
  " - Switch to existing terminal window if any
  "   Otherwise create one
  " - Switch the terminal window to the desired terminal buffer
  "   Otherwise create one
  let l:bufindex = 0
  if a:0 == 0 || a:1 == "0"
    " If no name is given use the working directory:
    let l:name = fnamemodify(getcwd(), ':p')

    " If no name is given use the current file directory:
    " let l:name = fnamemodify(expand('%:p:h'), ':p')
  else
    if a:1 =~ '^\d\+'
      " The argument is the buffer index:
      let l:bufindex = str2nr(a:1)
      let l:name = ''
    else
      " The argument is the terminal "name"
      let l:name = expand(a:1)
      if !isdirectory(l:name)
        " If the name given is the name of a file
        " use the parent folder
        " End with '/'
        let l:name = fnamemodify(fnamemodify(l:name, ':p:h'), ':p')
      else
        " End with '/'
        let l:name = fnamemodify(l:name, ':p')
      endif
    endif
  endif

  let l:term_width = 100
  if exists('g:term_width')
    let l:term_width = g:term_width
  endif

  let win_infos = getwininfo()
  call filter(win_infos, "v:val.terminal")
  call filter(win_infos, {_, x -> x.tabnr == tabpagenr()})
  if len(win_infos)
    " If a terminal window exist with the right name/index switch to it:
    let winnr = win_infos[-1].winnr
    if l:bufindex != 0
      " The argument is the buffer index:
      let win_info = filter(win_infos, "v:val.bufnr ==" . l:bufindex)
    else
      " The argument is the terminal "name"
      let win_info = filter(win_infos, "getbufvar(v:val.bufnr, 'terminal_name')=='" . l:name . "'")
    endif

    if len(win_info) > 0
      " A window has been found:
      let winnr = win_info[0].winnr
      execute winnr . 'wincmd w'
      return
    endif

    " Otherwise if a terminal window exist reuse it:
    execute winnr . 'wincmd w'
  else
    " If no terminal window create a vertical window at the right side:
    wincmd s
    wincmd L
    execute l:term_width . "wincmd |"
    " 100wincmd |
    set winfixwidth
    let winnr = winnr()
  endif

  " Search among existing terminal buffer:
  if l:bufindex != 0
    let buf_infos = filter(getbufinfo(), "v:val.bufnr ==" . l:bufindex)
  else
    let buf_infos = filter(getbufinfo(), "getbufvar(v:val.bufnr, '&buftype')=='terminal'")
  endif
  if len(buf_infos)
    if l:bufindex == 0
      let buf_infos = filter(buf_infos, "getbufvar(v:val.bufnr, 'terminal_name')=='" . l:name . "'")
    endif
    if len(buf_infos)
      " If a hidden terminal with the right name exist use it:
      execute 'buffer ' . buf_infos[0].bufnr
      return
    endif
  endif

  if l:bufindex != 0
    echom 'Fail to find buffer:' . l:bufindex
    return
  endif

  let l:workingdir = getcwd()
  if l:name != l:workingdir
    " Change the working directory temporarily
    " In order to create the terminal with the correct working directory
    execute 'cd' l:name

    let l:restore_rooter = 0
    if exists('g:rooter_manual_only') && !g:rooter_manual_only
      " Disable vim-rooter temporarily
      RooterToggle
      let l:restore_rooter = 1
    endif
  endif

  let l:term_command = ''
  if exists('g:term_command')
    let l:term_command = g:term_command
  endif

  " Load a new terminal into the window:
  if has('nvim')
    " The redirection to >nul hide the output of the console
    " terminal cmd.exe /s /k C:\Softs\Clink\Clink.bat inject
    execute "terminal" g:term_command
    " Switch to console mode:
    norma a
  else
    " 96 = 100 - &numberwidth
    " &signcolumn == yes -> 2 columns
    " &numberwidth -> max(&numberwidth, ceil(log(line('$'))/log(10)) + 1)
    " terminal ++curwin ++cols=96 ++close ++kill=kill cmd.exe /k C:\Softs\Clink\Clink.bat inject >nul
    execute "terminal" "++curwin" "++cols=" . (l:term_width - &numberwidth) "++close" "++kill=kill" l:term_command
  endif

  setlocal nobuflisted
  let b:terminal_name = l:name
  " Set a name for the terminal buffer:
  execute 'file' 'Term ' . bufnr()

  if l:name != l:workingdir
    execute 'cd' l:workingdir
    if l:restore_rooter
      RooterToggle
    endif
  endif
endfunction

function! s:TermComplete(arg_lead, cmd_line, position)
  let ret = map(s:TermList(), {_, val -> val[1]})
  return join(ret, "\n")
endfunction

command! -complete=custom,<SID>TermComplete -nargs=? TermGo call <SID>TermGo(<f-args>)

function! s:TermToggle(name)
  let win_infos = getwininfo()
  call filter(win_infos, "v:val.terminal")
  call filter(win_infos, {_, x -> x.tabnr == tabpagenr()})
  if len(win_infos)
    " If a terminal window exist go to the terminal:
    for i in range(len(win_infos)-1, 0, -1)
      execute win_infos[i].winnr . 'wincmd c'
    endfor
    return
  else
    call s:TermGo(a:name)
  endif
endfunction

nnoremap <Plug>(TermToggle) <cmd>call <SID>TermToggle(expand('%:p:h'))<CR>

function! s:TermList()
  let ret = []
  let buf_infos = filter(getbufinfo(), "getbufvar(v:val.bufnr, '&buftype')=='terminal'")

  let cwd = getcwd()
  let cwd = fnamemodify(cwd, ':p')

  for buf_info in buf_infos
    if !has_key(buf_info.variables, 'terminal_name')
      continue
    endif
    let terminal_name  = buf_info.variables.terminal_name
    if terminal_name[0:len(cwd)-1] ==# cwd
      let terminal_name = terminal_name[len(cwd):]
      if terminal_name == ''
        let terminal_name = '.'
      endif
    endif
    call add(ret, [buf_info.bufnr, terminal_name])
  endfor
  return ret
endfunction

command TermList echo join(map(<SID>TermList(), {_, val -> printf("%3d %s", val[0], val[1])}), "\n")

function! s:GetTermBufNr(name)
    let buf_infos = getbufinfo()
    call filter(buf_infos, "getbufvar(v:val.bufnr, '&buftype')=='terminal'")
    call filter(buf_infos, "getbufvar(v:val.bufnr, 'terminal_name')=='" . a:name . "'")
    if len(buf_infos)
      return buf_infos[0].bufnr
    endif
    return 0
endfunction

function! Term(terminal, ...)
  let l:winnr = winnr()
  call s:TermGo(a:terminal)
  let l:mode = mode()
  if l:mode != "t"
    " Switch to terminal mode:
    normal a
  endif
  if a:0
    let l:what = a:1
    call term_sendkeys(bufnr(), l:what . "\<Cr>")

    " Try to switch back to normal mode:
    " if l:mode != mode()
    "   call term_wait(bufnr())
    "   call feedkeys("\<C-\>\<C-n>", "x")
    " endif

    if winnr() != l:winnr
      " Don't switch to terminal if a command has been executed
      wincmd p
    endif
  endif
endfunction

command! -count -nargs=? Term call Term(<count>, <f-args>)

