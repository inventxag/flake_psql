{
  config,
  lib,
  ...
}:
let
  cfg = config.services.hapsql;
in
{
  options.services.hapsql = {
    enable = lib.mkEnableOption "HA PostgreSQL";

    postgresqlPackage = lib.mkOption {
      type = lib.types.package;
    };

    nodeIp = lib.mkOption {
      type = lib.types.str;
    };

    partners = lib.mkOption {
      type = lib.types.listOf lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    services.patroni = {
      enable = true;
      postgresqlPackage = cfg.postgresqlPackage;
      name = config.networking.hostName;
      scope = "my-ha-postgres";
      nodeIp = cfg.nodeIp;

      settings = {
        restapi = {
          listen = "0.0.0.0:8008";
          connect_address = "${cfg.nodeIp}:8008";
        };
        raft = {
          data_dir = "/var/lib/patroni/raft-${config.services.patroni.scope}";
          self_addr = "${cfg.nodeIp}:5010";
          partner_addrs = map (ip: "${ip}:5010") cfg.partners;
        };
        bootstrap = {
          dcs = {
            ttl = 30;
            loop_wait = 10;
            retry_timeout = 10;
            maximum_lag_on_failover = 1048576;
            postgresql = {
              use_pg_rewind = true;
              use_slots = true;
              parameters = {
                wal_level = "replica";
                hot_standby = "on";
                max_wal_senders = 10;
                max_replication_slots = 10;
                wal_keep_segments = 100;
                archive_mode = "on";
                archive_command = "test ! -f /var/lib/postgresql/archive/%f && cp %p /var/lib/postgresql/archive/%f";
              };
            };
          };
          initdb = [
            "encoding=UTF-8"
            "data-checksums"
          ];
          pg_hba = [
            "host replication replicator 0.0.0.0/0 md5"
            "host replication replicator ::0/0 md5"
            "host all all 0.0.0.0/0 md5"
            "host all all ::0/0 md5"
          ];
          # pg_hba = [
          #   "host replication replicator 127.0.0.1/32 md5"
          #   "host replication replicator ${cfg.nodeIp} md5"

          # ]
          # ++ map (ip: "host replication replicator ${ip} md5") cfg.partners
          # ++ [ "host all all 0.0.0.0/0 md5" ];
          users = {
            admin = {
              password = "admin"; # TODO: move to secret config
              options = [
                "createrole"
                "createdb"
              ];
            };
          };
        };
        postgresql = {
          authentication = {
            replication = {
              username = "replicator";
              password = "admin@123";
            };
            superuser = {
              username = "postgres";
              password = "admin@123";
            };
          };
          parameters = {
            unix_socket_directories = "/tmp";
          };
        };
        tags = {
          nofailover = false;
          noloadbalance = false;
          clonefrom = false;
          nosync = false;
        };
      };
    };
  };
}
