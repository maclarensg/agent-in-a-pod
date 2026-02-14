#!/usr/bin/env bash
set -e

# ── Git config (from env vars if provided) ───────────────────────
if [ -n "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
fi
if [ -n "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
fi

# ── SSH agent (load keys if present) ─────────────────────────────
if [ -d "$HOME/.ssh" ] && ls "$HOME/.ssh/id_"* 1>/dev/null 2>&1; then
    eval "$(ssh-agent -s)" >/dev/null 2>&1
    for key in "$HOME/.ssh/id_"*; do
        case "$key" in
            *.pub) continue ;;
            *)     ssh-add "$key" 2>/dev/null || true ;;
        esac
    done
    echo "SSH agent: $(ssh-add -l 2>/dev/null | wc -l) key(s) loaded"
fi

# ── SSH known hosts ──────────────────────────────────────────────
if [ ! -f "$HOME/.ssh/known_hosts" ]; then
    ssh-keyscan -t ed25519,rsa github.com gitlab.com bitbucket.org \
        >> "$HOME/.ssh/known_hosts" 2>/dev/null || true
fi

# ── Claude status ────────────────────────────────────────────────
if command -v claude >/dev/null 2>&1; then
    echo "Claude Code: $(claude --version 2>/dev/null || echo 'installed')"
else
    echo "Warning: claude command not found"
fi

echo "──────────────────────────────────────"
echo " Lilith container ready"
echo " Python: $(python --version 2>&1)"
echo " Node:   $(node --version 2>&1)"
echo " tmux:   $(tmux -V 2>&1)"
echo " ttyd:   $(ttyd --version 2>&1)"
echo "──────────────────────────────────────"

exec "$@"
