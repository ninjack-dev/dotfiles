{
  lib,
  rustPlatform,
  buildGoModule,
  fetchFromGitHub,
  pam,
  udev,
  pkg-config,
  installShellFiles,
}:
let
  version = "v0.50.0";

  src = fetchFromGitHub {
    owner = "goauthentik";
    repo = "platform";
    tag = version;
    hash = "sha256-R65QfQZsHcVi/oAeOI6WLTKuwX4GbNJCDlsA4x1QTiU=";
  };

  meta = {
    homepage = "https://github.com/goauthentik/platform";
    changelog = "https://github.com/goauthentik/platform/releases/tag/${version}";
    license = with lib.licenses; [
      mit
    ];
    platforms = lib.platforms.all;
  };

  cargoHash = "sha256-Dkjj8yiiasJIrSJHAd0iV+2PRhwY8RxTGoTJZ/I+ON0=";
  vendorHash = "sha256-01qnu0q6Na8fvO9GQekvJuk8oregRwtumIPLSibzJo8=";

  ak-pam = rustPlatform.buildRustPackage (finalAttrs: {
    pname = "ak-pam";
    inherit src version cargoHash;

    buildInputs = [
      pam
      udev
    ];

    nativeBuildInputs = [
      pkg-config
      installShellFiles
    ];

    # --target-dir is needed because the workspace puts built files in _cache
    # TODO: Break this out, along with pname, into a convenient wrapper for all derivations
    cargoBuildFlags = [
      "--package"
      "ak-pam"
      "--target-dir"
      "target"
    ];

    doCheck = false;

    meta = {
      description = "Authentik Platform PAM module";
    }
    // meta;
  });

  ak-nss = rustPlatform.buildRustPackage (finalAttrs: {
    pname = "ak-nss";
    inherit src version cargoHash;

    cargoBuildFlags = [
      "--package"
      "ak-nss"
      "--target-dir"
      "target"
    ];

    doCheck = false;

    meta = {
      description = "Authentik Platform NSS module";
    }
    // meta;
  });

  ak-cli = rustPlatform.buildRustPackage (finalAttrs: {
    pname = "ak-cli";
    inherit src version cargoHash;

    cargoBuildFlags = [
      "--package"
      "ak-cli"
      "--target-dir"
      "target"
    ];

    nativeBuildInputs = [
      installShellFiles
    ];

    doCheck = false;

    postInstall = ''
      installShellCompletion --cmd ak \
        --bash <($out/bin/ak completion bash) \
        --zsh <($out/bin/ak completion zsh) \
        --fish <($out/bin/ak completion fish)
    '';

    meta = {
      description = "Authentik CLI";
      mainProgram = "ak";
    }
    // meta;
  });

  ak-agent = rustPlatform.buildRustPackage (finalAttrs: {
    pname = "ak-agent";
    inherit src version cargoHash;

    cargoBuildFlags = [
      "--package"
      "ak-agent"
      "--target-dir"
      "target"
    ];

    postInstall = ''
      install -Dm644 \
        vpkg/linux/agent/usr/share/polkit-1/actions/io.goauthentik.platform.policy \
        $out/share/polkit-1/actions/io.goauthentik.platform.policy
    '';

    doCheck = false;

    meta = {
      description = "Authentik Platform user agent";
      mainProgram = "ak-agent";
    };
  });

  ak-sysd = buildGoModule {
    pname = "ak-sysd";
    inherit version src vendorHash;

    subPackages = [ "cmd/agent_system" ];

    nativeBuildInputs = [
      installShellFiles
    ];

    postInstall = ''
      mv "$out/bin/agent_system" "$out/bin/ak-sysd"

      installShellCompletion --cmd ak-sysd \
        --bash <($out/bin/ak-sysd completion bash) \
        --zsh <($out/bin/ak-sysd completion zsh) \
        --fish <($out/bin/ak-sysd completion fish)
    '';

    doCheck = false;

    meta = {
      description = "Authentik Platform system agent";
      mainProgram = "ak-sysd";
    }
    // meta;
  };
in
{
  inherit
    ak-pam
    ak-nss
    ak-cli
    ak-agent
    ak-sysd
    ;
}
