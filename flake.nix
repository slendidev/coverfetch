{
  description = "coverfetch";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachSystem nixpkgs.lib.systems.flakeExposed (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        python = pkgs.python313;
        source = pkgs.lib.cleanSourceWith {
          src = self;
          filter = path: type:
            let
              name = builtins.baseNameOf path;
            in
            !(
              name == ".direnv"
              || name == ".venv"
              || name == "__pycache__"
              || name == "result"
            );
        };

        coverfetch = python.pkgs.buildPythonApplication {
          pname = "coverfetch";
          version = "0.1.0";
          src = source;
          format = "pyproject";

          nativeBuildInputs = with python.pkgs; [ setuptools wheel ];
          propagatedBuildInputs = with python.pkgs; [ fastapi requests uvicorn ];
        };
      in
      {
        packages.default = coverfetch;

        apps.default = {
          type = "app";
          program = "${coverfetch}/bin/coverfetch";
        };

        devShells.default = pkgs.mkShell {
          venvDir = ".venv";

          postShellHook = ''
            venvVersionWarn() {
              local venvVersion
              venvVersion="$($venvDir/bin/python -c 'import platform; print(platform.python_version())')"

              [[ "$venvVersion" == "${python.version}" ]] && return

              cat <<EOF
            Warning: Python version mismatch: [$venvVersion (venv)] != [${python.version}]
                     Delete '$venvDir' and reload to rebuild for version ${python.version}
            EOF
            }

            venvVersionWarn
          '';

          packages =
            (with python.pkgs; [
              venvShellHook
              uv
              requests
              fastapi
              uvicorn
              setuptools
              wheel
            ])
            ++ (with pkgs; [ pyright ]);
        };
      }
    )
    // {
      nixosModules.default = import ./nix/nixos-module.nix { inherit self; };
    };
}
