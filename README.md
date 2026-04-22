# tmux-whisper

`tmux-whisper` is a small tmux plugin that brings [`whisper.cpp`](https://github.com/ggml-org/whisper.cpp) voice transcription directly into a tmux workflow.

Common uses:

- Prompting LLMs by voice
- Writing down notes
- General voice-to-text inside tmux

The plugin looks for `whisper-cli` on the system, records with `sox`, and sends the transcript straight back to tmux.

## Install

With TPM:

```tmux
set -g @plugin 'martynasjocius/tmux-whisper'
run '~/.tmux/plugins/tpm/tpm'
```

Manual load:

```tmux
run-shell ~/.tmux/plugins/tmux-whisper/tmux-whisper.tmux
```

## Requirements

- `tmux`
- `whisper-cli` in `PATH`
- `sox` in `PATH`
- a Whisper model file

For sound cues, the plugin also expects one available audio player:

- `afplay` on macOS
- `paplay` or `aplay` on Linux

If no supported player is available, the plugin still works, but sound effects will be skipped.

## Usage

By default, the plugin binds `prefix + u` when `u` is free in the tmux `prefix` table.

The status segment shows one of four states:

- `whisper`
- `recording`
- `analyzing`
- `copied`

## Options

```tmux
set -g @tmux_whisper_key 'u'
set -g @tmux_whisper_icon '◉'
set -g @tmux_whisper_sound_enabled '1'
set -g @tmux_whisper_show_messages '0'
```

## Model Selection

If `@tmux_whisper_model` is unset, the plugin resolves the real `whisper-cli` path and then looks for models relative to it, preferring:

```text
../../models/ggml-medium.en.bin
```

From the `whisper-cli` binary directory, it falls back in this order:

- `../../models/ggml-medium.en.bin`
- `../../models/ggml-small.en.bin`
- `../../models/ggml-base.en.bin`

If you want a different model, set it explicitly in your `~/.tmux.conf`:

```tmux
set -g @tmux_whisper_model '/full/path/to/ggml-medium.en.bin'
```

Examples:

- `ggml-base.en.bin`: faster, lower accuracy
- `ggml-small.en.bin`: better English accuracy
- `ggml-medium.en.bin`: better accuracy again, but slower and heavier

After changing `~/.tmux.conf`, reload tmux:

```sh
tmux source-file ~/.tmux.conf
```

## Notes

- The plugin uses the same key to start and stop recording.
- The transcript is copied into the tmux buffer and sent to the pane where recording started.
- If the selected key is already bound in tmux, the plugin leaves it alone and does not override it.
- Routine popup messages are disabled by default; the status segment is the primary feedback.

## License

[MIT](./LICENSE)
