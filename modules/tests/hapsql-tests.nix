{ self, ... }:
{
  perSystem =
    {
      self',
      lib,
      pkgs,
      ...
    }:
    {
      checks.hapsql-tests = self'.packages.hapsql-tests.driver;
      packages.hapsql-tests =
        let
          nodeNames = lib.genList (i: "psqlnode${toString (i + 1)}") 3;
          mkNode =
            name:
            { lib, pkgs, ... }:
            {
              imports = [ self.modules.nixos.hapsql ];
              services.hapsql = {
                enable = true;
                postgresqlPackage = pkgs.postgresql_15;
                nodeIp = name;
                partners = lib.filter (n: n != name) nodeNames;
              };
            };
        in
        pkgs.testers.runNixOSTest {
          name = "PostgreSQL HA Service Cluster Tests";
          nodes = lib.genAttrs nodeNames mkNode;

          testScript = builtins.readFile ./hapsql-tests.py;
        };
    };
}
