let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

if has("nvim")
  let g:plug_home = stdpath('data') . '/plugged'
endif

call plug#begin()

if has("nvim")
  Plug 'morhetz/gruvbox'
  Plug 'vim-airline/vim-airline'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'jiangmiao/auto-pairs'
  Plug 'vim-vdebug/vdebug'
"  Plug 'preservim/nerdtree'
"  Plug 'Xuyuanp/nerdtree-git-plugin'
"  Plug 'ryanoasis/vim-devicons'
  Plug 'nvim-tree/nvim-web-devicons' " optional, for file icons
  Plug 'nvim-tree/nvim-tree.lua'
  Plug 'vim-syntastic/syntastic'
  Plug 'nelsyeung/twig.vim'
  Plug 'preservim/nerdcommenter'
  Plug 'ap/vim-css-color'
  Plug 'kkoomen/vim-doge', { 'do': { -> doge#install() } }
  Plug 'nvim-lua/plenary.nvim'
  Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.x' }
endif

call plug#end()
