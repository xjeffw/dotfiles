# Unity on jeff-nixos

`jeff-nixos.nix` installs Unity Hub and a `unity-editor` launcher. Both use
Nixpkgs' Unity FHS environment, which supplies the libraries and filesystem
layout expected by Unity's downloaded Linux binaries.

The editor itself is managed by Hub in the user's home directory. To install
the version used by the launcher on a fresh system:

```sh
sudo nixos-rebuild switch
unityhub --headless install --version 6000.3.24f1
```

Open `unityhub`, sign in, and activate your Unity license. Then open or create
projects through Hub, or run:

```sh
unity-editor -projectPath /absolute/path/to/project
```

The launcher defaults to `~/Unity/Hub/Editor/6000.3.24f1/Editor/Unity`.
Set `UNITY_EDITOR_PATH` to another installed `Editor/Unity` executable to
select a different version or installation directory.

## Headless GUI verification

`bin/unity-headless` follows the private headless Sway approach in
`~/code/relay/headless/gui.sh`, with Xwayland enabled for Unity Editor.
It uses the real GPU and a private session bus and display; the default state
directory is `/tmp/unity-headless-$(id -u)`. It needs the host's `sway`,
`swaymsg`, `jq`, `dbus-run-session`, and `grim` commands.

```sh
bin/unity-headless start unity-editor \
  -createProject /tmp/unity-smoke-project \
  -logFile /tmp/unity-editor.log
bin/unity-headless status
bin/unity-headless shot /tmp/unity-editor.png
bin/unity-headless stop
```

Use a new project path for each `-createProject` test. To test Hub instead,
run `bin/unity-headless start unityhub`. `run COMMAND ARGS...` launches
another program inside an existing session. Set `UNITY_HEADLESS_DIR` to use
a separate session directory. With a tool runner that terminates background
processes on shell exit, keep the launching shell alive during inspection.

Verified on 2026-09-17: both NixOS switches succeeded; Hub 3.18.0 rendered its
sign-in window; Hub reported Editor 6000.3.24f1 installed successfully; and
`unity-editor -version` returned `6000.3.24f1`. The editor rendered its
first-run software terms window under Sway/Xwayland and connected to its
licensing client. Project creation remains unverified: the user must complete
first-run setup and activate a license (the startup log reported no editor
entitlement). Test screenshots and logs were saved in
`/tmp/unity-headless-1000/`.
