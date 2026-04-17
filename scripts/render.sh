#!/usr/bin/env bash

set -eu

tmux_get() {
  tmux show-option -gqv "$1"
}

escape_status_text() {
  printf '%s' "$1" | sed 's/#/##/g'
}

state="$(tmux_get @tmux_whisper_state)"
icon="$(tmux_get @tmux_whisper_icon)"

if [ -z "$state" ]; then
  state="ready"
fi

if [ -z "$icon" ]; then
  icon="◉"
fi

case "$state" in
  ready)
    color="colour183"
    label="whisper"
    ;;
  recording)
    color="colour203"
    label="recording"
    ;;
  analyzing)
    color="colour214"
    label="analyzing"
    ;;
  copied)
    color="colour70"
    label="copied"
    ;;
  *)
    color="colour183"
    label="whisper"
    ;;
esac

printf '#[fg=%s]%s#[default] #[fg=%s]%s#[default] ' "$color" "$(escape_status_text "$icon")" "$color" "$label"
