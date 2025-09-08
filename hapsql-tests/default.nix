{
  name = "Echo Service Test Z";

  nodes = {
    node1 = { config, pkgs, ... }: {
      imports = [ ../modules/hapsql.nix ];

      environment.systemPackages =
        builtins.attrValues { inherit (pkgs) curl nettools; };

      services.hapsql = {
        enable = true;
        nodeIp = "10.0.2.15";
        partners = [ "10.0.2.16" "10.0.2.17" ];
        postgresqlPackage = pkgs.postgresql_15;
      };
    };
    node2 = { config, pkgs, ... }: {
      imports = [ ../modules/hapsql.nix ];

      environment.systemPackages =
        builtins.attrValues { inherit (pkgs) curl nettools; };

      services.hapsql = {
        enable = true;
        nodeIp = "10.0.2.16";
        partners = [ "10.0.2.15" "10.0.2.17" ];
        postgresqlPackage = pkgs.postgresql_15;
      };
    };
  };

  # interactive.sshBackdoor.enable = true;
  # enableDebugHook = true;

  # globalTimeout = 200;

  # interactive.nodes.server = import ../debug-host-module.nix;

  testScript = { nodes, ... }: ''

    PATRONI_PORT = "8008"

    start_all()
  '';
}
