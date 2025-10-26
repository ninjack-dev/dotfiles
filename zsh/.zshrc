ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)" # If ZINIT_HOME folder isn't present, make it.
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" # If the git folderisn't present, clone the repo.  
source "${ZINIT_HOME}/zinit.zsh"

zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

HISTFILE=~/.config/zsh/.histfile
HISTSIZE=1000
SAVEHIST=$HISTSIZE
setopt appendhistory
setopt sharehistory 
setopt hist_ignore_space # prepend a space to prevent addition to history

stty -ctlecho # This disables the ^C echoing when killing an app

setopt autocd
unsetopt beep


## Keybindings ##
bindkey -e

bindkey "^[[1;5D" backward-word # Bind <C> + Left/Right to move 1 word
bindkey "^[[1;5C" forward-word

bindkey "^j" down-history
bindkey "^k" up-history

zle -N nvim_neovide_handler
bindkey '^N' nvim_neovide_handler

## Completions ##
zstyle ':completion:*' matcher-list 'm:{A-Za-z}={a-zA-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle :compinstall filename '/home/jacksonb/.zshrc' # I don't know what this does. It was put here automagically when I set up ZSH so I'll leave it be. 
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

# https://gist.github.com/ctechols/ca1035271ad134841284#gistcomment-2308206
autoload bashcompinit && bashcompinit
autoload -Uz compinit
compinit -C

complete -C 'aws_completer' aws

## Aliases and Functions ##
alias ls='ls -A --color'
alias cat='bat'
alias ff='fzf_with_preview'

getip()
{
  ip route get 1 | awk '{print $7;exit}'
}

loc() {
  find $( [[ -z "$1" ]] && echo "$1" || echo ".") -type f | xargs wc -l
}

nix-which() {
  readlink $('which' $1)
}

## Shell Integrations ##
eval "$(zoxide init zsh --cmd cd)"

eval "$(fzf --zsh)"

# Custom FZF cd widget which uses zoxide
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

FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
FZF_ALT_C_COMMAND="fd --hidden --type directory --exclude .git"
FZF_CTRL_T_COMMAND="fd -H --full-path"

# Custom FZF file widget to expand paths currently being edited.
# TODO: 
# - Debug FZF_CTRL_T_COMMAND
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
    local ret=$?
    zle reset-prompt
    return $ret
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

# pay-respects integration https://github.com/iffse/pay-respects
# Escaped hexadecimal: `echo -n "a_family_friendly_alias" | od -A n -t x1 | sed 's/ /\\0x/g' | tr -d '\n' | awk "{ printf \"\$(echo -n '\"\$1 \"')\"}" | wl-copy`
local respects_alias=$(echo '\0x66\0x75\0x63\0x6b')
eval "$(pay-respects zsh --alias $respects_alias)"
for i in $(seq 1 10); do
  alias $(echo -n '\0x73\0x68'$(for j in $(seq 1 $i); do echo -n '\0x69'; done)'\0x74')=$respects_alias
done
for i in $(seq 2 10); do
  alias $(echo -n '\0x66'$(for j in $(seq 1 $i); do echo -n '\0x75'; done)'\0x63\0x6b')=$respects_alias
done
alias $(echo -n '\0x67\0x6f\0x64\0x66\0x75\0x63\0x6b\0x69\0x6e')=$respects_alias
alias $(echo -n '\0x63\0x72\0x61\0x70')=$respects_alias
alias $(echo -n '\0x64\0x61\0x6d\0x6d\0x69\0x74')=$respects_alias
alias $(echo -n '\0x67\0x6f\0x64\0x64\0x61\0x6d\0x6d\0x69\0x74')=$respects_alias
alias $(echo -n '\0x66\0x75\0x63\0x6b\0x69\0x6e\0x68\0x65\0x6c\0x6c')=$respects_alias

eval "$(direnv hook zsh)"
if [ "$TERM" != "linux" ]; then
  eval "$(oh-my-posh init zsh)"
fi

## Neovim ##

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

  echo "$config is now selected as default config.";
  sed -i "s/NVIM_APPNAME=[^ ]*/NVIM_APPNAME=$config/" $ZDOTDIR/.zshenv;
  source $ZDOTDIR/.zshenv;
  done;
}

# Built for handling args designed for Neovim, but not for Neovide (to run Neovide with typical args, run `neovide/nvid <args>`)
nvim_neovide_handler()
{
  for arg in "$@"; do
    if [[ "$arg" == "--help" ]]; then
      \nvim --help
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

## Terminal-specific functionality
case "$TERM" in
  "linux") 
    NVIM_FRONTEND="term"
  ;;
  "xterm-kitty") 
    :
  ;;
esac

set_nvim_frontend_alias

## Variables ##
HYPRLAND_INFO="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
HYPRLAND_CONTROL="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock"
