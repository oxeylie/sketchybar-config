{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    sbarlua = {
      url = "github:FelixKratz/SbarLua";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, ... }:
    let
      system = "aarch64-darwin";

      /*
        sbarlua-derivation =
        { pkgs, inputs, ... }:
        pkgs.stdenv.mkDerivation {
          name = "sbarlua";

          src = inputs.sbarlua;

          nativeBuildInputs = [
            pkgs.gcc
          ];

          buildInputs = [
            pkgs.readline
          ];

          installPhase = ''
            mkdir -p $out/lib/sketchybar
            cp bin/sketchybar.so $out/lib/sketchybar/
          '';
        };
      */

      pkgs = import nixpkgs {
        inherit system;
        /*
          overlays = [
            (self: super: {
              sbarlua = super.callPackage sbarlua-derivation { inherit inputs; };
            })
          ];
        */
      };

    in
    {
      packages."${system}".sbarlua = pkgs.sbarlua;

      devShells."${system}".default = pkgs.mkShell {
        packages = with pkgs; [
          sketchybar
          lua5_5
          sbarlua
        ];

        shellHook = ''
          export SKETCHYBAR_LUA_PATH="${pkgs.sbarlua}/lib/lua/5.4/"
          #ln -sf ${pkgs.sketchybar-app-font}/bin/icon_map.sh ./helpers/icon_map.sh 

          cat > .zsh-shell <<'EOF'
          TRAPEXIT() {
            rm -rf .zsh-shell
          }
          EOF

          exec ${pkgs.zsh}/bin/zsh --rcs -i -c "source .zsh-shell; ${pkgs.zsh}/bin/zsh -i"
        '';
      };
    };
}
