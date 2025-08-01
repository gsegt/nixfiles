{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-server.url = "github:NixOS/nixpkgs/nixos-25.05-small";
    home-manager-server = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs-server";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixos-wsl,
      nixpkgs-server,
      home-manager-server,
      ...
    }:
    let
      timezone = "Europe/Paris";
      hostModule = specialArgs: ./system/hosts/${specialArgs.hostname};
      homeManagerModule = specialArgs: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = specialArgs;
        home-manager.users.${specialArgs.username} = import ./home/hosts/${specialArgs.hostname};
      };
    in
    {
      nixosConfigurations.wsl = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = {
          username = "gsegt";
          hostname = "wsl";
        };
        modules = [
          home-manager.nixosModules.home-manager
          nixos-wsl.nixosModules.wsl
          (hostModule specialArgs)
          (homeManagerModule specialArgs)
        ];
      };
      nixosConfigurations.aspire = nixpkgs-server.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = {
          username = "acer";
          hostname = "aspire";
          timezone = timezone;
          remoteUnlock = {
            networkKernelModules = [ "r8169" ];
            ip = "192.168.1.252";
            gateway = "192.168.1.254";
            mask = "255.255.255.0";
          };
          zfsExtraPools = [ "data-vault" ];
        };
        modules = [
          home-manager-server.nixosModules.home-manager
          (hostModule specialArgs)
          (homeManagerModule specialArgs)
        ];
      };
    };
}
