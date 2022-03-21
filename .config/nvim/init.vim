" Imports "{{{
" ---------------------------------------------------------------------
runtime ./plug.vim
if has("unix")
  let s:uname = system("uname -s")
  " Do Mac stuff
  if s:uname == "Darwin\n"
    runtime ./macos.vim
  endif
endif
"}}}

" Fundamentals "{{{
" ---------------------------------------------------------------------
" indents
set shiftwidth=2
set tabstop=2
set smartindent     " Smart autoindenting when starting a new line
set autoindent      " copy indent from current line when starting a new line
set expandtab       " use appropriate number of spaces to insert a tab"
set smarttab        " tab in front of a line inserts blanks according to 'shiftwidth'

" editor
set encoding=UTF-8  " Set encoding to UFT-8
set number          " show line numbers
set title           " show the filename in the terminal window
set scrolloff=10    " number of scroll lines to keep above and below the cursor
filetype plugin on  " enable filetype plugin for nerdcommenter
set autoread        " automatically read file changes outside of vim from disk
set colorcolumn=80  " adds a vertical line at 80 characters

" whitespace characters
set list listchars=tab:>-,trail:~,space:·,extends:>,precedes:<

" Disable Arrow keys in Normal mode
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>

" Disable Arrow keys in Insert mode
imap <up> <nop>
imap <down> <nop>
imap <left> <nop>
imap <right> <nop>
"}}}

" Colors and Theme "{{{
" ---------------------------------------------------------------------
colorscheme nord
set cursorline
let g:nord_cursor_line_number_background = 1
"}}}

" Airline "{{{
" ---------------------------------------------------------------------
let g:airline_powerline_fonts = 1
"}}}

" Terminal "{{{
" ---------------------------------------------------------------------
" set insert mode when opening terminal
autocmd TermOpen * startinsert
" remove line numbers in the terminal
autocmd TermOpen * setlocal nonumber norelativenumber

" Toggle terminal function
let g:term_buf = 0
let g:term_win = 0
function! TermToggle(height)
  if win_gotoid(g:term_win)
    hide
  else
    botright new
    exec "resize " . a:height
    try
      exec "buffer " . g:term_buf
    catch
      call termopen($SHELL, {"detach": 0})
      let g:term_buf = bufnr("")
      set nonumber
      set norelativenumber
      set signcolumn=no
    endtry
    startinsert!
    let g:term_win = win_getid()
  endif
endfunction

" Toggle terminal on/off
nnoremap <A-t> :call TermToggle(12)<CR>
inoremap <A-t> <Esc>:call TermToggle(12)<CR>
tnoremap <A-t> <C-\><C-n>:call TermToggle(12)<CR>

" Terminal go back to normal mode
tnoremap <Esc> <C-\><C-n>
tnoremap :q! <C-\><C-n>:q!<CR>
"}}}

" Plugins "{{{
" ---------------------------------------------------------------------
runtime ./plugins/coc.vim
runtime ./plugins/nerdtree.vim
runtime ./plugins/vdebug.vim
"runtime ./plugins/syntastic.vim
runtime ./plugins/rust.vim
runtime ./plugins/templates.vim
runtime ./plugins/denite.vim
"}}}
