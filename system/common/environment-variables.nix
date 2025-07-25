{
  environment.sessionVariables = rec {
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";

    # Not officially in the specification
    XDG_BIN_HOME = "$HOME/.local/bin"; # Path is extended in the fish shell init to avoid conflicts with multiple PATH definitions
  };

  # Directories are created with default permissions and ownership with no cleanup timer
  systemd.user.tmpfiles.rules = [
    "d %h/.cache - - - -"
    "d %h/.config - - - -"
    "d %h/.local/share - - - -"
    "d %h/.local/state - - - -"
    "d %h/.local/bin - - - -"
  ];
}
