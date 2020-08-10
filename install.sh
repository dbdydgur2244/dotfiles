#!/bin/bash

CURRENT_DIR=`pwd -P`

# 
# Include config parameters from ./config.sh
# This variables are global
# 
# Example)
#   git_email:    "dbdydgur2244@gmail.com"
#   git_username: "dbdydgur2244"
#   public_key:   ".ssh/id_rsa.pub" // must be $HOME/.ssh
CONFIG_DIR="$(dirname $(realpath $0))"
if [[ ! -d "$CONFIG_DIR" ]]; then CONFIG_DIR="$PWD"; fi

[ -f "${CONFIG_DIR}/config.sh" ] && source "${CONFIG_DIR}/config.sh"

# backup previous zsh configuration files
backup() {
  if [[ -d "$HOME/.zsh" ]]; then mv "$HOME/.zsh" "$HOME/.zsh_backup"; fi
  if [[ -f "$HOME/.zshrc" ]]; then mv "$HOME/.zshrc" "$HOME/.zshrc_backup"; fi
  if [[ -f ~/.zpreztorc ]]; then mv "~/.zpreztorc" "~/.zpreztorc_backup"; fi
  if [[ -f ~/.tmux.conf ]]; then mv "~/.tmux.conf" "~/.tmux.conf_backup"; fi
  if [[ -f ~/.alias ]]; then mv "~/.alias" "~/.alias_backup"; fi
  if [[ -f ~/.env ]]; then mv "~/.env" "~/.env_backup"; fi
}


find_os() {
  local uname_out="$(uname -s)"
  local machine
  case "${uname_out}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    *)          machine="UNKNOWN:${uname_out}"
  esac
  echo "$machine"
}


ssh_config() {
  local local_ssh_config="$HOME/.ssh/config"
  local ssh_config="${CONFIG_DIR}/config"
  # mkdir $HOME/.ssh 
  if [[ ! -d "$HOME/.ssh" ]]; then mkdir -p "$HOME/.ssh"; fi

  if [[ -f "$local_ssh_config" ]]; then
    echo "backup the prezto profile to ~/.ssh/config to ~/.ssh/config_bac"
    mv "$local_ssh_config" "${local_ssh_config}_bac"
    # { seq 1 9; cat "${CONFIG_DIR}/config" } > "$local_ssh_config"
  else
    [ -f "$local_ssh_config" ] && ln -s "$ssh_config" "$local_ssh_config"
  fi
  chmod 440 "$local_ssh_config"
}


git_config() {
  git config --global user.name "$git_username"
  git config --global user.email "$git_email"
}


install_fzf() {
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  $HOME/.fzf/install
  # fzf git plugin
  curl -Ss \
      https://raw.githubusercontent.com/wfxr/forgit/master/forgit.plugin.zsh \
      > ~/.forgit.plugin.zsh
}

# Installation prezto which is the configuration for Zsh
install_prezto_plugins() {
  cd $ZPREZTODIR
  git clone --recurse-submodules https://github.com/belak/prezto-contrib contrib
  pwd
  cd $CONFIG_DIR
}

install_prezto() {
  zsh
  git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
  # if zshrc doesn't exist than just touch file

  return 0
}

# Installation zsh package include prezto
install_zsh_packages() {
  # Install pure prompt
  if [[ -d "$HOME/.zsh" ]]; then mkdir -p "$HOME/.zsh"; fi
  install_prezto || (echo "install prezto failed. "; return 1)
  # install_prezto_plugins
  return 0
}


# installation zsh in ubuntu
ubuntu_install_zsh() {
    if [[ $(command -v zsh) == "" ]]; then
        sudo apt install zsh
    fi
    return 0
}

linux_install_zsh() {
  backup
  
  case "`/usr/bin/lsb_release -si`" in
    Ubuntu)
      ubuntu_install_zsh || return 1
      ;;
    *)
      echo "In current, only support Ubuntu" 
      return 1
      ;;
  esac
  return 0
}


install_brew() {
  if [[ $(command -v brew) == "" ]]; then
    echo "Cannot find brew" >&2
    echo "Installing Homebrew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
}


install_vimrc() {
  if [[ $(command -v vim) == "" ]]; then return 1; fi
  [ ! -f ~/.vimrc ] && \
    ln -s $CURRENT_DIR/vim-settings/vimrc ~/.vimrc && \
    vim -c ":PlugInstall" -c ":q" -c ":q"
}


install_tmux_packages() {
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  git clone https://github.com/erikw/tmux-powerline.git ~/.tmux/plugins

  ~/.tmux/plugins/tpm/scripts/install_plugins.sh
}


install_tmux_conf() {
  if [[ $(command -v tmux) == "" ]]; then return 0; fi

  [ ! -f ~/.tmux.conf ] && \
    ln -s $CURRENT_DIR/tmux.conf ~/.tmux.conf && \
    install_tmux_packages
}


install_cargo() {
  curl https://sh.rustup.rs -sSf | sh
  export PATH="$HOME/.cargo/bin:$PATH"
}


install_exa() {
  if [[ $(command -v cargo) == "" ]]; then install_cargo; fi
  cargo install exa
}


install_mac_package() {
  brew install git git-lfs
}


mac_install_zsh() {
  backup

  xcode-select --install
  install_brew
  install_mac_package

  return 0
}


install_dotfiles() { 

  # if already prezto profile exists, then backup pre-exist profile 
  mv "$local_prezto_profile" "${local_prezto_profile}_bac"
  if [[ -f ~/.zpreztorc ]]; then
    echo "backup the prezto profile to ~/.zpreztorc_bac"
    mv "~/.zpreztorc" "~/.zpreztorc_bac"
  fi
  # link our profile
  ln -s "$CURRENT_DIR/zpreztorc" ~/.zpreztorc
}


show_usage() {
  echo "Usage: install [COMMAND]
Commands:
  install   : install zsh and zsh configuration files in the home directory
  uninstall : uninstall zsh configuraiton files
  "
}


main() {
  git clone --recursive https://github.com/dbdydgur2244/dot-files
  cd dot-files

  local machine=$(find_os)
  echo $machine
  case $machine in
    Linux)
      linux_install_zsh || (echo "[!] install failed. "; return 1)
      ;;
    Mac)
      mac_install_zsh  || (echo "[!] install failed. "; return 1)
      ;;
    *)
      show_usage
      return 
      ;;
  esac

  # chsh -s `which zsh`
  install_dotfiles

  install_zsh_packages
  install_fzf
  install_vimrc
  install_tmux_conf
  install_exa

  return 0
}

main || exit 1
exit 0

