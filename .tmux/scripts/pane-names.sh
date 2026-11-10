#!/usr/bin/env bash
# Saves and restores the @name pane option around tmux-resurrect.
# Usage: pane-names.sh save | restore
set -euo pipefail

file="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/pane_names.txt"

case "${1:-}" in
    save)
        mkdir -p "$(dirname "$file")"
        tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}	#{@name}" \
            | awk -F '\t' '$2 != ""' > "$file"
        ;;
    restore)
        [ -f "$file" ] || exit 0
        while IFS=$'\t' read -r target name; do
            tmux set -p -t "$target" @name "$name" 2>/dev/null || true
        done < "$file"
        ;;
    *)
        echo "Usage: $0 save|restore" >&2
        exit 1
        ;;
esac
