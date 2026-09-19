{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";

    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: let
    systems = ["x86_64-linux"];
  in
    inputs.flake-utils.lib.eachSystem systems (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      # sources = import ./npins;
    in {
      formatter = pkgs.alejandra;

      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
        ];
      };
    })
    // {
      templates = rec {
        default = generic;

        generic = {
          path = ./generic;
          description = "generic template";
        };

        containers-docker = {
          path = ./containers/docker;
          description = "Template to allow for docker containers being built by nixos";
        };

        frontend-typescript-bun-svelte = {
          path = ./frontend/typescript/bun-svelte;
          description = "typescript-bun-svelte template";
        };

        fullstack-python-typescript = {
          path = ./fullstack/python-typescript;
          description = "fullstack applications built on python and typescript";
        };

        backend-python = {
          path = ./backend/python;
          description = "backend applications built on python";
        };

        ## AI ##
        python-llm = {
          path = ./ai/development/python;
          description = "this template is intended to create AI applications (such mcp) with python";
        };

        coding-agent = {
          path = ./ai/agents/coding-agent;
          description = "Basic files to use alongside armandociii/coding-agent";
        };

        ## Docs ##
        docs-mkdocs-material = {
          path = ./documentation/mkdocs-material;
          description = "mkdocs-material template";
        };
        
        zig-generic = {
          path = ./zig/generic;
          description = "generic zig template";
        };
      };
    };
}
