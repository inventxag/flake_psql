{
  lib,
  pkgs,
  ...
}:
{
  system.stateVersion = "25.11";
  nixpkgs.hostPlatform = "x86_64-linux";

  # Enable firewall with comprehensive rules for HA PostgreSQL
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22      # SSH
      5432    # PostgreSQL
      8008    # Patroni REST API
      5010    # Patroni Raft consensus
    ];
    allowedUDPPorts = [
      5010    # Patroni Raft consensus (UDP)
    ];
    # Allow ICMP for ping
    allowedICMPTypes = [ "echo-request" "echo-reply" ];
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
