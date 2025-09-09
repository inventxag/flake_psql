


# local setup with vmm / virsh

```
# Create network XML file (10.0.2.0-network.xml)
cat > 10.0.2.0-network.xml << EOF
<network>
  <name>custom-10-0-2</name>
  <forward mode='nat'/>
  <bridge name='virbr1' stp='on' delay='0'/>
  <ip address='10.0.2.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='10.0.2.2' end='10.0.2.254'/>
    </dhcp>
  </ip>
</network>
EOF

# Define and start the network
virsh net-define 10.0.2.0-network.xml
virsh net-start custom-10-0-2
virsh net-autostart custom-10-0-2


# build vms disk images
nix build .#vms

# copy or add write permissions to images and import in vmm with proper network


```