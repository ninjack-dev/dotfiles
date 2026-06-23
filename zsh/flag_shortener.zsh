# flag_shortener - Zsh completion widget: replace long flags with short flags
#
# Press Ctrl-S with the cursor on a long flag like `--update`
# and the widget replaces it with the short form `-u`.
#
# It discovers the mapping by parsing the Zsh completion function
# source for the current command, looking for brace patterns like
#   {-u,--update}
# that link a short flag to its long form.
#
# If the completion function doesn't use that pattern (or isn't found),
# it falls back to parsing the command's `-h` / `--help` output.
#
# Installation:
#   source ~/.config/zsh/flag_shortener.zsh
#   (Ctrl-S is already bound inside the file)
#
# Requirements:
#   - Zsh completion system must be loaded (compinit)
#   - Completion for the target command must be installed
#   - Terminal flow control must be disabled so Ctrl-S reaches ZLE:
#       stty -ixon
#     Add this to your .zshrc before sourcing this file.

# ---------------------------------------------------------------------------
# Widget entry-point (completion widget for zle -C)
# ---------------------------------------------------------------------------

_flag_shortener_widget() {
  emulate -L zsh

  # ---------- 1. Find the word we want to replace ----------

  local target=''

  # If the word at CURRENT looks like a long flag, use it.
  if [[ "${words[$CURRENT]}" == --* ]]; then
    target="${words[$CURRENT]}"
  fi

  # If the combined PREFIX+SUFFIX (cursor in middle of word) looks like
  # a long flag, use that — this catches the case where the cursor is
  # inside a long flag like --up|date.
  if [[ -z "$target" ]] && [[ "${PREFIX}${SUFFIX}" == --* ]]; then
    target="${PREFIX}${SUFFIX}"
  fi

  # Only convert the word under the cursor.  Unlike the old normal
  # widget (which walked backwards), a completion widget cannot
  # replace a word that isn't the current one — compadd always
  # inserts at the cursor position.
  [[ -n "$target" ]] || return 1

  # ---------- 2. Determine command and subcommand ----------

  local cmd="${words[1]}"
  local subcmd=''
  local -i i
  for (( i=2; i <= ${#words}; i++ )); do
    local w="${words[i]}"
    if [[ "$w" != -* ]]; then
      if [[ -z "$subcmd" ]]; then
        subcmd="$w"
      fi
    fi
  done

  # ---------- 3. Find the short flag via Zsh completions ----------

  local short_flag
  _flag_shortener_find_short "$cmd" "$subcmd" "$target"
  short_flag=$REPLY

  [[ -n "$short_flag" ]] || return 1

  # ---------- 4. Insert via completion pipeline ----------

  # Register the short flag as a completion match.
  #   -U : use the word as-given (no quoting transformations)
  #   -Q : display as given (no additional quoting)
  #   -- : guard against short_flag starting with dash (e.g., -u)
  compadd -UQ -- "$short_flag"

  # Insert the match immediately (no menu selection).
  compstate[insert]=1

  # When SUFFIX is non-empty (cursor in middle of the word, e.g.
  # "--up█date"), the completion system normally replaces only
  # PREFIX and keeps SUFFIX.  Setting exact=-1 tells it to treat
  # the match as exact and replace the whole word.
  [[ -n "$SUFFIX" ]] && compstate[exact]=-1

  return 0
}

# ---------------------------------------------------------------------------
# Mapping discovery
# ---------------------------------------------------------------------------

_flag_shortener_find_short() {
  emulate -L zsh

  local cmd="$1" subcmd="$2" target="$3"

  # Strategy A: Parse Zsh completion function source
  _flag_shortener_from_comps "$cmd" "$subcmd" "$target" && return 0

  # Strategy B: Parse command help output (fallback)
  _flag_shortener_from_help "$cmd" "$subcmd" "$target" && return 0

  return 1
}

# ---------------------------------------------------------------------------
# Strategy A: Parse completion function source for {-short,--long} patterns
# ---------------------------------------------------------------------------

_flag_shortener_from_comps() {
  emulate -L zsh

  local cmd="$1" subcmd="$2" target="$3"

  # Get the top-level completion function
  local comp_func="${_comps[$cmd]}"
  [[ -n "$comp_func" ]] || return 1

  # Ensure the function is autoloaded.
  if ! typeset -f "$comp_func" >/dev/null 2>&1; then
    autoload -Uz "$comp_func" 2>/dev/null || return 1
  fi

  # Call the function once in a (minimal) completion context so that
  # lazy sub-function definitions (e.g. _git-add inside _git) are created.
  local -a save_words=("${words[@]}")
  local save_current=$CURRENT
  local save_prefix="$PREFIX"
  local save_suffix="$SUFFIX"
  local save_curcontext="$curcontext"

  words=( "$cmd" "$subcmd" "$target" )
  CURRENT=3
  PREFIX="$target"
  SUFFIX=''
  curcontext=":completion::complete:${cmd}:"

  "$comp_func" 2>/dev/null || true

  words=("${save_words[@]}")
  CURRENT=$save_current
  PREFIX="$save_prefix"
  SUFFIX="$save_suffix"
  curcontext="$save_curcontext"

  # Determine the sub-function name.
  local sub_func="${comp_func}-${subcmd}"

  # Fall back to looking up a dedicated entry in _comps.
  if ! typeset -f "$sub_func" >/dev/null 2>&1; then
    local comp_sub="${_comps[$cmd-$subcmd]}"
    if [[ -n "$comp_sub" ]]; then
      sub_func="$comp_sub"
    fi
  fi

  # Get the source code of the sub-function.
  local src="${functions[$sub_func]}"
  [[ -n "$src" ]] || return 1

  # ---- Parse the source for {-short,--long} brace patterns ----
  #
  # In Zsh completion functions, options that have both a short and a long
  # form are typically written as:
  #   '(-n --dry-run)'{-n,--dry-run}'[dry run]'
  #
  # The short and long flags are linked via a brace expansion.
  # We extract those pairs here.

  local -A l2s
  l2s=()
  local temp="$src"

  # ERE pattern: match {-X,--yyyyy} (including + and = suffixes for value-taking options)
  local pattern='\{-[a-zA-Z0-9][^,]*,--[a-zA-Z0-9_-][^,]*\}'

  while [[ "$temp" =~ $pattern ]]; do
    local brace="$MATCH"
    local inner="${brace#\{}"
    inner="${inner%\}}"
    local parts=("${(@s:,:)inner}")
    local short_part="${parts[1]}"
    local long_part="${parts[2]}"

    # Strip value-taking suffixes (e.g. -m+ -> -m, --message= -> --message)
    short_part="${short_part%%[+:=]}"
    long_part="${long_part%%[+:=]}"

    if [[ "$short_part" == -[a-zA-Z0-9] && "$long_part" == --[a-zA-Z0-9_-]* ]]; then
      l2s[$long_part]="$short_part"
    fi

    temp="${temp#*$MATCH}"
  done

  REPLY="${l2s[$target]}"
  [[ -n "$REPLY" ]] && return 0
  return 1
}

# ---------------------------------------------------------------------------
# Strategy B: Fallback to parsing the command's -h / --help output
# ---------------------------------------------------------------------------

_flag_shortener_from_help() {
  emulate -L zsh

  local cmd="$1" subcmd="$2" target="$3"
  local target_name="${target##--}"

  local help_text=''

  # Try various ways to get help output, safely.
  if [[ -n "$subcmd" ]]; then
    help_text=$("$cmd" "$subcmd" --help 2>/dev/null) ||
      help_text=$("$cmd" "$subcmd" -h 2>/dev/null)
  fi
  if [[ -z "$help_text" ]]; then
    help_text=$("$cmd" --help 2>/dev/null) ||
      help_text=$("$cmd" -h 2>/dev/null)
  fi
  [[ -n "$help_text" ]] || return 1

  # Strip ANSI escape codes (SGR and OSC sequences)
  setopt localoptions extendedglob
  # Remove ESC [ ... m  (SGR)
  help_text="${help_text//$'\e['[^m]#m/}"
  # Remove ESC ] ... (ESC \ or BEL)  (OSC sequences, e.g. hyperlinks)
  help_text="${help_text//$'\e]'[^$'\e\a']#($'\e\\'|$'\a')/}"

  local short=''
  local line

  while IFS= read -r line; do
    line="${line##[[:space:]]##}"

    # Remove [no-] prefix from --long-name in help (--[no-]verbose -> --verbose)
    local clean="${line//\[no-\]/}"

    # Pattern: -X,--NAME or -X, --NAME
    if [[ "$clean" == (-[a-zA-Z0-9],[[:space:]]#--"${target_name}"*) ]]; then
      short="${clean:0:2}"
      break
    fi

    # Pattern: --NAME,-X or --NAME, -X
    if [[ "$clean" == (--"${target_name}",[[:space:]]#-[a-zA-Z0-9]*) ]]; then
      local comma_rest="${clean#*,}"
      comma_rest="${comma_rest##[[:space:]]##}"
      short="${comma_rest:0:2}"
      break
    fi
  done <<< "$help_text"

  if [[ -n "$short" ]]; then
    REPLY="$short"
    return 0
  fi

  return 1
}

# ---------------------------------------------------------------------------
# Register and bind
# ---------------------------------------------------------------------------

# Register as a completion widget so ZLE provides $words, $CURRENT,
# $PREFIX, and $SUFFIX automatically (no manual context computation
# needed). The widget function still manipulates BUFFER directly
# for reliable replacement regardless of cursor position.
zle -C flag-shortener .complete-word _flag_shortener_widget

# Bind to Ctrl-S
bindkey '^S' flag-shortener
