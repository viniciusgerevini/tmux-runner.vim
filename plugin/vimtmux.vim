if exists("g:loaded_vimtmux")
  finish
endif

let g:loaded_vimtmux = 1

command -nargs=* VimTmuxRunCommand :call VimTmuxRunCommand(<args>)
command -nargs=? VimTmuxPromptCommand :call VimTmuxPromptCommand(<args>)
command VimTmuxRunLastCommand :call VimTmuxRunLastCommand()
command -nargs=? VimTmuxSetRunner :call VimTmuxSetRunner(<args>)
command -nargs=? VimTmuxPromptRunner :call VimTmuxPromptRunner(<args>)
command VimTmuxOpenRunner :call VimTmuxOpenRunner()
command VimTmuxCloseRunner :call VimTmuxCloseRunner()
command VimTmuxStopRunner :call VimTmuxStopRunner()
command VimTmuxZoomRunner :call VimTmuxZoomRunner()
command VimTmuxClearRunner :call VimTmuxClearRunner()
command VimTmuxInspectRunner :call VimTmuxInspectRunner()
command VimTmuxScrollUpRunner :call VimTmuxScrollUpRunner()
command VimTmuxScrollDownRunner :call VimTmuxScrollDownRunner()

function! VimTmuxRunCommand(command, ...)
  if VimTmuxDoesPaneExist() == 0
    if VimTmuxStartRunner() == 0
      return
    endif
  endif

  let g:VimTmuxLastCommand = a:command

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

function! VimTmuxRunLastCommand()
  if exists("g:VimTmuxLastCommand")
    call VimTmuxRunCommand(g:VimTmuxLastCommand)
  else
    echo "No command to run"
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
  let l:orientation = VimTmuxOptionRunnerOrientation()
  let l:size = VimTmuxOptionRunnerSize()

  call VimTmuxCommand("split-window -p ".l:size." -".l:orientation)
  let g:VimTmuxRunnerId = VimTmuxGetIdForPane()
  call VimTmuxCommand("last-pane")
endfunction

function! VimTmuxCloseRunner()
  if VimTmuxDoesPaneExist() == 1
    call VimTmuxCommand("kill-pane -t ".g:VimTmuxRunnerId)
    unlet g:VimTmuxRunnerId
  endif
endfunction

function! VimTmuxStopRunner()
  call VimTmuxSendKeys("^c")
endfunction

function! VimTmuxZoomRunner()
  if VimTmuxDoesPaneExist() == 1
    call VimTmuxCommand("resize-pane -Z -t ".g:VimTmuxRunnerId)
  endif
endfunction

function! VimTmuxClearRunner()
  if VimTmuxDoesPaneExist() == 1
    call VimTmuxSendText("clear")
    call VimTmuxSendKeys("Enter")
    call VimTmuxCommand("clear-history -t ".g:VimTmuxRunnerId)
  endif
endfunction

function! VimTmuxInspectRunner()
  if VimTmuxDoesPaneExist() == 1
    call VimTmuxCommand("select-pane -t ".g:VimTmuxRunnerId)
    call VimTmuxCommand("copy-mode")
  endif
endfunction

function! VimTmuxScrollUpRunner()
  if VimTmuxDoesPaneExist() == 1
    call VimTmuxInspectRunner()
    call VimTmuxSendKeys("C-u")
    call VimTmuxCommand("last-pane")
  endif
endfunction

function! VimTmuxScrollDownRunner()
  if VimTmuxDoesPaneExist() == 1
    call VimTmuxInspectRunner()
    call VimTmuxSendKeys("C-d")
    call VimTmuxCommand("last-pane")
  endif
endfunction

function! VimTmuxStartRunner()
  let l:runnerMode = exists("g:VimTmuxNewRunnerMode") ? g:VimTmuxNewRunnerMode : "new"

  if l:runnerMode == 'new'
    call VimTmuxOpenRunner()
    return 1
  elseif l:runnerMode == 'nearest'
    call VimTmuxNewRunnerWithNearestPane()
    return 1
  elseif l:runnerMode == 'last'
    call VimTmuxNewRunnerLastActivePane()
    return 1
  else
    redraw
    echo 'Runner not defined'
    return 0
  endif
endfunction

function! VimTmuxNewRunnerWithNearestPane()
  let l:splitOrientation = VimTmuxOptionRunnerOrientation()

  if exists('g:VimTmuxRunnerNearestSelectionOrder')
    let l:nearestDirectionOrder = g:VimTmuxRunnerNearestSelectionOrder
  elseif l:splitOrientation == "v"
    let l:nearestDirectionOrder = ['down-of', 'right-of']
  else
    let l:nearestDirectionOrder = ['right-of', 'down-of']
  endif

  for direction in l:nearestDirectionOrder
    call VimTmuxCommand('select-pane -t {'.direction.'}')
    if v:shell_error == 0
      let g:VimTmuxRunnerId = VimTmuxGetIdForPane()
      call VimTmuxCommand("last-pane")
      return
    endif
  endfor

  call VimTmuxOpenRunner()
endfunction

function! VimTmuxOptionRunnerOrientation()
  return VimTmuxOption("g:VimTmuxRunnerOrientation", "v") == "h" ? "h" : "v"
endfunction

function! VimTmuxNewRunnerLastActivePane()
  let l:currentPaneId = VimTmuxGetIdForPane()
  call VimTmuxCommand("last-pane")
  let l:lastActivePaneId = VimTmuxGetIdForPane()
  call VimTmuxCommand("last-pane")

  if l:currentPaneId == l:lastActivePaneId
    call VimTmuxOpenRunner()
  else
    let g:VimTmuxRunnerId = l:lastActivePaneId
  endif
endfunction

function! VimTmuxOptionRunnerSize()
  return VimTmuxOption("g:VimTmuxRunnerSize", 20)
endfunction
