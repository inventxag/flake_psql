{
  description =
    "PL/pgSQL development flake with PostgreSQL client and optional server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, nixos-generators, ... }:
    let
      # Helper function to generate a NixOS configuration for a node.
      mkNode = nodeSpecificConfig: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./node.nix
          nodeSpecificConfig
          self.nixosModules.hapsql
          self.nixosModules.ssh-config
          ({ pkgs, ... }: {
            services.hapsql.postgresqlPackage = pkgs.postgresql_15;
          })
        ];
      };

      # Helper function to generate a VM image from a NixOS configuration.
      mkVM = nodeConfig: nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        format = "qcow";
        modules = nodeConfig._module.args.modules ++ [
          {
            nix.registry.nixpkgs.flake = nixpkgs;
            virtualisation.diskSize = 20 * 1024;
          }
        ];
      };

    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        config = import config { inherit config; };

        # Choose version of PostgreSQL
        postgres = pkgs.postgresql_15;

      in {
        packages = {
          hapsql-tests = pkgs.testers.runNixOSTest ./hapsql-tests;
          vm1 = mkVM self.nixosConfigurations.node1vm;
          vm2 = mkVM self.nixosConfigurations.node2vm;
          vm3 = mkVM self.nixosConfigurations.node3vm;

          # This package builds all VM images at once
          vms = pkgs.symlinkJoin {
            name = "all-vms";
            paths = [
              self.packages.${system}.vm1
              self.packages.${system}.vm2
              self.packages.${system}.vm3
            ];
            postBuild = ''
              mkdir -p $out
              ln -s ${self.packages.${system}.vm1}/nixos.qcow2 $out/vm1.qcow2
              ln -s ${self.packages.${system}.vm2}/nixos.qcow2 $out/vm2.qcow2
              ln -s ${self.packages.${system}.vm3}/nixos.qcow2 $out/vm3.qcow2
            '';
          };
        };
        checks = config.packages // {
          hapsql-tests-interactive = config.packages.hapsql-tests.driverInteractive;
        };
        devShells.default = pkgs.mkShell {
          name = "plpgsql-dev";

          buildInputs = [
            postgres
            pkgs.pgcli # Optional: nice interactive CLI
          ];

          shellHook = ''
            echo "🛢️  Welcome to your PL/pgSQL dev environment"
            echo "🔧 psql version: $(psql --version)"
            echo "📁 Project directory: $PWD"
            export PGDATA=$PWD/pgdata
            export PGDATABASE=dev
            export PGUSER=dev
            export PGPASSWORD=dev
            export PGPORT=5433
          '';
        };
      }) // {
        nixosModules = {
          hapsql = ./modules/hapsql.nix;
          ssh-config = ./modules/ssh-config.nix;
        };

        nixosConfigurations = {
          # QEMU configs (Testing)
          node1 = mkNode ./node-configs/node1-qemu.nix;
          node2 = mkNode ./node-configs/node2-qemu.nix;
          node3 = mkNode ./node-configs/node3-qemu.nix;
          
          # VM configs (Deployment)
          node1vm = mkNode ./node-configs/node1.nix;
          node2vm = mkNode ./node-configs/node2.nix;
          node3vm = mkNode ./node-configs/node3.nix;
        };
      };
}