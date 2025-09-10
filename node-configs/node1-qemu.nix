{
  networking.hostName = "node1";

  services.hapsql = {
    nodeIp = "192.168.100.10";
    partners = [ "192.168.100.11" "192.168.100.12" ];
  };
}