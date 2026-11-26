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

# FZF (ANSI-16 so dark/light kitty themes swap cleanly)
export FZF_DEFAULT_OPTS="--color=16,fg:-1,bg:-1,fg+:15:bold,bg+:8,hl:1,hl+:1:bold,info:8,marker:1,prompt:1,spinner:1,pointer:15,header:8,border:8,gutter:-1 --border=rounded --prompt='› ' --pointer='●' --marker='•'"
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
fi
