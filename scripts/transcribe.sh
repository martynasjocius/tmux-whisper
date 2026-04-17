#!/usr/bin/env bash

set -eu

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"

wav_path="${1:-}"
target_pane="${2:-}"
model_path="${3:-}"

tmux_get() {
  tmux show-option -gqv "$1"
}

tmux_set() {
  tmux set-option -gq "$1" "$2"
}

notify() {
  if [ "$(tmux_get @tmux_whisper_show_messages)" = "1" ]; then
    tmux display-message "whisper: $1"
  fi
}

notify_error() {
  tmux display-message "whisper: $1"
}

refresh_status() {
  tmux refresh-client -S >/dev/null 2>&1 || true
}

restore_refresh() {
  saved_interval="$(tmux_get @tmux_whisper_status_interval_saved)"
  if [ -n "$saved_interval" ]; then
    tmux set-option -gq status-interval "$saved_interval"
    tmux_set @tmux_whisper_status_interval_saved ""
  fi
}

cleanup() {
  if [ -n "$wav_path" ] && [ -f "$wav_path" ]; then
    rm -f "$wav_path"
  fi
}

finish_with_error() {
  cleanup
  tmux_set @tmux_whisper_state "ready"
  tmux_set @tmux_whisper_wav_path ""
  tmux_set @tmux_whisper_target_pane ""
  restore_refresh
  refresh_status
  notify_error "$1"
  exit 1
}

if [ -z "$wav_path" ] || [ ! -f "$wav_path" ]; then
  finish_with_error "recording file missing"
fi

if [ -z "$model_path" ] || [ ! -f "$model_path" ]; then
  finish_with_error "model file missing"
fi

if ! command -v whisper-cli >/dev/null 2>&1; then
  finish_with_error "whisper-cli not found"
fi

text="$(
  whisper-cli -m "$model_path" -f "$wav_path" -nt -np 2>/dev/null |
    tr '\n' ' ' |
    sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//'
)"

cleanup
tmux_set @tmux_whisper_wav_path ""
tmux_set @tmux_whisper_target_pane ""

if [ -z "$text" ]; then
  tmux_set @tmux_whisper_state "ready"
  restore_refresh
  refresh_status
  notify "no speech detected"
  exit 0
fi

printf '%s' "$text" | tmux load-buffer -

if [ -n "$target_pane" ] && tmux list-panes -a -F '#{pane_id}' | grep -Fxq "$target_pane"; then
  tmux send-keys -t "$target_pane" -l -- "$text"
else
  tmux send-keys -l -- "$text"
fi

tmux_set @tmux_whisper_state "copied"
restore_refresh
refresh_status
notify "copied"
"$project_dir/scripts/reset-copied.sh" >/dev/null 2>&1 &
