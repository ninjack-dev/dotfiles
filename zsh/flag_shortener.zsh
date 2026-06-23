# flag_shortener - Zsh completion widget: toggle long flags ↔ short flags
#
# Press Ctrl-S with the cursor on a long flag like `--update`
# and the widget replaces it with the short form `-u`.
# Press Ctrl-S with the cursor on a short flag like `-u`
# and the widget replaces it with the long form `--update`.
#
# Compound short flags are handled: if the cursor is on a character
# inside a compound like `-u|v`, the character is expanded to its
# long form and the rest kept as separate short flags:
#   -u|v  -->  --update -v
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

  # Clear REPLY to prevent stale values from a previous invocation
  # leaking when the look-up functions fail to find a mapping.
  REPLY=''

  # ---------- 1. Find the word we want to replace ----------

  local target=''
  local reverse=0
  local -a left_parts=() right_parts=()

  # Long flag: --update, --human-readable, etc.
  if [[ "${words[$CURRENT]}" == --* ]]; then
    target="${words[$CURRENT]}"
  elif [[ "${PREFIX}${SUFFIX}" == --* ]]; then
    target="${PREFIX}${SUFFIX}"
  fi

  if [[ -z "$target" ]]; then
    local fullword="${PREFIX}${SUFFIX}"
    local fwlen=${#fullword}

    if [[ "$fullword" == -[a-zA-Z0-9]* && $fwlen -ge 2 ]]; then
      # Short flag: either simple (-u) or compound (-uv).
      if [[ $fwlen -gt 2 ]]; then
        # Compound: expand the character at the cursor position.
        # The cursor position is determined by comparing LBUFFER
        # with the full word — the longest suffix of LBUFFER that
        # matches a prefix of fullword tells us the cursor offset.
        local expand_pos
        local -i i

        # Determine offset: longest suffix of LBUFFER matching
        # a prefix of fullword.
        local in_lbuf=0
        for ((i = fwlen; i > 0; i--)); do
          if [[ $i -le $#LBUFFER && "${LBUFFER[-i,-1]}" == "${fullword[1,i]}" ]]; then
            in_lbuf=$i
            break
          fi
        done

        # Map cursor-relative position to expand position
        if (( in_lbuf <= 1 )); then
          expand_pos=2                    # Cursor at/before dash → first flag char
        elif (( in_lbuf >= fwlen )); then
          expand_pos=$fwlen               # Cursor at/after end → last char
        else
          expand_pos=$in_lbuf             # Char immediately before cursor
        fi

        target="-${fullword[$expand_pos]}"
        reverse=1

        # Build left and right arrays for remaining flag chars.
        # Flags before expand_pos go in left_parts (appear before
        # the expanded flag), those after go in right_parts.
        for ((j = 2; j <= fwlen; j++)); do
          if [[ $j -ne $expand_pos ]]; then
            if (( j < expand_pos )); then
              left_parts+=( "-${fullword[j]}" )
            else
              right_parts+=( "-${fullword[j]}" )
            fi
          fi
        done
      else
        # Simple single short flag: -u
        target="$fullword"
        reverse=1
      fi
    elif [[ "${words[$CURRENT]}" == -[a-zA-Z0-9]* ]]; then
      local wlen=${#words[$CURRENT]}
      if [[ $wlen -ge 2 ]]; then
        target="${words[$CURRENT]}"
        reverse=1
      fi
    fi
  fi

  [[ -n "$target" ]] || return 1

  # ---------- 2. Determine command and subcommand ----------

  local cmd="${words[1]}"
  local subcmd=''
  for w in "${words[@]:1}"; do
    [[ "$w" != -* ]] && { subcmd="$w"; break; }
  done

  # ---------- 3. Find the counterpart flag ----------

  local counterpart=''
  _flag_shortener_find "$cmd" "$subcmd" "$target"
  counterpart=$REPLY

  [[ -n "$counterpart" ]] || return 1

  # ---------- 4. Handle compound short flags ----------

  # Build insertion as: left_parts + counterpart + right_parts,
  # preserving the original order of remaining flags around the
  # expanded one.
  local -a all_parts=( "${left_parts[@]}" "$counterpart" "${right_parts[@]}" )
  local insertion="${(j: :)all_parts}"

  # ---------- 5. Insert via completion pipeline ----------

  compadd -UQ -- "$insertion"

  compstate[insert]=1

  # When SUFFIX is non-empty (cursor in middle of word), tell the
  # completion system to replace the full word, not just PREFIX.
  [[ -n "$SUFFIX" ]] && compstate[exact]=-1

  return 0
}

# ---------------------------------------------------------------------------
# Mapping discovery — shared entry point
# ---------------------------------------------------------------------------

_flag_shortener_find() {
  emulate -L zsh

  local cmd="$1" subcmd="$2" target="$3"

  _flag_shortener_from_comps "$cmd" "$subcmd" "$target" && return 0
  _flag_shortener_from_help "$cmd" "$subcmd" "$target" && return 0

  return 1
}

# ---------------------------------------------------------------------------
# Strategy A: Parse completion function source for {-short,--long} patterns
# ---------------------------------------------------------------------------

_flag_shortener_from_comps() {
  emulate -L zsh

  local cmd="$1" subcmd="$2" target="$3"
  REPLY=''

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
  # We extract those pairs here.  Both directions are built so that
  # the function handles short→long lookup too.

  local -A l2s s2l
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
      s2l[$short_part]="$long_part"
    fi

    temp="${temp#*$MATCH}"
  done

  # Check both maps so this function works for both directions.
  REPLY="${l2s[$target]}"
  [[ -n "$REPLY" ]] && return 0
  REPLY="${s2l[$target]}"
  [[ -n "$REPLY" ]] && return 0
  return 1
}

# ---------------------------------------------------------------------------
# Strategy B: Fallback to parsing the command's -h / --help output
# ---------------------------------------------------------------------------

_flag_shortener_from_help() {
  emulate -L zsh

  local cmd="$1" subcmd="$2" target="$3"
  REPLY=''

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

  local counterpart=''
  local line

  if [[ "$target" == --* ]]; then
    # ---- Long → short ----
    local target_name="${target##--}"

    while IFS= read -r line; do
      line="${line##[[:space:]]##}"
      local clean="${line//\[no-\]/}"

      # Pattern: -X,--NAME or -X, --NAME
      if [[ "$clean" == (-[a-zA-Z0-9],[[:space:]]#--"${target_name}"*) ]]; then
        counterpart="${clean:0:2}"
        break
      fi

      # Pattern: --NAME,-X or --NAME, -X
      if [[ "$clean" == (--"${target_name}",[[:space:]]#-[a-zA-Z0-9]*) ]]; then
        local comma_rest="${clean#*,}"
        comma_rest="${comma_rest##[[:space:]]##}"
        counterpart="${comma_rest:0:2}"
        break
      fi
    done <<< "$help_text"

  elif [[ "$target" == -[a-zA-Z0-9] ]]; then
    # ---- Short → long ----
    local target_char="${target#-}"

    while IFS= read -r line; do
      line="${line##[[:space:]]##}"
      local clean="${line//\[no-\]/}"

      # Pattern: -X,--NAME or -X, --NAME
      if [[ "$clean" == (-"${target_char}",[[:space:]]#--[a-zA-Z0-9_-]*) ]]; then
        # Extract the long flag: --NAME
        local after_comma="${clean#*,}"
        after_comma="${after_comma##[[:space:]]##}"
        counterpart="${after_comma%%[^a-zA-Z0-9_-]*}"
        # Ensure it starts with --
        if [[ "$counterpart" == --* ]]; then
          break
        fi
        counterpart=''
      fi

      # Pattern: --NAME,-X or --NAME, -X
      if [[ "$clean" == (--[a-zA-Z0-9_-]*,[[:space:]]#-"${target_char}"*) ]]; then
        counterpart="${clean%%,*}"
        counterpart="${counterpart%%[^a-zA-Z0-9_-]*}"
        break
      fi
    done <<< "$help_text"
  fi

  if [[ -n "$counterpart" ]]; then
    REPLY="$counterpart"
    return 0
  fi

  return 1
}

# ---------------------------------------------------------------------------
# Register and bind
# ---------------------------------------------------------------------------

# Register as a completion widget so ZLE provides $words, $CURRENT,
# $PREFIX, and $SUFFIX automatically (no manual context computation).
zle -C flag-shortener .complete-word _flag_shortener_widget

# Bind to Ctrl-S
bindkey '^S' flag-shortener
