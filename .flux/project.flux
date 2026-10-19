{
  :build-commands
    [
      {:command "sudo nixos-rebuild build", :name "build"}
      {:command "sudo nixos-rebuild switch", :name "switch"}
      {
        :command "./update-claude-code.sh"
        :name "update-claude-code.sh"
      }
    ]
  :test-commands []
}
