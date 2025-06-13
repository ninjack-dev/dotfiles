# I want to see if this can be put elsewhere
#if uwsm check may-start; then
#exec uwsm start hyprland-uwsm.desktop
#fi
# alias Hyprland='exec uwsm start hyprland-uwsm.desktop'

# Benchmark logic
# zmodload zsh/datetime
# setopt PROMPT_SUBST
# PS4='+$EPOCHREALTIME %N:%i> '
#
# logfile=$(mktemp zsh_profile.XXXXXXXX)
# echo "Logging to $logfile"
# exec 3>&2 2>$logfile
# setopt XTRACE
# End benchmark logic

# Official benchmark tool
# zmodload zsh/zprof

# Zinit can be installed with Nix, but since it's entirely shell-driven, we'll just install it to .local for usage with other operating systems.
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

bindkey "^[[1;5D" backward-word # Bind <C> + Left/Right to move 1 word
bindkey "^[[1;5C" forward-word

bindkey "^j" down-history # Bind <C> + j/k to scroll up/down through command history
bindkey "^k" up-history

bindkey '^p' history-search-backward 
bindkey '^n' history-search-forward 

zle -N nvim_neovide_handler
bindkey '^N' nvim_neovide_handler

zstyle ':completion:*' matcher-list 'm:{A-Za-z}={a-zA-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle :compinstall filename '/home/jacksonb/.zshrc' # I don't know what this does. It was put here automagically when I set up ZSH so I'll leave it be. 
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

# https://gist.github.com/ctechols/ca1035271ad134841284#gistcomment-2308206
# autoload -Uz compinit
# compinit -Cu
#
#https://gist.github.com/ctechols/ca1035271ad134841284?permalink_comment_id=5224370#gistcomment-5224370
() {
  setopt local_options
  local zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
  local zcomp_ttl=1  # how many days to let the zcompdump file live before it must be recompiled
  local lock_timeout=1  # register an error if lock-timeout exceeded
  local lockfile="${zcompdump}.lock"
  autoload -Uz compinit
  # check for lockfile — if the lockfile exists, we cannot run a compinit
  #   if no lockfile, then we will create one, and set a trap on EXIT to remove it;
  #   the trap will trigger after the rest of the function has run.
  if [ -f "${lockfile}" ]
  then 
    # error log if the lockfile outlived its timeout
    if [ "$( find "${lockfile}" -mmin $lock_timeout )" ]
    then
      (
        echo "${lockfile} has been held by $(< ${lockfile}) for longer than ${lock_timeout} minute(s)."
        echo "This may indicate a problem with compinit"
      ) >&2
    fi
    # since the zcompdump is still locked, run compinit without generating a new dump
    compinit -D -d "$zcompdump"
    # Exit if there's a lockfile; another process is handling things
    return 1
  else
    # Create the lockfile with this shell's PID for debugging
    echo $$ > "${lockfile}"
    # Ensure the lockfile is removed on exit
    trap "rm -f '${lockfile}'" EXIT
  fi

  # refresh the zcompdump file if needed
  if [ ! -f "$zcompdump" -o "$( find "$zcompdump" -mtime "+${zcomp_ttl}" )" ]
  then
    # if the zcompdump is expired (past its ttl) or absent, we rebuild it
    compinit -d "$zcompdump"
  else
    # load the zcompdump without updating
    compinit -CD -d "$zcompdump"
    # asynchronously rebuild the zcompdump file
    (autoload -Uz compinit; compinit -d "$zcompdump" &);
  fi
}

