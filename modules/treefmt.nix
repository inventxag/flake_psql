{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem.treefmt.programs = {
    nixfmt.enable = true;
    #    deadnix.enable = true;
    nixf-diagnose.enable = true;
  };
}
