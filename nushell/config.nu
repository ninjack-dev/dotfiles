oh-my-posh init nu
$env.config.show_banner = false

# Using this custom completer by @scientiac https://github.com/nushell/nushell/issues/10285#issuecomment-2731825727
# 
# It's a working alternative to the one found in the cookbook https://www.nushell.sh/cookbook/external_completers.html#fish-completer
let fish_completer = {|spans|
  let completions = fish --command $'complete "--do-complete=($spans | str join " ")"'
    | from tsv --flexible --noheaders --no-infer
    | rename value description

    let has_paths = ($completions | any {|row| $row.value =~ '/' or $row.value =~ '\\.\\w+$' or $row.value =~ ' '})

    if $has_paths {
      $completions | update value {|row| 
        if $row.value =~ ' ' { 
          $"'($row.value)'"  # Wrap in single quotes
        } else { 
          $row.value 
        }
      }
    } else {
      $completions
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

$env.config.cursor_shape.emacs = "blink_line"

source ~/.config/nushell/modules/.zoxide.nu
