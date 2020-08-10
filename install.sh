#!/bin/bash

# Include config parameters from ./config.sh
# This variables are global
# 
# Example)
#   git_email:    "dbdydgur2244@gmail.com"
#   git_username: "dbdydgur2244"
#   public_key:   ".ssh/id_rsa.pub" // must be $HOME/.ssh

CONFIG_DIR="$HOME/.config"

if [[ -f "${CONFIG_DIR}/config.sh" ]]; then source "${CONFIG_DIR}/config.sh"; fi

# backup previous zsh configuration files
backup() {
  echo "backup .zsh directory and .zshrc .zpreztorc .tmux.conf" \
       ".alias .env if exists"
  if [[ -d ~/.zsh ]]; then mv ~/.zsh ~/.zsh_backup; fi
  if [[ -f ~/.zshrc ]]; then mv ~/.zshrc ~/.zshrc_backup; fi
  if [[ -f ~/.zpreztorc ]]; then mv "~/.zpreztorc" "~/.zpreztorc_backup"; fi
  if [[ -f ~/.tmux.conf ]]; then mv "~/.tmux.conf" "~/.tmux.conf_backup"; fi
  if [[ -f ~/.alias ]]; then mv "~/.alias" "~/.alias_backup"; fi
  if [[ -f ~/.env ]]; then mv "~/.env" "~/.env_backup"; fi
  if [[ -d ~/.vim ]]; then mv "~/.vim" "~/.vim_backup"; fi
  if [[ -f ~/.vimrc ]]; then mv "~/.vimrc" "~/.vimrc_backup"; fi
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
  # mkdir $HOME/.ssh 
  if [[ ! -d "$HOME/.ssh" ]]; then mkdir -p "$HOME/.ssh"; fi

  if [[ -f ~/.ssh/config ]]; then
    echo "backup the prezto profile to ~/.ssh/config to ~/.ssh/.config"
    mv ~/.ssh/config ~/.ssh/.config
  else
    if [[ -f "${CONFIG_DIR}/config" ]]; then ln -s "${CONFIG_DIR}/config"; fi
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
  [[ -z "${ZPREZTODIR}" ]] && echo $ZPREZTODIR & cd $ZPREZTODIR || \
      cd "${ZDOTDIR:-$HOME}/.zprezto"

  git clone --recurse-submodules https://github.com/belak/prezto-contrib contrib
}

install_prezto() {
  zsh
  git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"

  return 0
}

# Installation zsh package include prezto
install_zsh_packages() {
  # Install pure prompt
  if [[ -d "$HOME/.zsh" ]]; then mkdir -p "$HOME/.zsh"; fi
  install_prezto || (echo "install prezto failed. "; return 1)

  install_prezto_plugins
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
  
  [ ! -d ~/.vim ] && ln -sf $CONFIG_DIR/vim-settings ~/.vim
  [ ! -f ~/.vimrc ] && ln -s $CONFIG_DIR/vim-settings/vimrc ~/.vimrc
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
    install_tmux_packages
}


install_cargo() {
  curl https://sh.rustup.rs -sSf | sh -s -- -q -y
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
  xcode-select --install
  install_brew
  install_mac_package

  return 0
}


install_dotfiles() { 
  backup
  # link our profile
  cd $CONFIG_DIR
  ln -s zshrc ~/.zshrc
  ln -s zpreztorc ~/.zpreztorc
  ln -s tmux.conf ~/.tmux.conf
  ln -s alias ~/.alias
  ln -s env ~/.env
}


show_usage() {
  echo "Usage: install [COMMAND]
Commands:
  install   : install zsh and zsh configuration files in the home directory
  uninstall : uninstall zsh configuraiton files
  "
}


main() {
  cd ~/
  git clone --recursive https://github.com/dbdydgur2244/dotfiles $CONFIG_DIR
  cd $CONFIG_DIR

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

