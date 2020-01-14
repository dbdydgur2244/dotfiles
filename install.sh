#!/bin/bash

# 
# Include config parameters from ./config.sh
# This variables are global
# 
# example)
#   git_email:    "dbdydgur2244@gmail.com"
#   git_username: "dbdydgur2244"
#   public_key:   ".ssh/id_rsa.pub" // must be $HOME/.ssh
CONFIG_DIR="$(dirname $(realpath $0))"
if [[ ! -d "$CONFIG_DIR" ]]; then CONFIG_DIR="$PWD"; fi
. "${CONFIG_DIR}/config.sh"


# backup previous zsh configuration files
backup() {
  if [[ -d "$HOME/.zsh" ]]; then mv "$HOME/.zsh" "$HOME/.zsh_backup"; fi
  if [[ -f "$HOME/.zshrc" ]]; then mv "$HOME/.zshrc" "$HOME/.zshrc_backup"; fi
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
    ln -s "$ssh_config" "$local_ssh_config"

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
  source <(curl -Ss https://raw.githubusercontent.com/wfxr/forgit/master/forgit.plugin.zsh)
}

# Installation prezto which is the configuration for Zsh
install_prezto_plugins() {
  cd $ZPREZTODIR
  git clone --recurse-submodules https://github.com/belak/prezto-contrib contrib
  pwd
  cd $CONFIG_DIR
}

install_prezto() {
  # zsh
  git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
  # if zshrc doesn't exist than just touch file
  echo 'source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"' >> "$HOME/.zshrc"
  # if already prezto profile exists, then backup pre-exist profile 
  local local_prezto_profile="$HOME/.zpreztorc"
    
  mv "$local_prezto_profile" "${local_prezto_profile}_bac"
  # if [[ -e "${local_prezto_profile}" ]]; then
    # echo "backup the prezto profile to ~/.zpreztorc_bac"
    # mv "$local_prezto_profile" "${local_prezto_profile}_bac"
  # fi
  # link our profile
  local prezto_profile="${CONFIG_DIR}/zpreztorc"
  ln -s "$prezto_profile" "$local_prezto_profile"

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


show_usage() {
  echo "Usage: install [COMMAND]
Commands:
  install   : install zsh and zsh configuration files in the home directory
  uninstall : uninstall zsh configuraiton files
  "
}


main() {
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
      return 1
      ;;
  esac

  chsh -s `which zsh`
  install_zsh_packages
  install_fzf
  return 0
}

main || exit 1
exit 0