## Shell integrations and prompt ##
eval "$(zoxide init zsh --cmd cd)"
function cd() {
  if [[ $# -gt 1 || $# -eq 0 ]]; then
    __zoxide_z "$@"
    return
  fi
  # redundant? 
  if [ -d "$1" ]; then
    __zoxide_z "$1"
    return
  fi

  local dir=$(find $(dirname $1) -maxdepth 1 -type d,l -wholename "*$(basename $1)*")
  if [ -d "$dir" ]; then
    __zoxide_z "./$dir"
  else
    __zoxide_z "$@"
  fi
}

eval "$(fzf --zsh)"

# Custom FZF cd widget to use zoxide
fzf-cd-widget() {
  setopt localoptions pipefail no_aliases 2> /dev/null
  local dir="$(
    FZF_DEFAULT_COMMAND=${FZF_ALT_C_COMMAND:-} \
    FZF_DEFAULT_OPTS=$(__fzf_defaults "--reverse --walker=dir,follow,hidden --scheme=path" "${FZF_ALT_C_OPTS-} +m") \
    FZF_DEFAULT_OPTS_FILE='' $(__fzfcmd) < /dev/tty)"
  if [[ -z "$dir" ]]; then
    zle redisplay
    return 0
  fi
  zle push-line # Clear buffer. Auto-restored on next prompt.
  BUFFER="cd -- ${(q)dir:a}"
  zle accept-line
  local ret=$?
  unset dir # ensure this doesn't end up appearing in prompt expansion
  zle reset-prompt
  return $ret
}

# Custom FZF file widget to expand paths currently being edited.
# TODO: 
# - Update Regex to allow for escaped spaces
# - Allow for path in quotes (need to pull path out of quotes)
fzf-file-widget() {
  #WIP
  # Extract token under cursor, handling escaped spaces
  # local left="$LBUFFER"
  # local right="$RBUFFER"
  # local token_left token_right token
  #
  # if [[ $left =~ '(([^[:space:]\\]|\\.)*)$' ]]; then
  #   token_left="${match[1]}"
  # else
  #   token_left=""
  # fi
  # if [[ $right =~ '^(([^[:space:]\\]|\\.)*)' ]]; then
  #   token_right="${match[1]}"
  # else
  #   token_right=""
  # fi
  # token="${token_left}${token_right}"

  # Regex match on left-of-cursor buffer; captures preceeding non-whitespace.
  local token="${LBUFFER##*[[:space:]]}"
  # Regex match on right-of-cursor buffer; captures leading non-whitespace.
  [[ "$RBUFFER" =~ '^([^[:space:]]*)' ]] && token+="${match[1]}"
  # [[ "$RBUFFER" =~ '^(([^[:space:]\\]|\\.)*)' ]] && token+="${match[1]}"

  # token="${words[$CURRENT]}" 

  local original_token=$token
  local expanded_token=${~token} # Expands ~ and variables

  local parent base

  # If token is empty, fallback to default behavior
  if [[ -z "$expanded_token" ]]; then
    LBUFFER="${LBUFFER}$(__fzf_select)"
    zle reset-prompt
    return $?
  fi

  parent=${expanded_token:h} # Head of path in token, e.g. /foo/bar -> /foo/
  base=${expanded_token:t} # Tail of path in token, e.g. /foo/bar -> bar

  if [[ -d "$expanded_token" ]]; then
    # If token is a directory, start search there
    new_path=$(__fzf_select --walker-root "$expanded_token")
    if [[ -n "$new_path" ]]; then
      LBUFFER="${LBUFFER/$original_token/$new_path}"
    fi
  elif [[ -f "$expanded_token" ]]; then
    # If it's a valid file, do nothing
    :
  elif [[ -d "$parent" ]]; then
    # If parent is a directory, set walker-root and pre-query base
    new_path=$(__fzf_select --walker-root "$parent" --query "$base")
    if [[ -n "$new_path" ]]; then 
      LBUFFER="${LBUFFER[1,-${#token}-1]}$new_path" # Replace current token with the new, expanded path
    fi
  else
    # Fallback to normal fzf
    LBUFFER="${LBUFFER}$(__fzf_select)"
  fi

  local ret=$?
  zle reset-prompt
  return $ret
}

# https://thevaluable.dev/fzf-shell-integration/

eval $(pay-respects zsh --alias fuck)
for i in $(seq 1 10); do
  alias $(echo -n 'sh'$(for j in $(seq 1 $i); do echo -n 'i'; done)'t')='fuck'
done
for i in $(seq 2 10); do
  alias $(echo -n 'f'$(for j in $(seq 1 $i); do echo -n 'u'; done)'ck')='fuck'
done
alias godfuckin='fuck'
alias crap='fuck'
alias dammit='fuck'
alias goddamnit='fuck'
alias fuckinhell='fuck'

eval "$(direnv hook zsh)"
if [ "$TERM" != "linux" ]; then
  eval "$(oh-my-posh init zsh)"
fi

# Aliases
alias ls='ls -A --color'
alias copy=$COPY_UTIL
alias cat='bat'
alias ff='fzf_with_preview'
alias reload='exec zsh'
alias reboot='systemctl shutdown -r now'
alias git-graph='git log --oneline --decorate --graph'
alias ags-restart='ags -q && ags &|'
# alias sudo='sudo ' # https://askubuntu.com/questions/22037/aliases-not-available-when-using-sudo
alias prolog='swipl'

alias nvid='neovide'

getip()
{
  ip route get 1 | awk '{print $7;exit}'
}

# I want to update this later so I can specify filetypes 
loc() {
  find $( [[ -z "$1" ]] && echo "$1" || echo ".") -type f | xargs wc -l
}

## NEOVIM ##

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
  [[ $NVIM_FRONTEND = "neovide" ]] && alias nvim='nvim_neovide_handler'
  return 0
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

# Built for handling args designed for Neovim, but not for Neovide (to run Neovide with typical args, run `neovide/nvid <args>`)
nvim_neovide_handler()
{
  for arg in "$@"; do
    if [[ "$arg" == "--help" ]]; then
      /usr/bin/env nvim --help
      return 0
    fi
  done

  neovide --fork -- "$@"
}

fzf_with_preview()
{
  # For reference
  # https://vitormv.github.io/fzf-themes/
  # This works well, it just flashes in between fzf/bat. 
  # TODO
  #   Allow this to accept a list of items from STDIN (or as a parameter). 

  # See the following to take in a list of items from STDIN
  # if [ -t 0 ]; then
  #     echo "No files provided"
  #   else
  #     mapfile -t files
  #   fi
  # for file in "${files[@]}"; do
  #   done

  while true; do 
    if [[ ! -f ITEM ]]; then
      if [[ -f "${1}" ]]; then
        cd $(dirname $1)
        ITEM=$(basename "$1")
        ITEMS=$( ls *(.D) --color=none )
        ITEMS=$(echo "$ITEMS" | grep -v "$ITEM"; echo "$ITEM")

        echo $ITEMS
        return
      elif [[ -d "${1}" ]]; then
        cd $1
        ITEMS=$( ls *(.D) --color=none) 2>/dev/null
      else
        ITEMS=$(ls *(.D) --color=none ) 2>/dev/null
      fi
    else
      ITEMS=$(echo "$ITEMS" | grep -v "$ITEM"; echo "$ITEM")
    fi

    ITEM=$(echo $ITEMS | fzf --preview 'bat --color=always {}' --preview-window 'up,75%')

    if [[ -f $ITEM ]]; then
      bat "$ITEM" --paging=always 
    else
      break
    fi
  done

  return 0
}

if [ $TERM = "linux" ]; then
  NVIM_FRONTEND="term"
fi

nix-which() {
  readlink $('which' $1)
}

set_nvim_frontend_alias

if [[ "$TERM" == "xterm-kitty" ]]; then
  ssh() { kitten ssh "$@" }
fi

# zprof

HYPRLAND_INFO="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
HYPRLAND_CONTROL="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock"
