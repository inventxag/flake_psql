{
  lib,
  pkgs,
  ...
}:
{
  system.stateVersion = "25.11";
  nixpkgs.hostPlatform = "x86_64-linux";

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
