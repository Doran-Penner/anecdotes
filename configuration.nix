{
	config,
	pkgs,
	lib,
	inputs,
	...
}: {
	imports = [
		# Include the results of the hardware scan.
		./hardware-configuration.nix
		# use the agenix system module
		inputs.agenix.nixosModules.default
	];

	# make actual encrypted files referencable by agenix
	age.identityPaths = ["${config.users.users.doran.home}/.ssh/id_ed25519"];
	age.secrets = {
		"restic/password".file = ./secrets/restic/password.age;
		"restic/repo-local".file = ./secrets/restic/repo-local.age;
		"restic/repo-remote".file = ./secrets/restic/repo-remote.age;
	};

	# add extra swap for ml building/running
	swapDevices = lib.mkAfter [
		{
			device = "/swapfile";
			size = 16 * 1024;	# a bit over 16GB
		}
	];

	boot.kernelPackages = pkgs.linuxPackages_6_18;

	# Bootloader.
	boot.loader.systemd-boot = {
		enable = true;
		# limit number of generations in bootloader so we don't run out of space
		configurationLimit = 50;
	};
	boot.loader.efi.canTouchEfiVariables = true;

	# Setup keyfile
	boot.initrd.secrets = {
		"/crypto_keyfile.bin" = null;
	};

	# Enable swap on luks
	boot.initrd.luks.devices."luks-2b96fe1e-6e3d-4517-8a62-fa4d6abbad57".device = "/dev/disk/by-uuid/2b96fe1e-6e3d-4517-8a62-fa4d6abbad57";
	boot.initrd.luks.devices."luks-2b96fe1e-6e3d-4517-8a62-fa4d6abbad57".keyFile = "/crypto_keyfile.bin";

	networking.hostName = "legionix";	# Define your hostname.

	# add caches
	nix.settings = {
		extra-substituters = [
			"https://nix-community.cachix.org"
			"https://cuda-maintainers.cachix.org"
		];
		extra-trusted-public-keys = [
			"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
			"cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
		];
	};

	# Enable networking
	networking.networkmanager.enable = true;

	# enable stuff for tailscale
	networking.nameservers = ["100.100.100.100" "8.8.8.8" "1.1.1.1" "194.242.2.2"];
	networking.search = ["coywolf-goldeye.ts.net"];	# can I hide this via age somehow?

	# enable bluetooth
	hardware.bluetooth.enable = true;

	# Set your time zone.
	time.timeZone = "America/Los_Angeles";

	# Select internationalisation properties.
	i18n.defaultLocale = "en_US.UTF-8";

	i18n.extraLocaleSettings = {
		LC_ADDRESS = "en_US.UTF-8";
		LC_IDENTIFICATION = "en_US.UTF-8";
		LC_MEASUREMENT = "en_US.UTF-8";
		LC_MONETARY = "en_US.UTF-8";
		LC_NAME = "en_US.UTF-8";
		LC_NUMERIC = "en_US.UTF-8";
		LC_PAPER = "en_US.UTF-8";
		LC_TELEPHONE = "en_US.UTF-8";
		LC_TIME = "en_US.UTF-8";
	};

	# enable KDE! (And try to disable xserver)
	services.xserver.enable = false;
	services.displayManager = {
		defaultSession = "plasma";
		sddm = {
			enable = true;
			wayland.enable = true;
		};
	};
	services.desktopManager.plasma6.enable = true;

	# enable ozone for some electron-based things
	environment.sessionVariables.NIXOS_OZONE_WL = "1";

	# Configure keymap in X11
	services.xserver.xkb = {
		layout = "us";
		variant = "";
	};

	# printing :(
	services.avahi = {
		enable = true;
		nssmdns4 = true;
		openFirewall = true;
	};

	services.printing = {
		enable = true;
		drivers = with pkgs; [
			cups-filters
			cups-browsed
		];
	};

	# udev rules (initially for keyboard stuff)
	services.udev.packages = [pkgs.via];

	# Enable sound with pipewire.
	services.pulseaudio.enable = false;
	security.rtkit.enable = true;
	services.pipewire = {
		enable = true;
		alsa.enable = true;
		alsa.support32Bit = true;
		pulse.enable = true;
	};

	# my main user account
	users.users.doran = {
		isNormalUser = true;
		description = "Doran Penner";
		extraGroups = ["networkmanager" "wheel"];
		shell = pkgs.fish;
		uid = 1000;
		# other config is in home.nix
	};

	# List packages installed in system profile.
	environment.systemPackages = with pkgs; [
		git
		(lutris.override {
			extraLibraries = pkgs: [
				wineWow64Packages.stable
			];
		})
		kdePackages.krohnkite
		kdePackages.karousel
	];

	# enable steam; if this has issues add steam-run to systemPackages instead
	# can I do steam in home-manager or does it work best with the nixos module?
	programs.steam = {
		enable = true;
		remotePlay.openFirewall = true;	# Open ports in the firewall for Steam Remote Play
		dedicatedServer.openFirewall = true;	# Open ports in the firewall for Source Dedicated Server
	};

	# customize available fonts
	fonts.packages = with pkgs; [
		nerd-fonts.jetbrains-mono
		nerd-fonts.monaspace
		b612
		comic-neue
		comic-relief
		corefonts	# unfree but necessary
		iosevka
		open-sans
		fira
		font-awesome
		atkinson-hyperlegible-next
		atkinson-hyperlegible-mono
	];

	# enable KDE Connect (can't get it to work in home-manager)
	# programs.kdeconnect.enable = true;

	# enable nix3 commands and flakes
	nix.settings.experimental-features = ["nix-command" "flakes" "ca-derivations"];

	# enable official nvidia drivers (https://nixos.wiki/wiki/Nvidia)
	hardware.graphics.enable = true;
	services.xserver.videoDrivers = ["nvidia"];
	hardware.nvidia = {
		# enable basic nvidia support
		modesetting.enable = true;
		open = true;
		nvidiaSettings = false;
		# NOTE this works for sus/res WAHOO don't touch anything as of nixpkgs rev
		# c8cfcd6ccd422e41cc631a0b73ed4d5a925c393d
		package = config.boot.kernelPackages.nvidiaPackages.production;

		# enable prime offloading
		prime = {
			offload = {
				enable = true;
				enableOffloadCmd = true;
			};
			amdgpuBusId = "PCI:6:0:0";
			nvidiaBusId = "PCI:1:0:0";
		};

		# (hopefully) fix suspend/resume issues
		powerManagement.enable = true;
		powerManagement.finegrained = true;

		# also some random stuff in case it does something
		dynamicBoost.enable = true;
	};

	# enable podman
	# virtualisation.podman.enable = true;
	# virtualisation.podman.enableNvidia = true;

	# enable nix-ld, hopefully fix python issues
	programs.nix-ld.enable = true;

	# enable fish (config in home-manager)
	programs.fish = {
		enable = true;
		useBabelfish = true;
	};

	# big thanks to <https://www.arthurkoziel.com/restic-backups-b2-nixos/>
	services.restic.backups = let
		home = config.users.users.doran.home;
		commonAttrs = {
			exclude = [
				"${home}/.local/share/containers/"
				"${home}/.cache/"
			];
			passwordFile = config.age.secrets."restic/password".path;
			paths = [home];
			extraBackupArgs = [
				"--verbose"
				"--exclude-caches"
			];
			pruneOpts = [
				"--keep-daily 7"
				"--keep-weekly 5"
				"--keep-monthly 12"
				"--keep-yearly 75"
			];
			timerConfig = {
				OnCalendar = "daily";
				Persistent = true;
				RandomizedDelaySec = "5h";
			};
			# this is the user on the *local* device, to reduce restic's perms;
			# but instead we're defaulting to root to avoide headaches
			# user = "doran";
			initialize = true;
		};
	in {
		local =
			commonAttrs
			// {
				repositoryFile = config.age.secrets."restic/repo-local".path;
			};
		remote =
			commonAttrs
			// {
				repositoryFile = config.age.secrets."restic/repo-remote".path;
				extraOptions = ["sftp.args='-i ${config.users.users.doran.home}/.ssh/id_ed25519'"];
			};
	};

	# send desktop notification on local backup failure
	systemd.services.restic-backups-local.unitConfig.OnFailure = "notify-backup-failed@local.service";
	systemd.services.restic-backups-remote.unitConfig.OnFailure = "notify-backup-failed@remote.service";
	systemd.services."notify-backup-failed@" = {
		enable = true;
		description = "Notify on failed backup";
		serviceConfig = {
			Type = "oneshot";
			User = config.users.users.doran.name;
		};

		# required for notify-send
		environment.DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${
			toString config.users.users.doran.uid
		}/bus";
		environment.MYRESTIC_REPO_NAME = "%i";

		# need to pass "hint" and maybe "app-name" for notif to persist in tray :/
		# <https://bbs.archlinux.org/viewtopic.php?id=252208>
		script = ''
			${pkgs.libnotify}/bin/notify-send --urgency=normal \
				--app-name=restic --hint=string:desktop-entry:org.wezfurlong.wezterm \
				"Backup failed for repo $MYRESTIC_REPO_NAME" \
				"$(${pkgs.systemd}/bin/journalctl -u restic-backups-$MYRESTIC_REPO_NAME -n 5 -o cat)"
		'';
	};
	# stop the remote service from running until tailscale and network is up
	systemd.services.restic-backups-remote.preStart = lib.mkBefore "${pkgs.coreutils}/bin/sleep 30";

	# set up tailscale
	services.tailscale = {
		enable = true;
		useRoutingFeatures = "client";
	};

	# syncthing
	services.syncthing = {
		enable = true;
		openDefaultPorts = true;
		# we get infinite recursion error if user = config.users.users.doran.name
		user = "doran";
		dataDir = config.users.users.doran.home;
	};

	# auto-optimize store every week
	nix.optimise = {
		automatic = true;
		dates = ["weekly"];
	};

	system.stateVersion = "23.05";	# for backwards compatibility; don't change unless you're sure!
}
