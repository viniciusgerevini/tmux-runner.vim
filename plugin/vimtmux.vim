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
  if s:VimTmuxDoesPaneExist() == 0
    if s:VimTmuxStartRunner() == 0
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
  if l:runner != ""
    call VimTmuxSetRunner(l:runner)
  endif
endfunction

function! VimTmuxSetRunner(...)
  if exists("a:1")
    let l:newRunner = s:VimTmuxGetIdForPane(string(a:1))
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
  call s:VimTmuxCommand("send-keys -t ".g:VimTmuxRunnerId." ".a:keys)
endfunction

function! s:VimTmuxCommand(arguments)
  return system("tmux ".a:arguments)
endfunction

function! s:VimTmuxOption(option, default)
  return exists(a:option) ? eval(a:option) : a:default
endfunction

function! s:VimTmuxGetIdForPane(...)
  let l:target = exists("a:1") ? ' -t '.a:1 : ''

  return substitute(s:VimTmuxCommand('display -p '.l:target.' "#{session_id}:#{window_id}.#{pane_id}"'), '\n$', '', '')
endfunction

function! s:VimTmuxDoesPaneExist()
  if !exists("g:VimTmuxRunnerId") || g:VimTmuxRunnerId == ""
    return 0
  endif

  call s:VimTmuxCommand('has -t '.g:VimTmuxRunnerId)

  return v:shell_error == 0
endfunction

function! VimTmuxOpenRunner()
  let l:orientation = s:VimTmuxOptionRunnerOrientation()
  let l:size = s:VimTmuxOptionRunnerSize()

  call s:VimTmuxCommand("split-window -p ".l:size." -".l:orientation)
  let g:VimTmuxRunnerId = s:VimTmuxGetIdForPane()
  call s:VimTmuxCommand("last-pane")
endfunction

function! VimTmuxCloseRunner()
  if s:VimTmuxDoesPaneExist() == 1
    call s:VimTmuxCommand("kill-pane -t ".g:VimTmuxRunnerId)
    unlet g:VimTmuxRunnerId
  endif
endfunction

function! VimTmuxStopRunner()
  call VimTmuxSendKeys("^c")
endfunction

function! VimTmuxZoomRunner()
  if s:VimTmuxDoesPaneExist() == 1
    call s:VimTmuxCommand("resize-pane -Z -t ".g:VimTmuxRunnerId)
  endif
endfunction

function! VimTmuxClearRunner()
  if s:VimTmuxDoesPaneExist() == 1
    call VimTmuxSendText("clear")
    call VimTmuxSendKeys("Enter")
    call s:VimTmuxCommand("clear-history -t ".g:VimTmuxRunnerId)
  endif
endfunction

function! VimTmuxInspectRunner()
  if s:VimTmuxDoesPaneExist() == 1
    call s:VimTmuxCommand("select-pane -t ".g:VimTmuxRunnerId)
    call s:VimTmuxCommand("copy-mode")
  endif
endfunction

function! VimTmuxScrollUpRunner()
  if s:VimTmuxDoesPaneExist() == 1
    call VimTmuxInspectRunner()
    call VimTmuxSendKeys("C-u")
    call s:VimTmuxCommand("last-pane")
  endif
endfunction

function! VimTmuxScrollDownRunner()
  if s:VimTmuxDoesPaneExist() == 1
    call VimTmuxInspectRunner()
    call VimTmuxSendKeys("C-d")
    call s:VimTmuxCommand("last-pane")
  endif
endfunction

function! s:VimTmuxStartRunner()
  let l:runnerMode = exists("g:VimTmuxNewRunnerMode") ? g:VimTmuxNewRunnerMode : "new"

  if l:runnerMode == 'new'
    call VimTmuxOpenRunner()
    return 1
  elseif l:runnerMode == 'nearest'
    call s:VimTmuxNewRunnerWithNearestPane()
    return 1
  elseif l:runnerMode == 'last'
    call s:VimTmuxNewRunnerLastActivePane()
    return 1
  else
    redraw
    echo 'Runner not defined'
    return 0
  endif
endfunction

function! s:VimTmuxNewRunnerWithNearestPane()
  let l:nearestDirectionOrder = s:VimTmuxNearestSelectionOrder()

  for direction in l:nearestDirectionOrder
    call s:VimTmuxCommand('select-pane -t {'.direction.'}')
    if v:shell_error == 0
      let g:VimTmuxRunnerId = s:VimTmuxGetIdForPane()
      call s:VimTmuxCommand("last-pane")
      return
    endif
  endfor

  call VimTmuxOpenRunner()
endfunction

function! s:VimTmuxNearestSelectionOrder()
  if exists('g:VimTmuxRunnerNearestSelectionOrder')
    return g:VimTmuxRunnerNearestSelectionOrder
  endif

  return s:VimTmuxOptionRunnerOrientation() == "v" ? ['down-of', 'right-of'] : ['right-of', 'down-of']
endfunction

function! s:VimTmuxOptionRunnerOrientation()
  return s:VimTmuxOption("g:VimTmuxRunnerOrientation", "v") == "h" ? "h" : "v"
endfunction

function! s:VimTmuxNewRunnerLastActivePane()
  let l:currentPaneId = s:VimTmuxGetIdForPane()
  call s:VimTmuxCommand("last-pane")
  let l:lastActivePaneId = s:VimTmuxGetIdForPane()
  call s:VimTmuxCommand("last-pane")

  if l:currentPaneId == l:lastActivePaneId
    call VimTmuxOpenRunner()
  else
    let g:VimTmuxRunnerId = l:lastActivePaneId
  endif
endfunction

function! s:VimTmuxOptionRunnerSize()
  return s:VimTmuxOption("g:VimTmuxRunnerSize", 20)
endfunction
