{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  k3s = pkgs.unstable.k3s;
  # K3s doesn't ship with CLI completions despite being a Cobra program.
  k3sCompletions = (
    pkgs.runCommand "k3s-completions"
      {
        nativeBuildInputs = [ pkgs.installShellFiles ];
      }
      ''
        # K3s needs these set; it doesn't use them for completion generations
        export HOME=$PWD
        export XDG_CACHE_HOME=$PWD/cache
        export XDG_DATA_HOME=$PWD/data

        installShellCompletion --cmd k3s \
          --bash <(${k3s}/bin/k3s completion bash) \
          --zsh <(${k3s}/bin/k3s completion zsh)

        installShellCompletion --cmd kubectl \
          --bash <(${k3s}/bin/kubectl completion bash) \
          --zsh <(${k3s}/bin/kubectl completion zsh)
      ''
  );

  # k3s's --flannel-iface wt0 makes the agent fatal-exit at startup unless wt0
  # already carries a global unicast IPv4 address.
  waitForWt0 = pkgs.writeShellScript "k3s-wait-for-wt0" ''
    tries=0
    while [ $tries -lt 120 ]; do
      if ${pkgs.iproute2}/bin/ip -4 -o addr show dev wt0 2>/dev/null \
          | ${pkgs.gnugrep}/bin/grep -q ' scope global '; then
        exit 0
      fi
      tries=$((tries + 1))
      sleep 1
    done
    echo "k3s: timed out waiting for wt0 (NetBird) to have a global unicast IPv4 address" >&2
    exit 1
  '';
in
{
  services.k3s = {
    enable = true;
    role = "agent";
    # NOTE: This is unidiomatic for K3s agent token paths, which are typically at /var/lib/rancher/k3s/server/agent-token, but only when a node is a server. This is also hacky; proper SOPS/AGE is on the table.
    tokenFile = /var/lib/rancher/k3s/agent/token;
    serverAddr = "https://192.168.2.3:6443"; # Homelab LAN node, reachable via exit node
    extraFlags = [ "--flannel-iface wt0" ]; # NetBird interface
    package = k3s;
  };

  systemd.services.k3s = {
    after = [ "netbird.service" ];
    wants = [ "netbird.service" ];
    serviceConfig.ExecStartPre = [ waitForWt0 ];
  };

  services.openiscsi = {
    enable = true;
    name = "iqn.2026-08.lab.ninjack:${config.networking.hostName}";
  };

  boot.kernelModules = [ "iscsi_tcp" ];

  # https://github.com/longhorn/longhorn/issues/2166
  systemd.tmpfiles.rules = [
    "L+ /usr/local/sbin/iscsiadm - - - - /run/current-system/sw/bin/iscsiadm"
  ];

  environment.systemPackages = with pkgs; [
    unstable.fluxcd
    unstable.kustomize
    unstable.kubernetes-helm
    openiscsi
    k3sCompletions
  ];
}
