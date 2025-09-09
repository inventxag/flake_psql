{
  networking.hostName = "node2";

  services.hapsql = {
    nodeIp = "10.0.2.16";
    partners = [ "10.0.2.15" "10.0.2.17" ];
  };
}