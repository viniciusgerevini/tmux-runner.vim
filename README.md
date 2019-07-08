# VimTmux

This plugin allows you to interact with Tmux without leaving Vim.
It was inspired by [Vimux](https://github.com/benmills/vimux) (used as reference), which has similar features, but hasn't been accepting updates for a while.

Some of VimTmux main improvements are:

- Command prompt has command line completion
- You can choose your runner manually by providing its id, name or index
- Changing layouts and creating new panes do not affect the current runner
- Various options for auto-selecting pane as runner: last active, nearest, new

# Installation

[VimPlug](https://github.com/junegunn/vim-plug): `Plug 'viniciusgerevini/vimtmux'`

[Vundle](https://github.com/VundleVim/Vundle.vim): `Plugin 'viniciusgerevini/vimtmux'`

[Pathogen](https://github.com/tpope/vim-pathogen) `cd ~/.vim/bundle && git clone https://github.com/viniciusgerevini/vimtmux`

Manual Instalation: copy `./plugin/vimtmux.vim` to your plugins folder.

# Usage

*Mappings example:*
```
" Prompt command
map <Leader>vp :VimTmuxPromptCommand<CR>

" Open VimTmux prompt with current buffer name
map <Leader>vr :VimTmuxPromptCommand bufname("%")<CR>

" Run last command executed
map <Leader>vl :VimTmuxRunLastCommand<CR>

" Edit last command and rerun
map <Leader>ve :VimTmuxEditCommand<CR>

" Inspect runner pane
map <Leader>vi :VimTmuxInspectRunner<CR>

" Scroll down pane
map <Leader>vd :VimTmuxScrollDownRunner<CR>

" Scroll up pane
map <Leader>vu :VimTmuxScrollUpRunner<CR>

" Zoom the tmux runner pane
map <Leader>vz :VimTmuxZoomRunner<CR>

" Close pane
map <Leader>vq :VimTmuxCloseRunner<CR>

" Clear pane
map <Leader>vc :VimTmuxClearRunner<CR>

" Stop execution in pane
map <Leader>vx :VimTmuxStopRunner<CR>

" Set new pane as runner
map <leader>vs :VimTmuxPromptRunner<CR>
```

*Options:*
```
" Runner pane size
let g:VimTmuxRunnerSize = 20

" Runner pane split orientation
let g:VimTmuxRunnerOrientation = 'v'

" Define how new runners are chosen
let g:VimTmuxNewRunnerMode = 'new'

" Custom order for 'nearest' mode
let g:VimTmuxRunnerNearestSelectionOrder = ['down-of', 'right-of']

" Tmux executable to use
let g:VimTmuxExecutable = 'tmate'
```
For more information `:help vimtmux` or online [docs](./doc/vimtmux.txt).

# License

MIT
