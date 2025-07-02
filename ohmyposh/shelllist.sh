#!/bin/sh
# I could not for the life of me get this to embed in YAML properly. Way too much of a hassle, so it's separate for now
# A bit rough; could do with a pass to make it cleaner.
ps -o pid=,ppid=,comm= \
  | awk -v pid=$$ -v shell="$POSH_SHELL" '
BEGIN { 
  chain = ""
  bash_subshells = 2 # Bash spawns a couple of subshells for the OMP integration
  zsh_subshells = 1  # Zsh only spawns one
}
{
    proc[$1] = $2
    comm[$1] = $3
}
END {
    p = pid
    shubshell_factor = 0
    skip_two = 0     # Skip the invocation of oh-my-posh and this script
    while (comm[p] != "" && !seen[p]) {
        if (shell == "zsh" && comm[p] == "zsh" && subshell_factor < zsh_subshells) {
           subshell_factor++
        }
        else if (shell == "bash" && comm[p] == "bash" && subshell_factor < bash_subshells) {
           subshell_factor++
        } else if (skip_two++ >= 2){
           chain = comm[p] (chain ? " " chain : "")
        }
        seen[p] = 1
        p = proc[p]
    }
    print chain
}'
