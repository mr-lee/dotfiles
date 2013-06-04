filetype off
call pathogen#runtime_append_all_bundles()
call pathogen#helptags()

" Code indenting
set foldmethod=indent
set foldlevel=99

" Movement around windows
map <c-j> <c-w>j
map <c-k> <c-w>k
map <c-l> <c-w>l
map <c-h> <c-w>h

filetype on
filetype plugin indent on
set number
syntax on
set cindent
set smartindent
"set mouse=a
set bg=dark
set ignorecase
set copyindent
set autoindent
set ts=2
set sw=2
set encoding=utf-8
set expandtab
set hlsearch


map <leader>td <Plug>TaskList
map <leader>g :GundoToggle<CR>

let g:pyflakes_use_quickfix = 0
let g:pep8_map='<leader>8'

" Tab completion configuration
au FileType python set omnifunc=pythoncomplete#Complete
let g:SuperTabDefaultCompletionType = "context"
set completeopt=menuone,longest,preview

"cheap hack to use cpp code completion with ctags in pathogen
au BufNewFile,BufRead,BufEnter *.cpp,*hpp set omnifunc=omni#cpp#complete#Main
autocmd FileType cpp set omnifunc=omni#cpp#complete#Main
"Enable c++ code completion using ctags
set tags+=~/.vim/tags/cpp
set tags+=~/.vim/tags/cpp_src/
set tags+=~/.vim/tags/qt4
set tags+=~/.vim/tags/wh_tags
"Hotkey to build tags for personal project
map <C-F6> :!ctags -R --sort=yes --c++-kinds=+pl --fields=+iaS --extra=+q .<CR>
"OmniCppComplete settings (derived from vim.wikia.com/wiki/VimTip1608)
let OmniCpp_NamespaceSearch = 1
let OmniCpp_GlobalScopeSearch = 1
let OmniCpp_ShowAccess = 1
let OmniCpp_ShowPrototypeInAbbr = 1 " show function parameters
let OmniCpp_MayCompleteDot = 1 " autocomplete after .
let OmniCpp_MayCompleteArrow = 1 " autocomplete after ->
let OmniCpp_MayCompleteScope = 1 " autocomplete after ::
let OmniCpp_DefaultNamespaces = ["std", "_GLIBCXX_STD"]
" automatically open and close the popup menu / preview window
au CursorMovedI,InsertLeave * if pumvisible() == 0|silent! pclose|endif
set completeopt=menuone,menu,longest,preview

"Ctags code browsing shortcuts for awesomeness
map <a-]> :vs <CR> :exec("tag ".expand("<cword>"))<CR>

"I'm sure there's a better key to use as leader, I hate meta keys...
map <c-c> <leader>

"Taglist function browser
map <leader>f :TlistToggle<CR>

" File browser
map <leader>n :NERDTreeToggle<CR>
"Configuration for nerdtree
let NERDTreeIgnore=['\.vim', '\.pyc', '\.o', '\.d', '\~$', '\.swp']

" Refactoring and go to definition
map <leader>j :RopeGotoDefinition<CR>
map <leader>r :RopeRename<CR>

nmap <leader>a <Esc>:Ack!
nmap <leader>s <Esc>:Ack!<C-R><C-W><CR>

" Git integration
set statusline+=%{fugitive#statusline()}

set showcmd

" Virtualenv recognition
py << EOF
import os.path
import sys
import vim
if 'VIRTUAL_ENV' in os.environ:
  project_base_dir = os.environ['VIRTUAL_ENV']
  sys.path.insert(0,project_base_dir)
  activate_this = os.path.join(project_base_dir, 'bin/activate_this.py')
  execfile(activate_this, dict(__file__=activate_this))
EOF

inoremap jj <ESC>

" Nosetest integration
map <leader>dt :set makerpg=python\ manage.py\ test\|:call MakeGreen()<CR>


"Bundles for vim-update-bundles
" Bundle: tope/fugitive 
" Bundle: msanders/snipmate.vim
" Bundle: tpope/vim-git
" Bundle: ervandew/supertab
" Bundle: sontek/minibufexpl.vim
" Bundle: wincent/Command-T
" Bundle: mitechie/pyflakes-pathogen
" Bundle: mileszs.ack.vim
" Bundle: sjl/gundo.vim
" Bundle: fs111/pydoc.vim
" Bundle: pep8
" Bundle: alfredodeza/pytest.vim
" Bundle: reinh/vim-makegreen
" Bundle: Tasklist.vim
" Bundle: The-NERD-tree
" Bundle: sontek/rope-vim
" Bundle: OmniCppComplete
