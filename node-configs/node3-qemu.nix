{
  networking.hostName = "node3";

  services.hapsql = {
    nodeIp = "192.168.100.12";
    partners = [
      "192.168.100.10"
      "192.168.100.11"
    ];
  };
}
