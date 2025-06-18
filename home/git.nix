{
  programs.git = {
    enable = true;
    userName = "gsegt";
    userEmail = "git@gsegt.eu";
    # Sections are to mimic the final configuration
    extraConfig = {
      core = {
        autocrlf = "input";
        eol = "lf";
      };
      init = {
        defaultBranch = "main";
      };
      pull = {
        rebase = "true";
      };
      rebase = {
        autostash = "true";
      };
    };
  };
}
