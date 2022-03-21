if has("nvim")
  let g:plug_home = stdpath('data') . '/plugged'
endif

call plug#begin()

if has("nvim")
  Plug 'arcticicestudio/nord-vim'
  Plug 'vim-airline/vim-airline'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'Raimondi/delimitMate'
  Plug 'Shougo/denite.nvim'
  Plug 'vim-vdebug/vdebug'
  Plug 'preservim/nerdtree'
  Plug 'Xuyuanp/nerdtree-git-plugin'
  Plug 'ryanoasis/vim-devicons'
  Plug 'vim-syntastic/syntastic'
  Plug 'rust-lang/rust.vim'
  Plug 'nelsyeung/twig.vim'
  Plug 'preservim/nerdcommenter'
endif

call plug#end()
