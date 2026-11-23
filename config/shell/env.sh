# Shared environment (sourced by both .zshrc and .bashrc)

export USER="${USER:-$(id -un)}"
export HOME="${HOME:-$(getent passwd "$USER" 2>/dev/null | cut -d: -f6)}"
[ -z "$HOME" ] && export HOME="/home/$USER"
export PATH="$HOME/.local/bin:$HOME/.kilo/bin:$HOME/.gemini/antigravity-cli/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin"
export EDITOR="nvim"
export SUDO_EDITOR="nvim"
export VISUAL="nvim"

if command -v helium-browser >/dev/null 2>&1; then
  export BROWSER="helium-browser"
elif command -v zen-browser >/dev/null 2>&1; then
  export BROWSER="zen-browser"
fi

export BAT_THEME="ansi"
export MANROFFOPT="-c"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# FZF
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
fi
