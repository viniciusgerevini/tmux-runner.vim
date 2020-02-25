# TmuxRunner.vim

This plugin allows you to interact with Tmux without leaving Vim.
It was inspired by [Vimux](https://github.com/benmills/vimux) (used as reference), which has similar features, but hasn't been accepting updates for a while.

Some of TmuxRunner main improvements are:

- Command prompt has command line completion
- You can choose your runner manually by providing its id, name or index
- Changing layouts and creating new panes do not affect the current runner
- Various options for auto-selecting pane as runner: last active, nearest, new

# Installation

[VimPlug](https://github.com/junegunn/vim-plug): `Plug 'viniciusgerevini/tmux-runner.vim'`

[Vundle](https://github.com/VundleVim/Vundle.vim): `Plugin 'viniciusgerevini/tmux-runner.vim'`

[Pathogen](https://github.com/tpope/vim-pathogen) `cd ~/.vim/bundle && git clone https://github.com/viniciusgerevini/tmux-runner.vim`

Manual Instalation: copy `./plugin/tmux-runner.vim` to your plugins folder.

# Usage

*Mappings example:*
```
" Prompt command
map <Leader>tp :TmuxRunnerPromptCommand<CR>

" Open TmuxRunner prompt with current buffer name
map <Leader>tr :TmuxRunnerPromptCommand bufname("%")<CR>

" Run last command executed
map <Leader>tl :TmuxRunnerRunLastCommand<CR>

" Edit last command and rerun
map <Leader>te :TmuxRunnerEditCommand<CR>

" Inspect runner pane
map <Leader>ti :TmuxRunnerInspect<CR>

" Scroll down pane
map <Leader>td :TmuxRunnerScrollDown<CR>

" Scroll up pane
map <Leader>tu :TmuxRunnerScrollUp<CR>

" Zoom the tmux runner pane
map <Leader>tz :TmuxRunnerZoom<CR>

" Close pane
map <Leader>tq :TmuxRunnerClose<CR>

" Clear pane
map <Leader>tc :TmuxRunnerClear<CR>

" Stop execution in pane
map <Leader>tx :TmuxRunnerStop<CR>

" Set new pane as runner
map <leader>ts :TmuxRunnerPromptRunner<CR>
```

*Options:*
```
" Runner pane size
let g:TmuxRunnerSize = 20

" Runner pane split orientation
let g:TmuxRunnerOrientation = 'v'

" Define how new runners are chosen
let g:TmuxRunnerNewRunnerMode = 'new'

" Custom order for 'nearest' mode
let g:TmuxRunnerNearestSelectionOrder = ['down-of', 'right-of']

" Tmux executable to use
let g:TmuxRunnerExecutable = 'tmate'
```
For more information `:help tmux-runner` or online [docs](./doc/tmux-runner.txt).

# License

MIT
