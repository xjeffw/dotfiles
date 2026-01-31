{ config, lib, pkgs, ... }:
with lib;
with lib.my;
let inherit (config) user host;
in {
  config = {
    home-manager.users.${user.name} = {
      home.packages = with pkgs; [ gh git-lfs ];

      programs.git = {
        enable = true;
        package = optimize config pkgs.git;
        userName = "${config.user.full-name}";
        userEmail = "${config.user.email}";
        lfs.enable = true;
        settings = {
          push.default = "current";
          pull.rebase = true;
          init.defaultBranch = "main";
          url."https://aur.archlinux.org/".insteadOf = "aur://";
          url."git@github.com:".insteadOf = "gh://";
          url."git@bitbucket.org:".insteadOf = "bb://";
          url."jeff@jeff-nixos:/home/jeff/".insteadOf = "jeff-nixos://";
          url."jeff@jeff-asahi:/home/jeff/".insteadOf = "jeff-asahi://";
          url."jeff@jeff-cloud.ddns.net:/git/".insteadOf = "jeff-cloud://";
          github.user = "jeffwkm";
        };
      };
    };
  };
}
