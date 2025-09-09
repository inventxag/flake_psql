{ config, pkgs, ... }:
{
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
}