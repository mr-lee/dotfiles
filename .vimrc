" ==========================
" Plugin Manager (vim-plug)
" ==========================
" Auto-install vim-plug if missing
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'mbbill/undotree'
Plug 'itchyny/lightline.vim'
call plug#end()

" ==========================
" Core Settings
" ==========================
filetype plugin indent on
syntax on
set number
set smartindent
set autoindent
set copyindent
set expandtab
set tabstop=2
set shiftwidth=2
set encoding=utf-8
set background=dark
set showcmd
set hidden
set laststatus=2
set noshowmode

" ==========================
" Search
" ==========================
set hlsearch
set incsearch
set ignorecase
set smartcase

" ==========================
" Folding
" ==========================
set foldmethod=indent
set foldlevel=99

" ==========================
" Completion
" ==========================
set wildmenu
set wildmode=longest:full,full
set completeopt=menuone,longest,preview
set backspace=indent,eol,start

" ==========================
" Visual
" ==========================
set cursorline
set scrolloff=5
set signcolumn=yes

" ==========================
" Persistent Undo
" ==========================
set undofile
set undodir=~/.vim/undodir

" ==========================
" Window Navigation
" ==========================
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l
map <C-h> <C-w>h

" ==========================
" Key Bindings
" ==========================
let mapleader = " "
inoremap jj <ESC>

" fzf
nnoremap <leader>f :Files<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>a :Rg<CR>
nnoremap <leader>s :Rg <C-R><C-W><CR>
nnoremap <leader>/ :BLines<CR>

" Undotree
nnoremap <leader>u :UndotreeToggle<CR>

" Fugitive
nnoremap <leader>gs :Git<CR>
nnoremap <leader>gd :Gdiffsplit<CR>
nnoremap <leader>gb :Git blame<CR>
nnoremap <leader>gl :Git log --oneline<CR>

" File browser (netrw)
nnoremap <leader>n :Explore<CR>

" Clear search highlight
nnoremap <leader><space> :nohlsearch<CR>

" Quick save
nnoremap <leader>w :w<CR>

" ==========================
" Lightline
" ==========================
let g:lightline = {
  \ 'active': {
  \   'left': [ ['mode', 'paste'], ['gitbranch', 'readonly', 'filename', 'modified'] ],
  \ },
  \ 'component_function': {
  \   'gitbranch': 'FugitiveHead',
  \ },
  \ }

" ==========================
" fzf
" ==========================
let g:fzf_layout = { 'down': '~40%' }
