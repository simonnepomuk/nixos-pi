{ config, pkgs, lib, ... }:

let
  user = builtins.getEnv "NIXOS_USER";
  password = builtins.getEnv "NIXOS_PASSWORD";
  sshPubKey = builtins.getEnv "NIXOS_SSH_PUBKEY";
  SSID = builtins.getEnv "NIXOS_SSID";
  SSIDpassword = builtins.getEnv "NIXOS_SSID_PASSWORD";
  hostname = builtins.getEnv "NIXOS_HOSTNAME";
  ip = builtins.getEnv "CONTROL_NODE_IP";
  k3sToken = builtins.getEnv "K3S_TOKEN";
in {
  imports = ["${fetchTarball "https://github.com/NixOS/nixos-hardware/archive/d2d9a58a5c03ea15b401c186508c171c07f9c4f1.tar.gz" }/raspberry-pi/4"];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  networking = {
    firewall = {
      allowedTCPPorts = [ 6443 ];
      enable = true;
      trustedInterfaces = [ "cni0" ];
    };
    hostName = hostname;
    wireless = {
      enable = true;
      networks."${SSID}".psk = SSIDpassword;
      interfaces = [ "wlan0" ];
      interfaces.wlan0 = {
        useDHCP = false;
        ipv4.addresses = [{
          # I used static IP over WLAN because I want to use it as local DNS resolver
          address = ip;
          prefixLength = 24;
        }];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    k3s
    nano
    curl
  ];

  boot.kernelParams = [
    "cgroup_memory=1"
    "cgroup_enable=memory"
  ];

  services.k3s = {
    enable = true;
    role = "server";
    token = k3sToken;
    clusterInit = true;
  };

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };

  users = {
    mutableUsers = false;
    users."${user}" = {
      openssh.authorizedKeys.keys = [
        sshPubKey
      ];
      isNormalUser = true;
      password = password;
      extraGroups = [ "wheel" ];
    };
  };
}