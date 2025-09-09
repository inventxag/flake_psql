{ ... }:
{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        name = "plpgsql-dev";

        buildInputs = [
          pkgs.postgresql_17
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
    };
}
