if exists("g:loaded_tmuxrunner")
  finish
endif

let g:loaded_tmuxrunner = 1

command -nargs=* TmuxRunnerRunCommand :call TmuxRunnerRunCommand(<args>)
command -nargs=? TmuxRunnerPromptCommand :call TmuxRunnerPromptCommand(<args>)
command TmuxRunnerRunLastCommand :call TmuxRunnerRunLastCommand()
command TmuxRunnerEditCommand :call TmuxRunnerEditCommand()
command -nargs=? TmuxRunnerSetRunner :call TmuxRunnerSetRunner(<args>)
command -nargs=? TmuxRunnerPromptRunner :call TmuxRunnerPromptRunner(<args>)
command TmuxRunnerOpen :call TmuxRunnerOpen()
command TmuxRunnerClose :call TmuxRunnerClose()
command TmuxRunnerStop :call TmuxRunnerStop()
command TmuxRunnerZoom :call TmuxRunnerZoom()
command TmuxRunnerClear :call TmuxRunnerClear()
command TmuxRunnerInspect :call TmuxRunnerInspect()
command TmuxRunnerScrollUp :call TmuxRunnerScrollUp()
command TmuxRunnerScrollDown :call TmuxRunnerScrollDown()

function! TmuxRunnerRunCommand(command, ...)
  if s:TmuxRunnerDoesPaneExist() == 0
    if s:TmuxRunnerStartRunner() == 0
      return
    endif
  endif

  let g:TmuxRunnerLastCommand = a:command

  call TmuxRunnerSendKeys("q C-u")
  call TmuxRunnerSendText(a:command)
  call TmuxRunnerSendKeys("Enter")
endfunction

function! TmuxRunnerPromptCommand(...)
  let defaultCommand = exists("a:1") ? a:1 : ""
  let l:command = input("Command: ", defaultCommand, 'shellcmd')
  if l:command != ""
    call TmuxRunnerRunCommand(l:command)
  endif
endfunction

function! TmuxRunnerRunLastCommand()
  if exists("g:TmuxRunnerLastCommand")
    call TmuxRunnerRunCommand(g:TmuxRunnerLastCommand)
  else
    echo "No command to run"
  endif
endfunction

function! TmuxRunnerEditCommand()
  if exists("g:TmuxRunnerLastCommand")
    call TmuxRunnerPromptCommand(g:TmuxRunnerLastCommand)
  else
    call TmuxRunnerPromptCommand()
  endif
endfunction

function! TmuxRunnerPromptRunner(...)
  let l:runner = input("Set new runner: ")
  if l:runner != ""
    call TmuxRunnerSetRunner(l:runner)
  endif
endfunction

function! TmuxRunnerSetRunner(...)
  if exists("a:1")
    let l:newRunner = s:TmuxRunnerGetIdForPane(string(a:1))
    if v:shell_error == 0
      let g:TmuxRunnerId = l:newRunner
    else
      echo "Runner error: ".g:TmuxRunnerId
    endif
  endif
endfunction

function! TmuxRunnerSendText(text)
  call TmuxRunnerSendKeys('"'.escape(a:text, '\"$`').'"')
endfunction

function! TmuxRunnerSendKeys(keys)
  call s:TmuxRunnerCommand("send-keys -t '".g:TmuxRunnerId."' ".a:keys)
endfunction

function! s:TmuxRunnerCommand(arguments)
  return system(s:TmuxRunnerOptionTmuxCommand()." ".a:arguments)
endfunction

function! s:TmuxRunnerOption(option, default)
  return exists(a:option) ? eval(a:option) : a:default
endfunction

function! s:TmuxRunnerGetIdForPane(...)
  let l:target = exists("a:1") ? " -t '".a:1. "'" : ""

  return substitute(s:TmuxRunnerCommand('display -p '.l:target.' "#{session_id}:#{window_id}.#{pane_id}"'), '\n$', '', '')
endfunction

function! s:TmuxRunnerDoesPaneExist()
  if !exists("g:TmuxRunnerId") || g:TmuxRunnerId == ""
    return 0
  endif

  call s:TmuxRunnerCommand("has -t '".g:TmuxRunnerId."'")

  return v:shell_error == 0
endfunction

function! TmuxRunnerOpen()
  let l:orientation = s:TmuxRunnerOptionRunnerOrientation()
  let l:size = s:TmuxRunnerOptionRunnerSize()

  call s:TmuxRunnerCommand("split-window -p ".l:size." -".l:orientation)
  let g:TmuxRunnerId = s:TmuxRunnerGetIdForPane()
  call s:TmuxRunnerCommand("last-pane")
