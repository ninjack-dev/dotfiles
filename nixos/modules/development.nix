{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  dotnet = (
    with pkgs.unstable.dotnetCorePackages;
    combinePackages [
      sdk_9_0_1xx
      sdk_10_0_1xx
    ]
  );

  langPkgs = with pkgs; {
    go = with unstable; [
      go
      gopls
    ];

    rust = with unstable; [
      rustc
      cargo
      rustfmt
      clippy
      rust-analyzer
      sccache
    ];

    godot = with unstable; [
      (callPackage ../packages/godot-mono.nix { inherit dotnet; })
      gdscript-formatter
    ];

    dotnet = with unstable; [
      dotnet
      csharp-ls # TODO: Consider Roslyn-based alternative(s)
    ];

    javascript = with unstable; [
      nodejs
      deno
    ];

    lua = with unstable; [
      lua
      stylua
      lua-language-server
    ];

    python = [
      (pkgs.python3.withPackages (
        pyPkgs: with pyPkgs; [
          pandas
          requests
          tkinter
          pygobject3
          pygobject-stubs
        ]
      ))
      unstable.uv
      black
      pyright
    ];

    vala = with unstable; [
      vala
      vala-language-server
    ];

    perl = [
      (perl.withPackages (
        perl-pkgs: with perl-pkgs; [
          NetDBus
        ]
      ))
      perlnavigator
    ];

    powershell = with unstable; [
      powershell
      powershell-editor-services
    ];

    zig = with unstable; [
      zig
      zls
    ];
  };
in
{
  environment.systemPackages =
    with pkgs;
    [
      # Uncategorized
      blesh
      ripgrep
      fd
      jq
      fzf
      wget
      tmux
      zoxide
      unstable.nushell
      psmisc # Provides fuser, pstree
      unstable.pay-respects
      unstable.gh
      unstable.libqalculate
      unzip
      yq-go
      bpftrace
      unstable.forgejo-cli
      libnotify
      gum
      stow

      unstable.secretspec

      # Networking
      dig
      socat
      iptables

      # Profiling/Tracing
      valgrind

      # LSP servers
      clang-tools
      nixd
      vscode-langservers-extracted
      yaml-language-server
      awk-language-server
      unstable.tombi
      typescript-language-server
      bash-language-server

      # Graphical Tools
      d-spy
      wev
      unstable.podman-desktop
      wireshark
    ]
    ++ lib.concatLists (lib.attrValues langPkgs);

  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  programs.direnv = {
    enable = true;
    loadInNixShell = true;
    nix-direnv = {
      enable = true;
    };
  };

  documentation.dev.enable = true;
}
