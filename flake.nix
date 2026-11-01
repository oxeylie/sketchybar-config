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

      pkgs = import nixpkgs {
        inherit system;

        overlays = [
          (final: prev: {
            sketchybar = prev.sketchybar.overrideAttrs (old: {
              postPatch = (old.postPatch or "") + ''
                sed -i '296s/kCGStatusWindowLevel/kCGPopUpMenuWindowLevel/' src/bar_manager.c
                sed -n '296p' src/bar_manager.c   # shows the result in the build log
              '';
            });
          })
        ];

      };

    in
    {
      packages."${system}" = pkgs;

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
