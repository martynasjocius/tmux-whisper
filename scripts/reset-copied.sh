#!/usr/bin/env bash

set -eu

tmux_get() {
  tmux show-option -gqv "$1"
}

tmux_set() {
  tmux set-option -gq "$1" "$2"
}

refresh_status() {
  tmux refresh-client -S >/dev/null 2>&1 || true
}

sleep 2

if [ "$(tmux_get @tmux_whisper_state)" = "copied" ]; then
  tmux_set @tmux_whisper_state "ready"
  refresh_status
fi
