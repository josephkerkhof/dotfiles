{config, ...}: {
  home.file.".ideavimrc" = {
    force = true;
    text = ''
      set scrolloff=5
      set incsearch
      map Q gq

      Plug 'machakann/vim-highlightedyank'
      Plug 'tpope/vim-commentary'
    '';
  };

  programs = {
    htop = {
      enable = true;
      settings = {
        hide_kernel_threads = true;
        hide_userland_threads = false;
        hide_running_in_container = false;
        shadow_other_users = false;
        show_thread_names = false;
        show_program_path = true;
        highlight_base_name = false;
        highlight_deleted_exe = true;
        shadow_distribution_path_prefix = false;
        highlight_megabytes = true;
        highlight_threads = true;
        highlight_changes = false;
        highlight_changes_delay_secs = 5;
        find_comm_in_cmdline = true;
        strip_exe_from_cmdline = true;
        show_merged_command = false;
        header_margin = true;
        screen_tabs = true;
        detailed_cpu_time = false;
        cpu_count_from_one = false;
        show_cpu_usage = true;
        show_cpu_frequency = false;
        show_cached_memory = true;
        update_process_names = false;
        account_guest_in_cpu_meter = false;
        color_scheme = 0;
        enable_mouse = true;
        delay = 15;
        hide_function_bar = false;
        header_layout = "two_50_50";
        column_meters_0 = [
          "LeftCPUs2"
          "Memory"
          "Swap"
        ];
        column_meter_modes_0 = [
          1
          1
          1
        ];
        column_meters_1 = [
          "RightCPUs2"
          "Tasks"
          "LoadAverage"
          "Uptime"
        ];
        column_meter_modes_1 = [
          1
          2
          2
          2
        ];
        tree_view = false;
        sort_key = config.lib.htop.fields.PERCENT_CPU;
        tree_sort_key = config.lib.htop.fields.PID;
        sort_direction = -1;
        tree_sort_direction = 1;
        tree_view_always_by_pid = false;
        all_branches_collapsed = false;
      };
    };

    jujutsu.enable = true;
  };

  xdg.configFile.htop.force = true;
}
