#!/usr/bin/env bash
# Default session layout: 3 windows, each with a full-height left pane
# and the right half split top/bottom. Called from the after-new-session hook.
s="$1"

for w in 1 2 3; do
  [ "$w" -gt 1 ] && tmux new-window -t "$s:$w" -c ~
  tmux split-window -h -t "$s:$w" -l 50% -c ~
  tmux split-window -v -t "$s:$w.2" -l 50% -c ~
  tmux select-pane -t "$s:$w.1"
done

tmux select-window -t "$s:1"
