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
" set the leader key to the spacebar
nnoremap <SPACE> <Nop>
let mapleader=" "

" indents
set shiftwidth=2
set tabstop=2
set smartindent     " Smart autoindenting when starting a new line
set autoindent      " copy indent from current line when starting a new line
set expandtab       " use appropriate number of spaces to insert a tab"
set smarttab        " tab in front of a line inserts blanks according to 'shiftwidth'

" editor
set encoding=UTF-8         " Set encoding to UTF-8
set number relativenumber  " show line numbers
set title                  " show the filename in the terminal window
set scrolloff=10           " number of scroll lines to keep above and below the cursor
set autoread               " automatically read file changes outside of vim from disk
set colorcolumn=80         " adds a vertical line at 80 characters
set spell spelllang=en_us  " enables spell checking
set clipboard=unnamed      " allows clipboard access across other applications

" nerdcommenter
filetype plugin on                          " enable filetype plugin for nerdcommenter
nmap <leader>/ <plug>NERDCommenterToggle    " remap comment toggle for normal mode
vmap <leader>/ <plug>NERDCommenterToggle gv " remap comment toggle for visual mode

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
autocmd vimenter * ++nested colorscheme gruvbox
set cursorline
"}}}

" Plugins "{{{
" ---------------------------------------------------------------------
runtime ./plugins/coc.vim
runtime ./plugins/nerdtree.vim
runtime ./plugins/vdebug.vim
runtime ./plugins/templates.vim
runtime ./plugins/telescope.vim
"}}}
