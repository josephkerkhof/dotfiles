{inputs, ...}: {
  imports = [inputs.private-assets.darwinModules.homestar];

  # Resolve every *.test name to loopback through DNS, as Herd's dnsmasq did.
  # /etc/hosts is a symlink into /nix/store here, and Chrome's sandbox cannot
  # read it, so local sites must come from DNS.
  services.dnsmasq = {
    enable = true;
    addresses.test = "127.0.0.1";
  };

  environment.etc.hosts.text = ''
    ##
    # Host Database
    #
    # localhost is used to configure the loopback interface
    # when the system is booting.  Do not change this entry.
    ##
    127.0.0.1 localhost
    255.255.255.255 broadcasthost
    ::1 localhost
  '';
}
