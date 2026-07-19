{
	description = "My NixOS configuration";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

		# for some things that need the absolute latest version
		unstable.url = "github:nixos/nixpkgs/nixos-unstable";

		home-manager.url = "github:nix-community/home-manager/release-26.05";
		home-manager.inputs.nixpkgs.follows = "nixpkgs";

		# for command-not-found support
		flake-programs-sqlite.url = "github:wamserma/flake-programs-sqlite";
		flake-programs-sqlite.inputs.nixpkgs.follows = "nixpkgs";

		# age[nix]
		agenix.url = "github:ryantm/agenix";
		agenix.inputs.nixpkgs.follows = "nixpkgs";

		# catppuccin for btop
		btop-themes.url = "github:catppuccin/btop";
		btop-themes.flake = false;

		# catppuccin for bat
		bat-themes.url = "github:catppuccin/bat";
		bat-themes.flake = false;
	};

	outputs = inputs @ {
		self,
		nixpkgs,
		unstable,
		home-manager,
		flake-programs-sqlite,
		agenix,
		btop-themes,
		bat-themes,
	}: let
		system = "x86_64-linux";
		pkgs = import nixpkgs {
			inherit system;
			config.allowUnfree = true;
			# TODO for zulip; remove when it's upgraded in nixpkgs (maybe upstream)
			# https://github.com/NixOS/nixpkgs/pull/526892
			config.permittedInsecurePackages = ["electron-39.8.10"];
		};
	in {
		nixosConfigurations.legionix = nixpkgs.lib.nixosSystem {
			inherit system pkgs;
			modules = [
				./configuration.nix
				agenix.nixosModules.default
			];
			specialArgs = {inherit inputs;};
		};
		homeConfigurations.doran = home-manager.lib.homeManagerConfiguration {
			inherit pkgs;
			modules = [
				./home.nix
				agenix.homeManagerModules.default
			];
			extraSpecialArgs = {inherit inputs;};
		};
	};
}
