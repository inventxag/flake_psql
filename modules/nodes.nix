{ self, inputs, ... }:
{
  flake.nixosConfigurations = {
    node1 = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.modules.nixos.hapsql
        self.modules.nixos.node-base
        { nixpkgs.hostPlatform = "x86_64-linux"; }
        ../node-configs/node1-qemu.nix
      ];
    };
    #    node2 = mkNode ../node-configs/node2-qemu.nix;
    #    node3 = mkNode ../node-configs/node3-qemu.nix;
  };
}
