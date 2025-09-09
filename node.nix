{
  pkgs,
  ...
}:
{
  system.stateVersion = "25.11";
  nixpkgs.hostPlatform = "x86_64-linux";

  # Filesystem configuration for VM builds
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Boot loader configuration
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda"; # For QEMU VMs
  };

  # Enable firewall with comprehensive rules for HA PostgreSQL
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22 # SSH
      5432 # PostgreSQL
      8008 # Patroni REST API
      5010 # Patroni Raft consensus
    ];
    allowedUDPPorts = [
      5010 # Patroni Raft consensus (UDP)
    ];
  };

  users.users.root.password = "root";

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      curl
      nettools
      ;
  };

  services.getty.autologinUser = "root";

  services.hapsql = {
    enable = true;
  };
}
