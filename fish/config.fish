if status is-interactive
    # Commands to run in interactive sessions can go here
end

direnv hook fish | source
zoxide init fish --cmd cd | source
oh-my-posh init fish | source
