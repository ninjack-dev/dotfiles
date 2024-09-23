# Zinit can be installed with Nix, but since it's entirely shell-driven, we'll just install it to .local
# Install (if needed) and initialize zinit and its needed environment variables. 
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)" # If ZINIT_HOME folder isn't present, make it.
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" # If the git folderisn't present, clone the repo.  
source "${ZINIT_HOME}/zinit.zsh"

zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

# ZSH auto-completion parameters

source ~/.config/zsh/.zshrc-framework

HISTFILE=~/.config/zsh/.histfile
HISTSIZE=1000
SAVEHIST=$HISTSIZE
setopt appendhistory
setopt sharehistory 
setopt hist_ignore_space # prepend a space to prevent addition to history

stty -ctlecho # This disables the ^C echoing when killing an app

setopt autocd
unsetopt beep

# Keybindings
bindkey -e
bindkey '^H' backward-kill-word # Bind <C> + <BS> to delete word

bindkey ";5D" backward-word # Bind <C> + Left/Right to move 1 word
bindkey ";5C" forward-word

bindkey "^j" down-history # Bind <C> + j/k to scroll up/down through command history
bindkey "^k" up-history

bindkey '^p' history-search-backward 
bindkey '^n' history-search-forward 

zstyle ':completion:*' matcher-list 'm:{A-Za-z}={a-zA-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle :compinstall filename '/home/jacksonb/.zshrc' # I don't know what this does. It was put here automagically when I set up ZSH so I'll leave it be. 
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls--color $realpath'

autoload -Uz compinit && compinit

# Shell integrations and prompt
eval "$(zoxide init zsh --cmd cd)"
eval "$(fzf --zsh)"
eval "$(thefuck --alias)" 
if [ "$TERM" != "linux" ]; then
  eval "$(oh-my-posh init zsh)"
fi

# Aliases
alias ls='ls -A --color'
alias cb=$COPY_UTIL
alias cat='bat'
alias reload='exec zsh'
alias reboot='systemctl shutdown -r now'
# alias sudo='sudo ' # https://askubuntu.com/questions/22037/aliases-not-available-when-using-sudo


alias nvid='run_neovide_hyprland'

# alias logout

# Nice idea, doesn't work on nix-os. Might be worth looking for a nix-specific solution
xd()
{
cd $(dirname $(whereis hyprland | awk '{ print $2 }'))
}

getip()
{
ip route get 1 | awk '{print $7;exit}'
}
 
## NEOVIM ##
  
run_neovide_hyprland()
{
  # if hyprctl activewindow | grep "fullscreen: 1"; then
  #   if hyprctl activewindow | grep "fullscreenmode: 1"; then
  #     windowState="maximize"
  #   else
  #     windowState="fullscreen"
  #   fi
  # fi 
  # hyprctl dispatch exec -- "[${windowState}]" neovide "${pwd}/" -- "${@}" 
  # The problem with this approach is that, as far as I can see, there is no way to pass the working directory to neovide. Otherwise it works ok,
  # sans a small problem with focusing the window after fullscreen
  if hyprctl activewindow | grep "fullscreen: 1" > /dev/null; then
    if hyprctl activewindow | grep "fullscreenmode: 1" > /dev/null; then
      windowState=1
    else
      windowState=0
    fi
  fi 

  
  # TODO: Look into using the Hyprland socket instead of grepping from `hyprctl clients` 
  #  https://wiki.hyprland.org/IPC/
  run_neovide_de_agnostic $@ # Only way to set $!
  while ! hyprctl clients | grep $! >/dev/null; do done # Kill me
  hyprctl dispatch focuswindow pid:$! >/dev/null
  while ! hyprctl activewindow | grep $! >/dev/null; do done; # Please god kill me
  hyprctl dispatch fullscreen $windowState >/dev/null
  [[ -v $windowState ]]; hyprctl dispatch fullscreen $windowState >/dev/null
  return 0 # Previous command may fail, no need to set the error code

  # TODO: Substitute the following for `dispatch fullscreen` when Hyprland is updated to 0.43
  # hyprctl dispatch fullscreenstate 1

}

run_neovide_de_agnostic()
{
  neovide -- "$@" </dev/null >/dev/null 2>&1 &|
  # We redirect stdin to null so that the terminal doesn't hang when running exit.
    # TODO: It may be prudent to see if I can redirect STD out to the shell that launched it.
  # OR
  #  neovide --fork
  # This does not set $!, unlike the one above. 
}

# NeoVim Frontend SELector
nvfsel() {
  select frontend in Neovide Terminal
  do update_nvim_frontend_env_var $frontend; break;
  done;
  set_nvim_frontend_alias
}

set_nvim_frontend_alias()
{
  [[ $NVIM_FRONTEND = "term" ]] && unalias nvim &>/dev/null 
  [[ $NVIM_FRONTEND = "neovide" ]] && alias nvim='run_neovide_hyprland'
  return 0 # Nothing went wrong, I promise <3
}

update_nvim_frontend_env_var(){
  echo "$1 is now selected as default frontend."
  if [[ $1 = "Terminal" ]]; then
    sed -i "s/NVIM_FRONTEND=[^ ]*/NVIM_FRONTEND=term/" $ZDOTDIR/.zshenv
    echo "Note that Neovide can still be launched with the alias 'nvid'";
    NVIM_FRONTEND=term
  fi
  if [[ $1 = "Neovide" ]]; then 
    sed -i "s/NVIM_FRONTEND=[^ ]*/NVIM_FRONTEND=neovide/" $ZDOTDIR/.zshenv 
    NVIM_FRONTEND=neovide
  fi
}

nvsel() {
  select config in nvim nvchad 
  do update_nvim_config_env_var $config; break; 
  done;
}

update_nvim_config_env_var()
{
  echo "$1 is now selected as default config.";
  sed -i "s/NVIM_APPNAME=[^ ]*/NVIM_APPNAME=${1}/" $ZDOTDIR/.zshenv;
  source $ZDOTDIR/.zshenv;
}

if [ $TERM = "linux" ]; then
  NVIM_FRONTEND="term"
fi

set_nvim_frontend_alias
