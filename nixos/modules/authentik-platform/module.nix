{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.authentik-platform;
  # Residual; not sure if this is really needed
  envFile =
    let
      lines = lib.mapAttrsToList (n: v: "${n}=${toString v}") cfg.settings;
      content = lib.concatStringsSep "\n" lines;
    in
    pkgs.writeText "ak-sysd.env" content;
in
{
  options.services.authentik-platform = {
    enable = mkEnableOption "authentik platform agent";

    package = lib.mkPackageOption pkgs "ak-sysd" { };

    cliPackage = lib.mkPackageOption pkgs "ak-cli" { };

    agent = {
      enable = mkEnableOption "authentik user agent";
      package = lib.mkPackageOption pkgs "ak-agent" { };
    };

    settings = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        AK_SYS_URL = "https://authentik.company";
      };
      description = ''
        Environment variables passed to ak-sysd.
        Common keys: AK_SYS_URL, AK_SYS_INSECURE_ENV_TOKEN.
        See the authentik platform documentation for the full list.
      '';
    };

    # TODO: Implement this
    pam = {
      enable = mkEnableOption "authentik PAM integration";
      package = lib.mkPackageOption pkgs "ak-pam" { };
    };

    nss = {
      enable = mkEnableOption "authentik NSS integration";
      package = lib.mkPackageOption pkgs "ak-nss" { };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.security.polkit.enable;
        message = ''
          The authentik platform user agent requires Polkit to be enabled (security.polkit.enable = true).
        '';
      }
    ];

    environment.systemPackages = [
      cfg.package
      cfg.cliPackage
    ] ++ lib.optionals cfg.agent.enable [
      # keep ak-agent out of system path; not happy with this solution but it's the only one I'm aware of
      (pkgs.runCommandLocal "ak-agent-polkit-policy" { } ''
        mkdir -p "$out/share/polkit-1/actions"
        cp "${cfg.agent.package}/share/polkit-1/actions/io.goauthentik.platform.policy" "$out/share/polkit-1/actions/"
      '')
    ];

    # Adapted from https://github.com/goauthentik/platform/blob/main/vpkg/linux/sysd/usr/lib/systemd/system/ak-sysd.service
    systemd.services.ak-sysd = {
      description = "authentik sysd";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Restart = "always";
        ExecStart = "${lib.getExe cfg.package} agent";
        RuntimeDirectory = "authentik";
        RuntimeDirectoryMode = 0777;
      }
      // lib.optionalAttrs (cfg.settings != { }) {
        EnvironmentFile = envFile;
      };
    };

    # Adapted from https://github.com/goauthentik/platform/blob/main/vpkg/linux/agent/etc/systemd/user/ak-agent.service
    systemd.user.services.ak-agent = lib.mkIf cfg.agent.enable {
      description = "authentik Agent";
      after = [ "network.target" ];
      wantedBy = [ "default.target" ];

      serviceConfig = {
        Restart = "always";
        ExecStart = lib.getExe cfg.agent.package;
        KeyringMode = "shared"; # Not 100% sure why this is necessary in NixOS; must research
      };
    };

    # Adapted from https://github.com/goauthentik/platform/blob/main/vpkg/linux/sysd/etc/ssh/sshd_config.d/authentik-authorized-keys.conf
    services.openssh.extraConfig = lib.mkIf config.services.openssh.enable ''
      AuthorizedKeysCommand ${lib.getExe cfg.package} ssh-verify %u %k %f
      AuthorizedKeysCommandUser nobody
    '';

    # Adapted from https://github.com/goauthentik/platform/blob/main/vpkg/linux/nss/_deb/postinst.sh
    system = mkIf cfg.nss.enable {
      nssModules = [ cfg.nss.package ];
      nssDatabases = {
        passwd = lib.mkAfter [ "authentik" ];
        group = lib.mkAfter [ "authentik" ];
        shadow = lib.mkAfter [ "authentik" ];
      };
    };
  };
}
