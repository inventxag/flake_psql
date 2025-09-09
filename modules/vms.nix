{ self, ... }:
let
  inherit (self.lib) mkVM;
in
{
  perSystem =
    {
      self',
      lib,
      pkgs,
      ...
    }:
    {
      packages =
        let
          mkNode =
            name: config:
            { lib, pkgs, ... }:
            {
              imports = [
                self.modules.nixos.hapsql
                config
              ];
              services.hapsql = {
                enable = true;
                postgresqlPackage = pkgs.postgresql_15;
              };
            };
        in
        {
          vm1 = mkNode "vm1" { };
          #          vm2 = mkVM self'.nixosConfigurations.node2vm;
          #          vm3 = mkVM self'.nixosConfigurations.node3vm;

          # This package builds all VM images at once
          vms = pkgs.symlinkJoin {
            name = "all-vms";
            paths = [
              self'.packages.vm1
              #              self'.packages.vm2
              #              self'.packages.vm3
            ];
            postBuild = ''
              mkdir -p $out
              ln -s ${self'.packages.vm1}/nixos.qcow2 $out/vm1.qcow2
              ln -s ${self'.packages.vm2}/nixos.qcow2 $out/vm2.qcow2
              ln -s ${self'.packages.vm3}/nixos.qcow2 $out/vm3.qcow2
            '';
          };
        };
    };
}
