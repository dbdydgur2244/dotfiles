# ~/.common: executed by the your shell (e.g. zsh, bash).
# This file include common environments or settings.

[ -f ~/.alias ] && source ~/.alias
[ -f ~/.forgit.plugin.zsh ] && source ~/.forgit.plugin.zsh



if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

# For autoenv
[ -f ~/.autoenv/activate.sh ] && source ~/.autoenv/activate.sh

# For ruby in local
[[ -d ~/.rbenv  ]] && eval "$(rbenv init -)"
