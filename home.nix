{
	config,
	pkgs,
	lib,
	inputs,
	...
}: {
	imports = [
		inputs.agenix.homeManagerModules.default
	];

	age.identityPaths = ["${config.home.homeDirectory}/.ssh/id_ed25519"];
	age.secrets = {
		reed = {
			file = ./secrets/ssh/reed.age;
			# dumb stuff a-la <https://discourse.nixos.org/t/ssh-config-as-agenix-secret/41096>
			path = "${config.home.homeDirectory}/.ssh/includes/ssh-config-reed";
		};
		rsync-net = {
			file = ./secrets/ssh/rsync-net.age;
			path = "${config.home.homeDirectory}/.ssh/includes/ssh-config-rsync-net";
		};
		csci-vm = {
			file = ./secrets/ssh/csci-vm.age;
			path = "${config.home.homeDirectory}/.ssh/includes/ssh-config-csci-vm";
		};
		miles = {
			file = ./secrets/ssh/miles.age;
			path = "${config.home.homeDirectory}/.ssh/includes/ssh-config-miles";
		};
	};

	home.username = "doran";
	home.homeDirectory = "/home/doran";

	# packages I want to install via hm
	home.packages = with pkgs; [
		hyperfine
		freesweep
		texlive.combined.scheme-full
		libreoffice
		prismlauncher
		vesktop
		ungoogled-chromium
		blender
		wl-clipboard-rs
		quarto
		typst
		# custom preview setup which is a bit annoying but less buggy than tinymist
		# <https://github.com/typst/typst/discussions/1981#discussioncomment-6804817>
		(writeShellScriptBin "ty-prev" ''
			__TYPREV_TMPFILE=$(${coreutils}/bin/mktemp --suffix .pdf)
			${typst}/bin/typst compile "$1" "$__TYPREV_TMPFILE"
			${typst}/bin/typst watch "$1" "$__TYPREV_TMPFILE" &
			${mupdf}/bin/mupdf-gl "$__TYPREV_TMPFILE" &
			${coreutils}/bin/echo "$__TYPREV_TMPFILE" | ${entr}/bin/entr ${procps}/bin/pkill -HUP mupdf
			${coreutils}/bin/rm "$__TYPREV_TMPFILE"
			${procps}/bin/pkill -P $$
		'')
		asciiquarium
		toipe
		dust
		mpv
		pandoc
		thunderbird
		kdePackages.kcalc
		speedtest-cli
		crawl
		crawlTiles
		via
		difftastic
		signal-desktop
		zip
		unzip
		bacon
		# jj config is in misc/jj.toml
		inputs.unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.jujutsu
		inputs.unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.jjui
		ov
		inputs.unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.zulip
		bitwarden-desktop
		shellcheck
	];

	# use "n" for shorthand of pinned system nixpkgs
	nix.registry.n.flake = inputs.nixpkgs;
	# and use "unstable" for explicit re-download
	nix.registry.unstable.to = {
		type = "github";
		repo = "nixpkgs";
		owner = "NixOS";
		ref = "nixos-unstable";
	};

	programs.firefox = {
		enable = true;
		nativeMessagingHosts = [
			pkgs.kdePackages.plasma-browser-integration
		];
		configPath = "${config.xdg.configHome}/mozilla/firefox";
	};

	programs.sioyek = {
		enable = true;
		bindings = {
			"screen_up" = "<pageup>";
			"screen_down" = "<pagedown>";
			"move_up" = "<backspace>";
			"move_down" = "<space>";
			"prev_state" = ["<S-<backspace>>" "<C-<left>>"];
			"next_state" = ["<S-<space>>" "<C-<right>>"];
		};
		config = {
			"startup_commands" = ["toggle_horizontal_scroll_lock"];
		};
	};

	programs.wezterm = {
		enable = true;
	};

	# use ghostty for dropdown terminal
	programs.ghostty = {
		enable = true;
		enableFishIntegration = true;
		settings = {
			theme = "Catppuccin Macchiato";
			# wonky on split monitor but naive % -> px translation doesn't work
			quick-terminal-size = "90%,90%";
			quick-terminal-position = "top";
			gtk-quick-terminal-layer = "overlay";
			# currently broken; see
			# https://github.com/ghostty-org/ghostty/discussions/9476
			# quick-terminal-autohide = true;
			keybind = [
				"global:alt+t=toggle_quick_terminal"
			];
		};
	};

	programs.btop = {
		enable = true;
		# change btop's LD_LIBRARY_PATH so it (always) shows gpu; guided by
		# <https://wiki.nixos.org/wiki/Nix_Cookbook#Wrapping_packages> and
		# <https://gist.github.com/CMCDragonkai/9b65cbb1989913555c203f4fa9c23374>
		package = pkgs.symlinkJoin {
			name = "btop";
			paths = [pkgs.btop];
			buildInputs = [pkgs.makeWrapper];
			postBuild = ''
				wrapProgram $out/bin/btop \
					--set LD_LIBRARY_PATH /run/opengl-driver/lib
			'';
		};
		settings = {
			# theme added in xdg.configFile
			color_theme = "catppuccin_mocha";
			vim_keys = true;
			update_ms = 2000;
			shown_boxes = "proc cpu mem net";
		};
	};

	programs.helix = {
		enable = true;
		extraPackages = with pkgs; [
			# markdown
			marksman
			# rust
			rust-analyzer
			# python (yay ruff!)
			ruff
			python312Packages.python-lsp-server
			# javascript
			typescript	# do I need this?
			typescript-language-server
			# nix
			nil
			# typst
			tinymist
			# latex :(
			texlab
			# go
			gopls
			# toml
			taplo
		];
		# settings are in misc/helix.toml so I can clone settings on other machines
		languages = {
			language = [
				{
					name = "python";
					language-servers = ["ruff" "pylsp"];
					auto-format = false;
				}
				{
					name = "nix";
					formatter.command = "${pkgs.alejandra}/bin/alejandra";
				}
				{
					name = "go";
					formatter.command = "${pkgs.go}/bin/gofmt";
				}
				{
					name = "rust";
					formatter.command = "${pkgs.rustfmt}/bin/rustfmt";
				}
				{
					name = "typst";
					formatter.command = "${pkgs.typstyle}/bin/typstyle";
					soft-wrap.enable = true;
					soft-wrap.wrap-at-text-width = true;
				}
				{
					name = "markdown";
					soft-wrap.enable = true;
					soft-wrap.wrap-at-text-width = true;
				}
				{
					name = "latex";
					soft-wrap.enable = true;
					soft-wrap.wrap-at-text-width = true;
				}
				{
					name = "quarto";
					soft-wrap.enable = true;
					soft-wrap.wrap-at-text-width = true;
				}
				# https://github.com/helix-editor/helix/discussions/7567
				{
					name = "text";
					scope = "source.default";
					roots = [];
					file-types = ["txt"];
					soft-wrap.enable = true;
					soft-wrap.wrap-at-text-width = true;
				}
			];
			language-server.ruff = {
				command = "ruff";
				args = ["server" "--preview"];
			};
		};
	};

	programs.tealdeer = {
		enable = true;
		settings.updates.auto_update = true;
	};

	programs.hyfetch = {
		enable = true;
		# wrap it to see fastfetch
		package = pkgs.symlinkJoin {
			name = "hyfetch";
			paths = [inputs.unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.hyfetch];
			buildInputs = [pkgs.makeWrapper];
			postBuild = ''
				wrapProgram $out/bin/hyfetch \
					--prefix PATH : ${pkgs.fastfetch}/bin
			'';
		};
		settings = {
			preset = "transfeminine";
			mode = "rgb";
			lightness = 0.5;
			color_align = {
				mode = "horizontal";
			};
			backend = "fastfetch";
			pride_month_disable = false;
		};
	};

	programs.fzf = {
		enable = true;
		enableFishIntegration = true;
		defaultCommand = "fd --type f";
	};

	programs.fd = {
		enable = true;
		hidden = true;
		ignores = [
			".git/"
			".jj/"
			".direnv/"
			"__pycache__/"
		];
	};

	programs.ripgrep.enable = true;

	programs.bat = {
		enable = true;
		config = {
			# theme added in xdg.configFile
			theme = "catppuccin-mocha";
			pager = "ov";
			wrap = "never";	# for ov
		};
	};

	programs.eza = {
		enable = true;
		enableFishIntegration = true;
		git = true;
		icons = "auto";
	};

	programs.zoxide = {
		enable = true;
		enableFishIntegration = true;
	};

	programs.atuin = {
		enable = true;
		enableFishIntegration = true;
		flags = ["--disable-up-arrow"];
		settings = {
			style = "compact";
			enter_accept = true;
		};
	};

	programs.fish = {
		enable = true;
		preferAbbrs = true;
		shellAbbrs = {
			l = "eza -lah";
			py = "python3";
			# still need to specify switch, boot, rollback, etc
			hm = "home-manager";
			# note: I manually created symlink from /etc/nixos to my config,
			# that way I don't need to specify --flake every time
			nixreb = "nixos-rebuild --sudo";
			dir-act = "echo \"use flake\" > .envrc && direnv allow .";
			welcome = "clear && hyfetch";
			zq = "zoxide query";
		};
		functions.theme = {
			description = "Convenient theme-switching on KDE";
			body = ''
				switch $argv
					case light
						set -f target org.kde.breeze.desktop
					case dark
						set -f target org.kde.breezedark.desktop
					case twilight
						set -f target org.kde.breezetwilight.desktop
				end
				if set -q target
					plasma-apply-lookandfeel -a $target
				else
					echo "Theme not found" >&2
					return 1
				end
			'';
		};
		plugins = [
			{inherit (pkgs.fishPlugins.git-abbr) name src;}
		];
		interactiveShellInit = ''
			set fish_greeting "Welcome back!"
			complete theme -xa "light dark twilight"
			${pkgs.bat-extras.batman}/bin/batman --export-env | source
		'';
	};

	programs.starship = {
		enable = true;
		enableFishIntegration = true;
		enableTransience = true;
		settings = {
			add_newline = false;
			cmd_duration.disabled = true;	# not certain
			shlvl = {
				disabled = false;
				format = "[$shlvl shells deep]($style) in ";
			};
			nix_shell = {
				heuristic = true;	# not sure if this is doing anything
				format = "via [$symbol]($style) ";
				symbol = "❄️";
			};
			direnv = {
				disabled = false;
				# slight hack to only display something if it's loaded
				format = "[$loaded]($style)";
				loaded_msg = "(direnv) ";
				unloaded_msg = "";
			};
			git_status = {
				# thanks to
				# https://github.com/spaceship-prompt/spaceship-prompt/issues/525#issuecomment-1494355353
				conflicted = "=$count ";
				ahead = "⇡$count ";
				behind = "⇣$count ";
				diverged = "⇡$ahead_count⇣$behind_count ";
				untracked = "?$count ";
				stashed = "\\$$count ";
				modified = "!$count ";
				staged = "+$count ";
				renamed = "»$count ";
				deleted = "✗$count ";
				typechanged = "🏳️‍⚧️$count ";	# <3
				format = "([\\[ $all_status$ahead_behind\\]]($style) )";	# added leading space
			};
		};
	};

	programs.direnv = {
		enable = true;
		nix-direnv.enable = true;
		config.global = {
			hide_env_diff = true;
			strict_env = true;
			warn_timeout = "0s";
			# not worth it to try messing with log colors
		};
	};

	programs.yazi = {
		enable = true;
		shellWrapperName = "y";
	};

	programs.git = {
		enable = true;
		settings = {
			user.email = "doranaviv@gmail.com";
			user.name = "Doran Penner";
			gpg.format = "ssh";
			init.defaultBranch = "main";
		};
		signing = {
			signByDefault = true;
			key = "/home/doran/.ssh/id_ed25519.pub";
		};
	};

	programs.delta = {
		enable = true;
		enableGitIntegration = true;
		options = {
			syntax-theme = "catppuccin-frappe";
		};
	};

	programs.ssh = {
		enable = true;
		# silly default config removed
		enableDefaultConfig = false;
		settings."*" = {
			ForwardAgent = false;
			# CHANGED
			AddKeysToAgent = "yes";
			Compression = false;
			ServerAliveInterval = 0;
			ServerAliveCountMax = 3;
			HashKnownHosts = false;
			UserKnownHostsFile = "~/.ssh/known_hosts";
			ControlMaster = "no";
			ControlPath = "~/.ssh/master-%r@%n:%p";
			ControlPersist = "no";
		};
		includes = [
			(lib.removePrefix "${config.home.homeDirectory}/.ssh/" config.age.secrets.reed.path)
			(lib.removePrefix "${config.home.homeDirectory}/.ssh/" config.age.secrets.rsync-net.path)
			(lib.removePrefix "${config.home.homeDirectory}/.ssh/" config.age.secrets.csci-vm.path)
			(lib.removePrefix "${config.home.homeDirectory}/.ssh/" config.age.secrets.miles.path)
		];
	};

	xdg = {
		enable = true;
		configFile = let
			# most direct files are symlinks for shorter edit->change latency
			symlink = config.lib.file.mkOutOfStoreSymlink;
			# NOTE this is the path where my config dir happens to be,
			# if that changes then I must update the code here
			confRoot = "${config.home.homeDirectory}/anecdotes";

			# define mergeable attrsets here, then direct files below

			# catppuccin themes for btop
			btopThemes = builtins.listToAttrs (builtins.map (theme: {
				name = "btop/themes/catppuccin_${theme}.theme";
				value = {source = "${inputs.btop-themes}/themes/catppuccin_${theme}.theme";};
			}) ["latte" "frappe" "macchiato" "mocha"]);

			# catppuccin themes for bat
			batThemes = builtins.listToAttrs (builtins.map (theme: {
				# unsure if I should name the files this way, but it works so whatever
				name = "bat/themes/catppuccin-${lib.toLower theme}.tmTheme";
				value = {
					source = "${inputs.bat-themes}/themes/Catppuccin\ ${theme}.tmTheme";
				};
			}) ["Latte" "Frappe" "Macchiato" "Mocha"]);
		in
			btopThemes
			// batThemes
			// {
				# for my convenience to not have to specify conf location
				"home-manager".source = symlink "${confRoot}";
				"ov/config.yaml".source = symlink "${confRoot}/misc/ov.yaml";
				"jj/config.toml".source = symlink "${confRoot}/misc/jj.toml";
				"jjui/config.toml".source = symlink "${confRoot}/misc/jjui.toml";
				"helix/config.toml".source = symlink "${confRoot}/misc/helix.toml";
				"wezterm/wezterm.lua".source = symlink "${confRoot}/misc/wezterm.lua";
			};
	};

	home.sessionVariables = {
		# set bat as the "default" env var pager
		# and bat's config makes it use ov as the actual pager
		PAGER = "bat -p";
		EDITOR = "hx";
		VISUAL = "hx";
	};

	programs.command-not-found = {
		enable = true;
		dbPath = inputs.flake-programs-sqlite.packages.${pkgs.stdenv.hostPlatform.system}.programs-sqlite;
	};

	manual.html.enable = true;
	manual.json.enable = true;
	manual.manpages.enable = true;

	home.stateVersion = "23.05";

	# Let Home Manager install and manage itself.
	programs.home-manager.enable = true;
}
