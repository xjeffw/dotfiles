{ config, lib, pkgs, ... }:
with lib;
with lib.my;
let
  inherit (config) user host modules;
  inherit (host) darwin;
  pwd = "${host.config-dir}/modules/common/programs/neovim";
  cfg = modules.programs.neovim;
  llvmPackages = pkgs.llvmPackages_18;
  clang = llvmPackages.clang;
in {
  options.modules.programs.neovim.enable = mkBoolOpt true;

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = { config, pkgs, ... }: {
      programs.neovim = {
        enable = true;
        viAlias = true;
        vimAlias = true;
        extraPackages = with pkgs;
          with llvmPackages;
          [ gnumake pkg-config luarocks ] ++ optional darwin clang
          ++ optional (!darwin) gcc;
      };

      home.packages = with pkgs; [ luarocks neovide lua-language-server ];

      xdg.configFile."nvim/".source = ./config;
        # config.lib.file.mkOutOfStoreSymlink "${pwd}/config";
    };
  };
}
