{
  networking.hostName = "node3";
  networking = {
    interfaces.enp1s0 = {
      ipv4.addresses = [{
        address = "10.0.2.17";
        prefixLength = 24;
      }];
    };
    defaultGateway = "10.0.2.1";
    firewall.allowedTCPPorts = [ 5010 8008 ];
  };

  services.hapsql = {
    nodeIp = "10.0.2.17";
    partners = [ "10.0.2.15" "10.0.2.16" ];
  };
}
