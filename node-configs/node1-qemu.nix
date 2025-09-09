{
  networking.hostName = "node1";

  services.hapsql = {
    nodeIp = "10.0.2.15";
    partners = [ "10.0.2.16" "10.0.2.17" ];
  };
}