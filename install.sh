#!/bin/bash

set -u


CONFIG_DIR="$HOME/.config"
zsh=1
vim=1
tmux=1
exa=1
fzf=1


show_usage() {
  cat << EOF
usage: $0 [OPTIONS]
    --help               Show this message
    --all                Install [(zshrc, zprezto), fzf, vim, exa, tmux.conf]

    --[no-]zsh           Whether install zshrc and zprezto
    --[no-]vim           Whether install vim configuration
    --[no-]tmux          Whether install tmux configuration
    --[no-]exa           Whether install exa and alias ls to exa
    --[no-]fzf           Whether install fzf and fzf configuration
EOF
}


for opt in "$@"; do
  case $opt in
    --help)
      show_usage
      exit 0
      ;;
    --all)
      zsh=1
      vim=1
      tmux=1
      exa=1
      fzf=1
      ;;
    --zsh) zsh=1;;
    --no-zsh) zsh=0;;
    --vim) vim=1;;
    --no-vim) vim=0;;
    --tmux) tmux=1;;
    --no-tmux) tmux=0;;
    --exa) exa=1;;
    --no-exa) exa=0;;
    --fzf) fzf=1;;
    --no-fzf) fzf=0;;
    *)
      echo "unknown option: $opt"
      help
      exit 1
      ;;
  esac
done


# Installation prezto which is the configuration for Zsh
install_prezto_plugins() {
  case ${ZPREZTODIR:-*} in
    --*) cd $ZPREZTODIR ;;
    *) cd "${ZDOTDIR:-$HOME}/.zprezto" ;;
  esac
  git clone --recurse-submodules https://github.com/belak/prezto-contrib contrib
}

install_prezto() {
  if [[ -f ~/.zpreztorc ]]; then mv ~/.zpreztorc ~/.zpreztorc_backup; fi
  if [[ -d ~/.zprezto ]]; then mv ~/.zprezto ~/.zprezto_backup; fi

  git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"

  install_prezto_plugins
  return 0
}

# Installation zsh package include prezto
install_zsh_packages() {
 
  if [[ ! -d ~/.zsh ]]; then 
    mkdir -p ~/.zsh
  else
    mv ~/.zsh ~/.zsh_backup
    if [[ -f ~/.zshrc ]]; then mv ~/.zshrc ~/.zshrc_backup; fi
  fi
  install_prezto || (echo "install prezto failed. "; return 1)

  ln -s ${CONFIG_DIR}/dotfiles/zshrc ~/.zshrc
  ln -s ${CONFIG_DIR}/dotfiles/zpreztorc ~/.zpreztorc

  return 0
}

install_fzf() {
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  $HOME/.fzf/install
  # fzf git plugin
  curl -Ss \
      https://raw.githubusercontent.com/wfxr/forgit/master/forgit.plugin.zsh \
      > ~/.forgit.plugin.zsh
}

install_vimrc() {
  if [[ $(command -v vim) == "" ]]; then
    echo "vim doesn't exist. please install vim"
    return 1
  fi

  if [[ -d ~/.vim ]]; then mv ~/.vim ~/.vim_backup; fi
  if [[ -f ~/.vimrc ]]; then mv ~/.vimrc ~/.vimrc_backup; fi
  
  ln -sf $CONFIG_DIR/dotfiles/vim-setting ~/.vim
  ln -s $CONFIG_DIR/dotfiles/vim-setting/vimrc ~/.vimrc

  vim -c ":PlugInstall" -c ":q" -c ":q"
}


install_tmux_packages() {
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  git clone https://github.com/erikw/tmux-powerline.git ~/.tmux/plugins

  ~/.tmux/plugins/tpm/scripts/install_plugins.sh
}


install_tmux_conf() {
  if [[ $(command -v tmux) == "" ]]; then 
    echo "tmux doesn't exist. please install tmux"
    return 1
  fi

  if [[ -f ~/.tmux.conf ]]; then mv ~/.tmux.conf ~/.tmux.conf_backup; fi
  ln -s ${CONFIG_DIR}/dotfiles/tmux.conf ~/.tmux.conf

  install_tmux_packages
}


install_cargo() {
  curl https://sh.rustup.rs -sSf | sh -s -- -q -y
  export PATH="$HOME/.cargo/bin:$PATH"
}


install_exa() {
  if [[ $(command -v cargo) == "" ]]; then install_cargo; fi
  cargo install exa || return 1
}


install_dotfiles() { 
  if [[ -f ~/.alias ]]; then mv ~/.alias ~/.alias_backup; fi
  if [[ -f ~/.env ]]; then mv ~/.env ~/.env_backup; fi
 
  ln -s ${CONFIG_DIR}/dotfiles/alias ~/.alias
  ln -s ${CONFIG_DIR}/dotfiles/env ~/.env
}




main() {
  git clone --recursive https://github.com/dbdydgur2244/dotfiles $CONFIG_DIR/dotfiles

  if [ $zsh -eq 1 ]; then
    if [[ $(command -v zsh) == "" ]]; then 
      echo "zsh doesn't exist. please install zsh"
      return 1
    fi
    install_zsh_packages || return 1
  fi 

  if [[ $fzf -eq 1 ]]; then install_fzf || return 1; fi
  if [[ $vim -eq 1 ]]; then install_vimrc || return 1; fi
  if [[ $tmux -eq 1 ]]; then install_tmux_conf || return 1; fi
  if [[ $exa -eq 1 ]]; then install_exa || return 1; fi
  install_dotfiles
  return 0
}

main || exit 1
exit 0
