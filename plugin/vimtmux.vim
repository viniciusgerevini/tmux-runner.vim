if exists("g:loaded_vimtmux")
  finish
endif

let g:loaded_vimtmux = 1

command -nargs=* VimTmuxRunCommand :call VimTmuxRunCommand(<args>)

function! VimTmuxRunCommand(command, ...)
  call VimTmuxSendText(a:command)
  call VimTmuxSendKeys("Enter")
endfunction

function! VimTmuxSendText(text)
  call VimTmuxSendKeys('"'.escape(a:text, '\"$`').'"')
endfunction

function! VimTmuxSendKeys(keys)
  call VimTmuxCommand("send-keys -t 1 ".a:keys)
endfunction

function! VimTmuxCommand(arguments)
  return system("tmux ".a:arguments)
endfunction

