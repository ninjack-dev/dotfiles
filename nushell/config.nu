oh-my-posh init nu
$env.config.show_banner = false

# Using this custom completer by @scientiac https://github.com/nushell/nushell/issues/10285#issuecomment-2731825727
# 
# I've found that it's rather slow, and could really benefit from some kind of caching or background work.
let fish_completer = {|spans|
    fish --command $"complete '--do-complete=($spans | str replace --all "'" "\\'" | str join ' ')'"
    | from tsv --flexible --noheaders --no-infer
    | rename value description
    | update value {|row|
      let value = $row.value
      let need_quote = ['\' ',' '[' ']' '(' ')' ' ' '\t' "'" '"' "`"] | any {$in in $value}
      if ($need_quote and ($value | path exists)) {
        let expanded_path = if ($value starts-with ~) {$value | path expand --no-symlink} else {$value}
        $'"($expanded_path | str replace --all "\"" "\\\"")"'
      } else {$value}
    }
}

$env.config = {
    completions: {
        external: {
            enable: true
            completer: $fish_completer
        }
    }
}

def hyprctl_completions [spans] {
  do $fish_completer $spans
  | where value != '-j'
}

def --wrapped hyprctl [...rest: string@hyprctl_completions] {
  let args = $rest | where {$in != "-j"}
  let result = ^hyprctl -j ...$args | complete
  if ($result.exit_code == 0) {
    try {
      return ($result.stdout | from json)
    }
  } 
  print $result.stdout
  ^false # Wish there was a way to set the exit code quickly; nu -c $"exit ($result.exit_code)" is too slow
}

$env.config.cursor_shape.emacs = "blink_line"

source ~/.config/nushell/modules/.zoxide.nu
