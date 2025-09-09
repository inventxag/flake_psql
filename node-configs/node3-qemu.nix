{
  networking.hostName = "node3";

  services.hapsql = {
    nodeIp = "10.0.2.17";
    partners = [ "10.0.2.15" "10.0.2.16" ];
  };
}