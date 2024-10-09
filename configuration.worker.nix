{ config, pkgs, lib, ... }:

let
  user = builtins.getEnv "NIXOS_USER";
  password = builtins.getEnv "NIXOS_PASSWORD";
  sshPubKey = builtins.getEnv "NIXOS_SSH_PUBKEY";
  SSID = builtins.getEnv "NIXOS_SSID";
  SSIDpassword = builtins.getEnv "NIXOS_SSID_PASSWORD";
  hostname = builtins.getEnv "NIXOS_HOSTNAME";
  k8sApiServerAddr = "https://${builtins.getEnv "CONTROL_NODE_IP"}:6443";
  k8sApiServerToken = builtins.getEnv "K3S_TOKEN";
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
      enable = true;
      trustedInterfaces = [ "cni0" ];
    };
    hostName = hostname;
    wireless = {
      enable = true;
      networks."${SSID}".psk = SSIDpassword;
      interfaces = [ "wlan0" ];
    };
  };

  environment.systemPackages = with pkgs; [
    k3s
    vim
  ];

  boot.kernelParams = [
    "cgroup_memory=1"
    "cgroup_enable=memory"
  ];

  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = k8sApiServerAddr;
    token = k8sApiServerToken;
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