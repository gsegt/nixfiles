{ pkgs, ... }:

{
  users.users.acer = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "changeme";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwPeKHdo/JDZ4TsrOVzgY2mEjTi1vL6UZzJ4ulaJpaY"
    ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true; # Needs to be installed system wide for user to login

  security.sudo.extraRules = [
    {
      users = [ "acer" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
