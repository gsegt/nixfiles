{ hostname, remoteUnlock, ... }:

{
  boot.initrd = {
    availableKernelModules = remoteUnlock.networkKernelModules;
    network = {
      enable = true;
      ssh = {
        enable = true;
        port = 22;
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEf5Nt/JVAhptEaxDU/5Rdf284QswbVpKOOWFf7o5RAk"
        ];
        hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
      };
      postCommands = ''
        # Automatically ask for the password on SSH login
        echo 'cryptsetup-askpass || echo "Unlock was successful; exiting SSH session" && exit 1' >> /root/.profile
      '';
    };
  };
  boot.kernelParams = [
    "ip=${remoteUnlock.ip}::${remoteUnlock.gateway}:${remoteUnlock.mask}:${hostname}"
  ];
}
