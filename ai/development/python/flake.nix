{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";

    flake-parts.url = "github:hercules-ci/flake-parts";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ flake-parts, ... }:
  # https://flake.parts/module-arguments.html
    flake-parts.lib.mkFlake { inherit inputs; } (top@{ config, withSystem, moduleWithSystem, ... }: {
      imports = [
        # Optional: use external flake logic, e.g.
        # inputs.foo.flakeModules.default
        inputs.devenv.flakeModule

      ];
      flake = {
        # Put your original flake attributes here.
      };
      systems = [
        # systems for which you want to build the `perSystem` attributes
        "x86_64-linux"
        # ...
      ];
      perSystem = { config, pkgs, lib, system, ... }: let
        # Use pyproject-nix to build the Python base
        pythonBase = pkgs.callPackage inputs.pyproject-nix.build.packages {
          python = pkgs.python3;
        };

        # Load the uv2nix workspace
        workspace = inputs.uv2nix.lib.workspace.loadWorkspace {workspaceRoot = ./.;};

        # Create overlays for dependencies and build systems
        overlay = workspace.mkPyprojectOverlay {
          sourcePreference = "wheel";
        };

        pythonSet = pythonBase.overrideScope (
          lib.composeManyExtensions [
            inputs.pyproject-build-systems.overlays.wheel
            overlay
          ]
        );

        # Build the virtual environment
        virtualenv = pythonSet.mkVirtualEnv "dev-env" workspace.deps.default;

      in {
        _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
            config.cudaSupport = false;
        };          

        formatter = pkgs.alejandra;
        devenv.shells.default = import ./nix/devenv.nix {
          inherit virtualenv pkgs;
        };
      };
  });
}
