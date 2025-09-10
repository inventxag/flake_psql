{
  networking.hostName = "node2";

  services.hapsql = {
    nodeIp = "192.168.100.11";
    partners = [ "192.168.100.10" "192.168.100.12" ];
  };
}