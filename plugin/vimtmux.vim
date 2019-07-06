if exists("g:loaded_vimtmux")
  finish
endif

let g:loaded_vimtmux = 1

command -nargs=* VimTmuxRunCommand :call VimTmuxRunCommand(<args>)
command -nargs=? VimTmuxPromptCommand :call VimTmuxPromptCommand(<args>)
command -nargs=? VimTmuxSetRunner :call VimTmuxSetRunner(<args>)
command -nargs=? VimTmuxPromptRunner :call VimTmuxPromptRunner(<args>)

function! VimTmuxRunCommand(command, ...)
  if VimTmuxDoesPaneExist() == 0
    call VimTmuxOpenRunner()
  endif

  call VimTmuxSendText(a:command)
  call VimTmuxSendKeys("Enter")
endfunction

function! VimTmuxPromptCommand(...)
  let defaultCommand = exists("a:1") ? a:1 : ""
  let l:command = input("Command: ", defaultCommand, 'shellcmd')
  if l:command != ""
    call VimTmuxRunCommand(l:command)
  endif
endfunction

function! VimTmuxPromptRunner(...)
  let l:runner = input("Set new runner: ")
  call VimTmuxSetRunner(l:runner)
endfunction

function! VimTmuxSetRunner(...)
  if exists("a:1")
    let l:newRunner = VimTmuxGetIdForPane(string(a:1))
    if v:shell_error == 0
      let g:VimTmuxRunnerId = l:newRunner
    else
      echo "Runner error: ".g:VimTmuxRunnerId
    endif
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

function! VimTmuxOption(option, default)
  return exists(a:option) ? eval(a:option) : a:default
endfunction

function! VimTmuxGetIdForPane(...)
  let l:target = exists("a:1") ? ' -t '.a:1 : ''

  return substitute(VimTmuxCommand('display -p '.l:target.' "#{session_id}:#{window_id}.#{pane_id}"'), '\n$', '', '')
endfunction

function! VimTmuxDoesPaneExist()
  if !exists("g:VimTmuxRunnerId") || g:VimTmuxRunnerId == ""
    return 0
  endif

  call VimTmuxCommand('has -t '.g:VimTmuxRunnerId)

  return v:shell_error == 0
endfunction

function! VimTmuxOpenRunner()
  let l:orientation = VimTmuxOption("g:VimTmuxRunnerOrientation", "v") == "h" ? "h" : "v"
  let l:size = VimTmuxOption("g:VimTmuxRunnerSize", 20)

  call VimTmuxCommand("split-window -p ".l:size." -".l:orientation)
  let g:VimTmuxRunnerId = VimTmuxGetIdForPane()
  call VimTmuxCommand("last-pane")
endfunction

