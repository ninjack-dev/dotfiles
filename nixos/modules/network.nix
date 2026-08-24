{
  ...
}:
{

  networking.hostName = "nixos-laptop";

  networking.networkmanager.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPortRanges = [
      {
        from = 3000;
        to = 3005;
      }
    ];
    allowedUDPPortRanges = [
    ];
    allowedTCPPorts = [
      8000
      9090 # Calibre wireless connection
      65530 # audio-share https://github.com/mkckr0/audio-share
      8472 # VXLAN for flannel
    ];
    allowedUDPPorts = [
      8000
      9090
      65530 # audio-share https://github.com/mkckr0/audio-share
      54982 # Calibre's discovery protocol
      8472 # VXLAN for flannel
    ];
  };

  services.printing.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
