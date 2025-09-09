{ inputs, ... }:
{
  debug = true;
  imports = [
    inputs.flake-parts.flakeModules.modules
    ./devshell.nix
    ./hapsql.nix
    ./node-base.nix
    ./nodes.nix
    ./treefmt.nix
    ./tests/hapsql-tests.nix
    #    ./vms.nix
  ];
}
