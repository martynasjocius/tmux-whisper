#!/usr/bin/env bash

set -eu

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tmux_get() {
  tmux show-option -gqv "$1"
}

tmux_set() {
  tmux set-option -gq "$1" "$2"
}

set_default() {
  option_name="$1"
  default_value="$2"

  if [ -z "$(tmux_get "$option_name")" ]; then
    tmux_set "$option_name" "$default_value"
  fi
}

set_default @tmux_whisper_state "ready"
set_default @tmux_whisper_icon "◉"
set_default @tmux_whisper_key "u"
set_default @tmux_whisper_sound_enabled "1"
set_default @tmux_whisper_show_messages "0"
set_default @tmux_whisper_recording_pid ""
set_default @tmux_whisper_wav_path ""
set_default @tmux_whisper_target_pane ""
set_default @tmux_whisper_model ""
set_default @tmux_whisper_model_resolved ""
set_default @tmux_whisper_status_interval_saved ""

tmux_set @tmux_whisper_dir "$CURRENT_DIR"

status_right="$(tmux_get status-right)"
segment="#($CURRENT_DIR/scripts/render.sh)"

case "$status_right" in
  *"$segment"*)
    ;;
  *)
    tmux_set status-right "$segment $status_right"
    ;;
esac

bind_key="$(tmux_get @tmux_whisper_key)"

if [ -n "$bind_key" ] && ! tmux list-keys -T prefix "$bind_key" >/dev/null 2>&1; then
  tmux bind-key "$bind_key" run-shell "'$CURRENT_DIR/scripts/control.sh' toggle"
fi