endfunction

function! TmuxRunnerClose()
  if s:TmuxRunnerDoesPaneExist() == 1
    call s:TmuxRunnerCommand("kill-pane -t '".g:TmuxRunnerId."'")
    unlet g:TmuxRunnerId
  endif
endfunction

function! TmuxRunnerStop()
  call TmuxRunnerSendKeys("^c")
endfunction

function! TmuxRunnerZoom()
  if s:TmuxRunnerDoesPaneExist() == 1
    call s:TmuxRunnerCommand("resize-pane -Z -t '".g:TmuxRunnerId."'")
  endif
endfunction

function! TmuxRunnerClear()
  if s:TmuxRunnerDoesPaneExist() == 1
    call TmuxRunnerSendText("clear")
    call TmuxRunnerSendKeys("Enter")
    call s:TmuxRunnerCommand("clear-history -t '".g:TmuxRunnerId."'")
  endif
endfunction

function! TmuxRunnerInspect()
  if s:TmuxRunnerDoesPaneExist() == 1
    call s:TmuxRunnerCommand("select-pane -t '".g:TmuxRunnerId."'")
    call s:TmuxRunnerCommand("copy-mode")
  endif
endfunction

function! TmuxRunnerScrollUp()
  if s:TmuxRunnerDoesPaneExist() == 1
    call TmuxRunnerInspect()
    call TmuxRunnerSendKeys("C-u")
    call s:TmuxRunnerCommand("last-pane")
  endif
endfunction

function! TmuxRunnerScrollDown()
  if s:TmuxRunnerDoesPaneExist() == 1
    call TmuxRunnerInspect()
    call TmuxRunnerSendKeys("C-d")
    call s:TmuxRunnerCommand("last-pane")
  endif
endfunction

function! s:TmuxRunnerStartRunner()
  let l:runnerMode = exists("g:TmuxRunnerNewRunnerMode") ? g:TmuxRunnerNewRunnerMode : "new"

  if l:runnerMode == 'new'
    call TmuxRunnerOpen()
    return 1
  elseif l:runnerMode == 'nearest'
    call s:TmuxRunnerNewRunnerWithNearestPane()
    return 1
  elseif l:runnerMode == 'last'
    call s:TmuxRunnerNewRunnerLastActivePane()
    return 1
  else
    redraw
    echo 'Runner not defined'
    return 0
  endif
endfunction

function! s:TmuxRunnerNewRunnerWithNearestPane()
  let l:nearestDirectionOrder = s:TmuxRunnerNearestSelectionOrder()

  for direction in l:nearestDirectionOrder
    call s:TmuxRunnerCommand('select-pane -t {'.direction.'}')
    if v:shell_error == 0
      let g:TmuxRunnerId = s:TmuxRunnerGetIdForPane()
      call s:TmuxRunnerCommand("last-pane")
      return
    endif
  endfor

  call TmuxRunnerOpen()
endfunction

function! s:TmuxRunnerNearestSelectionOrder()
  if exists('g:TmuxRunnerNearestSelectionOrder')
    return g:TmuxRunnerNearestSelectionOrder
  endif

  return s:TmuxRunnerOptionRunnerOrientation() == "v" ? ['down-of', 'right-of'] : ['right-of', 'down-of']
endfunction

function! s:TmuxRunnerOptionRunnerOrientation()
  return s:TmuxRunnerOption("g:TmuxRunnerOrientation", "v") == "h" ? "h" : "v"
endfunction

function! s:TmuxRunnerNewRunnerLastActivePane()
  let l:currentPaneId = s:TmuxRunnerGetIdForPane()
  call s:TmuxRunnerCommand("last-pane")
  let l:lastActivePaneId = s:TmuxRunnerGetIdForPane()
  call s:TmuxRunnerCommand("last-pane")

  if l:currentPaneId == l:lastActivePaneId
    call TmuxRunnerOpen()
  else
    let g:TmuxRunnerId = l:lastActivePaneId
  endif
endfunction

function! s:TmuxRunnerOptionRunnerSize()
  return s:TmuxRunnerOption("g:TmuxRunnerSize", 20)
endfunction

function! s:TmuxRunnerOptionTmuxCommand()
  return s:TmuxRunnerOption("g:TmuxRunnerExecutable", "tmux")
endfunction
