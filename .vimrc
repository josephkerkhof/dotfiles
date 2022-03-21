" Specify a directory for plugins
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

" Initialize plugin system
call plug#end()

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

" turn hybrid line numbers on
set number relativenumber
set nu rnu

" Line length marker
call matchadd('ColorColumn', '\%81v', 100)

" Fonts
set guifont=Fira\ Code\ Medium\ 12
set encoding=UTF-8

" Templates
if has("autocmd")
  augroup templates
    autocmd BufNewFile */devotions/** 0r ~/.vim/templates/devotions.skeleton
    autocmd VimEnter */devotions/** :call DevotionCurrentDate()
    autocmd BufNewFile */journal/** 0r ~/.vim/templates/journal.skeleton
    autocmd VimEnter */journal/** :call JournalCurrentDate()
  augroup END
endif
fun JournalCurrentDate()
  exe "1,1g/Journal entry for/s/Journal entry for.*/Journal entry for " .
  \ strftime("%B %-d, %Y")
endfun
fun DevotionCurrentDate()
  exe "1,1g/Devotion for/s/Devotion for.*/Devotion for " .
  \ strftime("%B %-d, %Y")
endfun

" whitespace help
filetype plugin indent on
" show existing tab with 4 spaces width
set tabstop=4
" when indenting with '>', use 4 spaces width
set shiftwidth=4
" On pressing tab, insert 4 spaces
set expandtab

