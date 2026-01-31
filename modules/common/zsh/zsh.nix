{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  inherit (lib.my) mkBoolOpt wrapOptimize;
  inherit (config) host user;
  inherit (config.host) darwin config-dir;
  pwd = "${config-dir}/modules/common/zsh";

  makeUserConfig = extra: {
    enable = true;
    sessionVariables = { };
    history = { };
    initExtraBeforeCompInit = "";
    envExtra = ''
      fpath+=( "${user.home}/.zsh/completions" )
    '';
    profileExtra = "";
    loginExtra = "";
    logoutExtra = "";

    prezto = {
      enable = true;
      pmodules = [
        "environment"
        "terminal"
        "editor"
        "history"
        "history-substring-search"
        "directory"
        "spectrum"
        "utility"
        "git"
        "node"
        "python"
        "archive"
        "completion"
        "fasd"
        "autosuggestions"
        "command-not-found"
        "prompt"
      ];
      pmoduleDirs = [ ./prompts ];
      prompt.theme = mkDefault "powerlevel10k";
      ssh.identities = [ "id_rsa" ];
      terminal.autoTitle = true;
      utility.safeOps = false;
      extraConfig = ''
        # zstyle ':prezto:module:terminal' auto-title 'always'
        zstyle ':prezto:module:terminal:window-title' format '%m: %s'
        zstyle ':prezto:module:terminal:tab-title' format '%m: %s'
        zstyle ':prezto:module:terminal:multiplexer-title' format '%s'
      '';
    };

    shellAliases = {
      _ = "sudo";
      __ = "sudo -i";
      dmesg = "sudo dmesg";
      top = "sudo btop";
      cat = "bat";
      cd = "z";
      ".." = "z ..";
      cdi = "zi";
      du = "du -h";
      f = "fzf";
      fI = "fzf --preview='timg -pk -g 60x80 -U -W {}'";
      e = "emacsclient -t -a emacs";
      ee = "emacs -nw";
      v = "vim";
      ### nix
      ss = "nix-search";
      ns = "nix search nixpkgs";
      nl = "nix-locate";
      wr = "which-realpath";
      wrd = "which-realpath-dir";
      wp = "which-package";
      ### tmux
      tmux = "tmux -2";
      tn = "tmux new-session -s";
      tl = "tmux list-sessions";
      ta = "tmux attach -t ";
      ### lsd
      lsd = "lsd --date relative";
      lsize = "sudo lsd --date relative --total-size";
      ls = "lsd --group-dirs first";
      ll = "ls -l";
      lr = "lsd --tree";
      lls = "lsize -l --blocks user,size,date,name";
      llS = "lsize -lSr";
      llt = "lsd -ltr --no-symlink --blocks permission,user,size,date,name";
      lt = "lsd -ltr --no-symlink --blocks size,date,name";
      ltr = "lsd -lt --no-symlink --blocks size,date,name";
      lts = "lsize -ltr --blocks size,date,name";
      l = "lsd -l --blocks user,size,date,name";
      l1 = "lsd -l1 --blocks name";
      lS = "lsize -l1 --blocks size,date,name --no-symlink";
      ldu = "lsize -lSr --blocks size,date,name";
      lduq = "lsize -lSr --blocks size,name --no-symlink";
      lst = "lsd --tree";
      lsd_help = ''alias | grep -Ee "(lsd|lsize |'ll |'lt )" | cat'';
      ### git
      gwS = "git status";
      gws = "gwS --untracked-files=no";
      gwsa = "gws --short";
      ### github (gh)
      ghs = "gh search";
      ghsr = "gh search repos";
      ghS = "gh status";
      ghr = "gh repo";
      ghrl = "gh repo list";
      ghrc = "gh repo clone";
      ghrC = "gh repo create";
      ghrf = "gh repo fork";
      ghrv = "gh repo view";
      ghrb = "gh repo view --web";
      ghb = "gh browse";
      gho = "gh org list";
      ### mpv
      mpvf = "mpv --input-ipc-server=";
      mpv-hlg = "mpv --icc-profile= --icc-profile-auto=no --target-trc=hlg --target-prim=bt.2020 --target-peak=1000 --hdr-compute-peak=no";
      # mpv2 = "mpv --icc-profile=~/.local/share/icc/p2715q.icc";
      ### misc
      sr-psql = "psql -h localhost -U postgres sysrev";
      sr-psql-any = "psql -h localhost -U postgres";
      sr-tunnels = ''
        open-tunnel ubuntu sysrev.com 5470 5432
        open-tunnel ubuntu staging.sysrev.com 5471 5432
      '';
      greg = "greg -cf ~/.greg.conf";
      H = "history -50000 | grep -i";
      n = "cd ${host.config-dir}";
      zsh-profile = "ZPROFILE=1 zsh -i -c exit";
    }
    // (extra.shellAliases or { });

    shellGlobalAliases = {
      _g = "| grep";
      _ge = "| grep -Ee";
      _gi = "| grep -i";
      _G = "| grep -iEe";
      _cl = "| wc -l";
      _cb = "| wc -c";
      _h = "| head -n";
      _t = "| tail -n";
      _l = "| less";
      EC2AUTH = "-O $AWS_ACCESS_KEY_ID -W $AWS_SECRET_ACCESS_KEY";
      # mpv options
      V50 = "--volume=50";
      FLOG = "--hwdec=auto --vf-clr --gamma=-14 --saturation=100 --contrast=40";
      SHF = "--shuffle";
      FS0 = "--fs --fs-screen=0";
      FS1 = "--fs --fs-screen=1";
      FS2 = "--fs --fs-screen=2";
      F24 = "--display-fps=24";
      HLG = "--target-trc=hlg --target-prim=bt.2020 --hdr-compute-peak=yes --tone-mapping=hable";
      SVP = "--input-ipc-server=/tmp/mpvsocket";
      NOSVP = "--input-ipc-server=";
      ICC = "--icc-profile-auto=yes";
      NOICC = "--icc-profile-auto=no";
    }
    // (extra.shellGlobalAliases or { });

    initExtraFirst = ''
      export USING_P10K=1

      [[ $TERM == "dumb" ]] && unsetopt zle && PS1='$ ' && return

      fpath+=( "${user.home}/.zsh/prompts" "${user.home}/.zsh/completions" )

      ${extra.initExtraFirst or ""}

      [[ -n "$ZPROFILE" ]] && zmodload zsh/zprof
    '';

    initExtra = ''
      if [[ "$USING_P10K" -eq 1 ]]; then
        if [[ -r "$HOME/.cache/p10k-instant-prompt-$USER.zsh" ]]; then
          source "$HOME/.cache/p10k-instant-prompt-$USER.zsh"
        fi
      fi

      [[ -n "$ZPROFILE" ]] && zprof

      if [[ "$USING_P10K" -ne 1 ]] ; then
        setopt PROMPT_CR
      fi
      setopt PROMPT_SP

      if [[ "$USING_P10K" -eq 1 ]]; then
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
        p10k finalize
      fi

      # Auto-reload ~/.zshrc when it changes
      if [[ -z "''${ZSHRC_AUTO_RELOAD_SETUP:-}" ]]; then
        ZSHRC_AUTO_RELOAD_SETUP=1

        _zshrc_mtime() {
          local rc="$1"
          # Use stat so we get the symlink's own mtime, not the target's.
          [[ -e $rc || -L $rc ]] || return 1
          command stat -c %Y -- "$rc" 2>/dev/null || return 1
        }

        ZSHRC_LAST_LOADED=$(_zshrc_mtime "$HOME/.zshrc" || true)
        export ZSHRC_LAST_LOADED

        autoload -Uz add-zsh-hook
        _zshrc_reload_if_changed() {
          local rc="$HOME/.zshrc" now
          now=$(_zshrc_mtime "$rc" || return)
          [[ -n ''${ZSHRC_LAST_LOADED:-} ]] || { ZSHRC_LAST_LOADED=$now; export ZSHRC_LAST_LOADED; return; }
          if (( now > ZSHRC_LAST_LOADED )); then
            ZSHRC_LAST_LOADED=$now
            export ZSHRC_LAST_LOADED
            source "$rc"
            print -r -- $'\e[1;92mReloaded ~/.zshrc\e[0m'
          fi
        }

        add-zsh-hook precmd _zshrc_reload_if_changed
      fi

      ${extra.initExtra or ""}
    '';
  };

  userLinuxConfig = makeUserConfig {
    shellAliases = {
      # ssh = "mosh";
      iotop = "sudo iotop";
      virsh = "VISUAL='emacs -nw' sudo -E virsh";
      ### systemctl
      sd = "sudo systemctl";
      sds = "sd status";
      sdr = "sd restart";
      ### systemctl --user
      sdu = "systemctl --user";
      sdus = "sdu status";
      sdur = "sdu restart";
      ### systemctl daemon-reload
      sdd = ''
        echo -n 'daemon-reload:'
        sudo systemctl daemon-reload
        echo -n ' [system]'
        systemctl --user daemon-reload
        echo -n ' [user]'
        echo'';
      ### cpupower
      cpinfo = "sudo cpupower frequency-info";
      cpgov = "sudo cpupower frequency-set -g";
    };
    initExtraFirst = ''
      export NIXOS=/etc/nixos
    '';
    initExtra = "";
  };

  userDarwinConfig = makeUserConfig {
    shellAliases = {
      brew = "/opt/homebrew/bin/brew";
      ibrew = "arch -x86_64 /usr/local/homebrew/bin/brew";
      mv = "/bin/mv";
    };
    initExtraFirst = "";
    initExtra = ''
      if [ -z $DISPLAY ]; then export DISPLAY=:0.0; fi
    '';
  };

  cfg = config.modules.zsh;
in
{
  options.modules.zsh.enable = mkBoolOpt true;

  config = mkIf cfg.enable {
    programs.zsh.enable = true;

    environment.shells = with pkgs; [
      zsh
      bash
    ];

    # programs.command-not-found.enable = !darwin;

    nixpkgs.overlays = [ (wrapOptimize config "zsh") ];

    home-manager.users.${user.name} =
      { config, pkgs, ... }:
      let
        link = config.lib.file.mkOutOfStoreSymlink;
      in
      {
        programs.zsh = (if darwin then userDarwinConfig else userLinuxConfig);
        programs.zoxide.enable = true;
        programs.fzf.enable = true;

        home.file.".zsh/prompts".source = ./prompts;
        home.file.".zsh/completions/_lsd".source = ./_lsd;
        home.file.".p10k.zsh".source = link "${pwd}/p10k.zsh";

        home.packages = with pkgs; [
          nix-zsh-completions
          zsh-better-npm-completion

          zsh-powerlevel10k
          starship
          powerline-go
          agkozak-zsh-prompt
        ];
      };
  };
}
