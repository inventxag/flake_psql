{ inputs, ... }:
{
  flake.modules.nixos.node-base =
    {
      lib,
      pkgs,
      ...
    }:
    {
      system.stateVersion = "25.11";
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      nix.registry = lib.mapAttrs (_: flake: { inherit flake; }) inputs;

      virtualisation.vmVariant.virtualisation.diskSize = 20 * 1024;

      users.users.root.password = "root"; # TODO: don't use in production!
      services.getty.autologinUser = "root";

      environment.systemPackages = builtins.attrValues {
        inherit (pkgs)
          curl
          nettools
          ;
      };

      services.hapsql = {
        enable = true;
      };

      # Enable SSH
      services.openssh = {
        enable = true;
        settings = {
          #PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "yes"; # or "no" if you prefer
        };
      };

      # Add your public key
      users.users.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJBHH6vsLzOs4oTIOoNDKnJExUl2mvjmYS9ey5L6f1PY"
      ];

      # Optional: Create a regular user with the same key
      # users.users.art = {
      #   isNormalUser = true;
      #   extraGroups = [ "wheel" "sudo" ];
      #   openssh.authorizedKeys.keys = [
      #     "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJBHH6vsLzOs4oTIOoNDKnJExUl2mvjmYS9ey5L6f1PY"
      #   ];
      # };

      # Enable sudo without password for wheel group
      security.sudo.wheelNeedsPassword = false;
    };
}
