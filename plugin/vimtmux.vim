if exists("g:loaded_vimtmux")
  finish
endif

let g:loaded_vimtmux = 1

command -nargs=* VimTmuxRunCommand :call VimTmuxRunCommand(<args>)
command -nargs=? VimTmuxSetRunner :call VimTmuxSetRunner(<args>)

function! VimTmuxRunCommand(command, ...)
  call VimTmuxSendText(a:command)
  call VimTmuxSendKeys("Enter")
endfunction

function! VimTmuxSetRunner(...)
  if exists("a:1")
      let g:VimTmuxRunnerId = VimTmuxGetIdForPane(string(a:1))
  endif
endfunction

function! VimTmuxSendText(text)
  call VimTmuxSendKeys('"'.escape(a:text, '\"$`').'"')
endfunction

function! VimTmuxSendKeys(keys)
  call VimTmuxCommand("send-keys -t ".g:VimTmuxRunnerId." ".a:keys)
endfunction

function! VimTmuxCommand(arguments)
  return system("tmux ".a:arguments)
endfunction

function! VimTmuxGetIdForPane(index)
  return substitute(VimTmuxCommand('display -p -t '.a:index.' "#{session_id}:#{window_id}.#{pane_id}"'), '\n$', '', '')
endfunction

