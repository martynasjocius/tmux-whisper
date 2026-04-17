#!/usr/bin/env bash

set -eu

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"

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

play_sound() {
  sound_name="$1"
  "$project_dir/scripts/play-sound.sh" "$sound_name" >/dev/null 2>&1 &
}

activate_refresh() {
  saved_interval="$(tmux_get @tmux_whisper_status_interval_saved)"
  if [ -z "$saved_interval" ]; then
    tmux_set @tmux_whisper_status_interval_saved "$(tmux_get status-interval)"
  fi
  tmux set-option -gq status-interval 1
}

restore_refresh() {
  saved_interval="$(tmux_get @tmux_whisper_status_interval_saved)"
  if [ -n "$saved_interval" ]; then
    tmux set-option -gq status-interval "$saved_interval"
    tmux_set @tmux_whisper_status_interval_saved ""
  fi
}

reset_state() {
  tmux_set @tmux_whisper_state "ready"
  tmux_set @tmux_whisper_recording_pid ""
  tmux_set @tmux_whisper_wav_path ""
  tmux_set @tmux_whisper_target_pane ""
}

fail() {
  reset_state
  restore_refresh
  refresh_status
  notify_error "$1"
  exit 1
}

find_model() {
  configured_model="$(tmux_get @tmux_whisper_model)"
  if [ -n "$configured_model" ] && [ -f "$configured_model" ]; then
    printf '%s\n' "$configured_model"
    return 0
  fi

  for candidate in \
    "$HOME/Software/whisper.cpp/models/ggml-base.en.bin" \
    "$HOME/.local/share/whisper.cpp/models/ggml-base.en.bin" \
    "/opt/homebrew/share/whisper.cpp/models/ggml-base.en.bin" \
    "/usr/local/share/whisper.cpp/models/ggml-base.en.bin" \
    "/usr/share/whisper.cpp/models/ggml-base.en.bin"
  do
    if [ -f "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

start_recording() {
  if ! command -v sox >/dev/null 2>&1; then
    fail "sox not found"
  fi

  if ! command -v whisper-cli >/dev/null 2>&1; then
    fail "whisper-cli not found"
  fi

  if ! model_path="$(find_model)"; then
    fail "set @tmux_whisper_model to a Whisper model file"
  fi

  wav_path="$(mktemp "${TMPDIR:-/tmp}/tmux-whisper.XXXXXX.wav")"
  target_pane="$(tmux display-message -p '#{pane_id}')"

  sox -q -d -r 16000 -c 1 -b 16 "$wav_path" >/dev/null 2>&1 &
  sox_pid=$!

  tmux_set @tmux_whisper_model_resolved "$model_path"
  tmux_set @tmux_whisper_wav_path "$wav_path"
  tmux_set @tmux_whisper_target_pane "$target_pane"
  tmux_set @tmux_whisper_recording_pid "$sox_pid"
  tmux_set @tmux_whisper_state "recording"
  activate_refresh
  play_sound start
  refresh_status
  notify "recording"
}

stop_recording() {
  sox_pid="$(tmux_get @tmux_whisper_recording_pid)"
  wav_path="$(tmux_get @tmux_whisper_wav_path)"
  target_pane="$(tmux_get @tmux_whisper_target_pane)"
  model_path="$(tmux_get @tmux_whisper_model_resolved)"

  if [ -z "$sox_pid" ] || [ -z "$wav_path" ]; then
    fail "no active recording"
  fi

  kill -INT "$sox_pid" >/dev/null 2>&1 || true

  attempt=0
  while kill -0 "$sox_pid" >/dev/null 2>&1; do
    sleep 0.1
    attempt=$((attempt + 1))
    if [ "$attempt" -ge 100 ]; then
      kill -TERM "$sox_pid" >/dev/null 2>&1 || true
      break
    fi
  done

  tmux_set @tmux_whisper_recording_pid ""
  tmux_set @tmux_whisper_state "analyzing"
  play_sound stop
  refresh_status

  "$project_dir/scripts/transcribe.sh" "$wav_path" "$target_pane" "$model_path" >/dev/null 2>&1 &
  notify "analyzing"
}

toggle() {
  state="$(tmux_get @tmux_whisper_state)"
  case "$state" in
    ""|ready|copied)
      start_recording
      ;;
    recording)
      stop_recording
      ;;
    analyzing)
      notify "still analyzing"
      ;;
    *)
      reset_state
      restore_refresh
      start_recording
      ;;
  esac
}

case "${1:-toggle}" in
  toggle)
    toggle
    ;;
  *)
    notify_error "unknown command"
    exit 1
    ;;
esac
