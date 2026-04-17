#!/usr/bin/env bash

set -eu

sound_name="${1:-}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"

tmux_get() {
  tmux show-option -gqv "$1"
}

if [ "$(tmux_get @tmux_whisper_sound_enabled)" = "0" ]; then
  exit 0
fi

case "$sound_name" in
  start)
    sound_file="$project_dir/assets/sounds/recording-start.wav"
    ;;
  stop)
    sound_file="$project_dir/assets/sounds/recording-stop.wav"
    ;;
  *)
    exit 1
    ;;
esac

if [ ! -f "$sound_file" ]; then
  exit 0
fi

if command -v afplay >/dev/null 2>&1; then
  afplay "$sound_file" >/dev/null 2>&1 &
elif command -v paplay >/dev/null 2>&1; then
  paplay "$sound_file" >/dev/null 2>&1 &
elif command -v aplay >/dev/null 2>&1; then
  aplay "$sound_file" >/dev/null 2>&1 &
fi
