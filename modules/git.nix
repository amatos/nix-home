{ ... }: {
  programs.git = {
    enable = true;
    package = null;
    settings.user = {
      name = "Alberth Matos";
      email = "alberth@matos.cc";
    };
  };
}
