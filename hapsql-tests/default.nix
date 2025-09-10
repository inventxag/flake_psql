{
  name = "PostgreSQL HA Service Cluster Test";

  nodes = {
    psqlnode1 = { config, pkgs, ... }: {
      imports = [ ../modules/hapsql.nix ];

      networking.firewall.enable = false;

      users.users.root.password = "root";
      services.getty.autologinUser = "root";

      environment.systemPackages =
        builtins.attrValues { inherit (pkgs) curl nettools; };

      services.hapsql = {
        enable = true;
        nodeIp = "psqlnode1";
        partners = [ "psqlnode2" "psqlnode3" ];
        postgresqlPackage = pkgs.postgresql_15;
      };
    };
    psqlnode2 = { config, pkgs, ... }: { # TODO: parametrize this config so we don't repeat ourselves as much
      imports = [ ../modules/hapsql.nix ];

      networking.firewall.enable = false;

      users.users.root.password = "root";
      services.getty.autologinUser = "root";

      environment.systemPackages =
        builtins.attrValues { inherit (pkgs) curl nettools; };

      services.hapsql = {
        enable = true;
        nodeIp = "psqlnode2";
        partners = [ "psqlnode1" "psqlnode3" ];
        postgresqlPackage = pkgs.postgresql_15;
      };
    };
    psqlnode3 = { config, pkgs, ... }: { # TODO: parametrize this config so we don't repeat ourselves as much
      imports = [ ../modules/hapsql.nix ];

      networking.firewall.enable = false;

      users.users.root.password = "root";
      services.getty.autologinUser = "root";

      environment.systemPackages =
        builtins.attrValues { inherit (pkgs) curl nettools; };

      services.hapsql = {
        enable = true;
        nodeIp = "psqlnode3";
        partners = [ "psqlnode1" "psqlnode2" ];
        postgresqlPackage = pkgs.postgresql_15;
      };
    };
  };

  testScript = { nodes, ... }: ''
    start_all()

    for node in [ psqlnode1, psqlnode2 ]:
        node.systemctl("start network-online.target")
        node.wait_for_unit("network-online.target")
        node.wait_for_unit("patroni.service")

    psqlnode1.succeed("ping -c 1 psqlnode2")
    psqlnode2.succeed("ping -c 1 psqlnode1")

    # TODO: Test posgres service connectivity between nodes and stuff
  '';
}
