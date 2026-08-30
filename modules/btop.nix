{ lib, ... }:
{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = lib.mkDefault "Default";
      theme_background = false;
      vim_keys = true;
      update_ms = 2000;
      proc_sorting = "cpu lazy";
      proc_tree = false;
      proc_per_core = true;
      show_coretemp = true;
      temp_scale = "celsius";
      show_cpu_freq = true;
      clock_format = "%X";
      background_update = true;
      shown_boxes = "cpu mem net proc";
    };
  };
}
