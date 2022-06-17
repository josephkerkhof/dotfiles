if has("nvim")
  let g:plug_home = stdpath('data') . '/plugged'
endif

call plug#begin()

if has("nvim")
  Plug 'arcticicestudio/nord-vim'
  Plug 'vim-airline/vim-airline'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'jiangmiao/auto-pairs'
  Plug 'Shougo/denite.nvim'
  Plug 'vim-vdebug/vdebug'
  Plug 'preservim/nerdtree'
  Plug 'Xuyuanp/nerdtree-git-plugin'
  Plug 'ryanoasis/vim-devicons'
  Plug 'vim-syntastic/syntastic'
  Plug 'rust-lang/rust.vim'
  Plug 'nelsyeung/twig.vim'
  Plug 'preservim/nerdcommenter'
  Plug 'ap/vim-css-color'
  Plug 'kkoomen/vim-doge', { 'do': { -> doge#install() } }
endif

call plug#end()
