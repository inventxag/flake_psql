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
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        config = import config { inherit config; };

        # Choose version of PostgreSQL
        postgres = pkgs.postgresql_15;

      in {
        packages = { hapsql-tests = pkgs.testers.runNixOSTest ./hapsql-tests; };
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

        nixosConfigurations.node1 = nixpkgs.lib.nixosSystem {
          modules = [
            ./node.nix
            self.nixosModules.hapsql
            self.nixosModules.ssh-config
            ({ pkgs, ... }: {
              services.hapsql.postgresqlPackage = pkgs.postgresql_15;
            })
          ];
        };

        vm = nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          format = "qcow";

          modules = self.nixosConfigurations.node1._module.args.modules ++ [
            {
              # Pin nixpkgs to the flake input, so that the packages installed
              # come from the flake inputs.nixpkgs.url.
              nix.registry.nixpkgs.flake = nixpkgs;
              # set disk size to to 20G
              virtualisation.diskSize = 20 * 1024;
            }

            # You can add more modules here
            #./vm-specific-config.nix
          ];
        };

      };
}
