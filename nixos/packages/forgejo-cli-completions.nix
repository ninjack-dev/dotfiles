{
  lib,
  runCommand,
  installShellFiles,
  forgejo-cli,
}:
# forgejo-cli 0.6.0 always loads its keys file, and when the keys file is missing, it prints
# "Could not find keys file. Creating a new file." to stdout, so that line
# ends up at the top of each generated completion script. For zsh in particular this is
# fatal, since compinit only reads the first line of a fpath file to find the
# `#compdef` tag, meaning `_fj` is ignored and `fj` has no completions.
#
# Fixed upstream in #626, which reports the message to stderr instead:
#   https://codeberg.org/forgejo-contrib/forgejo-cli/pulls/626
#
# This package can be dropped once nixpkgs' forgejo-cli is updated with the fix
lib.warnIf (forgejo-cli.version != "0.6.0")
  "forgejo-cli-completions: forgejo-cli is now ${forgejo-cli.version}, but this stopgap was written for 0.6.0. Check whether PR #626 is in the release and, if so, remove this package."
  (
    runCommand "forgejo-cli-completions"
      {
        nativeBuildInputs = [ installShellFiles ];
        meta = {
          inherit (forgejo-cli) version;
          description = "Shell completions for forgejo-cli";
          homepage = forgejo-cli.meta.homepage;
          license = forgejo-cli.meta.license;
          priority = 4; # Outrank forgejo-cli in buildEnv
        };
      }
      ''
        # Supplant $HOME and pre-seed an empty keys file so v0.6.0 doesn't emit the diagnostic
        export HOME=$PWD
        export XDG_DATA_HOME=$PWD/data
        mkdir -p "$XDG_DATA_HOME/forgejo-cli"
        printf '{"hosts":{}}\n' > "$XDG_DATA_HOME/forgejo-cli/keys.json"

        installShellCompletion --cmd fj \
          --bash <(${forgejo-cli}/bin/fj completion bash) \
          --fish <(${forgejo-cli}/bin/fj completion fish) \
          --zsh <(${forgejo-cli}/bin/fj completion zsh)
      ''
  )
