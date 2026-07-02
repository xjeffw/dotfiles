{ config, lib, inputs, ... }:
with lib;
with lib.my;
let
  inherit (config) user host modules;
  inherit (modules) dev programs;
  cfg = programs.vscode;
  pwd = "${host.config-dir}/modules/common/programs";
in {
  options.modules.programs.vscode = {
    enable = mkBoolOpt (modules.desktop.enable && modules.dev.enable-all);
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = { config, pkgs, ... }:
      let link = config.lib.file.mkOutOfStoreSymlink;
      in {
        xdg.configFile = mkIf (!host.darwin) {
          "Cursor/User/settings.json".source =
            link "${pwd}/Cursor/settings.json";
          "Cursor/User/keybindings.json".source =
            link "${pwd}/Cursor/keybindings.json";
        };
        home.file = mkIf (host.darwin) {
          "Library/Application Support/Cursor/User/settings.json".source =
            link "${pwd}/Cursor/settings.json";
          "Library/Application Support/Cursor/User/keybindings.json".source =
            link "${pwd}/Cursor/keybindings.json";
        };
        programs.vscode = mkIf (!host.darwin) {
          enable = true;
          package = pkgs.vscode.fhsWithPackages (ps:
            with ps;
            [
              babashka
              direnv
              git
              # neovim
              nil
              nixfmt
              nodejs
              openssh
              openssl.dev
              pkg-config
              shellcheck
              shfmt
              zlib
              zsh
            ] ++ optionals dev.rust.enable [ rustup ]
            ++ optionals dev.jdk.enable [ clang-tools jdk maven ]
            ++ optionals dev.clojure.enable [
              boot
              clj-kondo
              clojure
              clojure-lsp
              leiningen
            ]);
        };
      };
  };
}
