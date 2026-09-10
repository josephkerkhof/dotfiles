{username, ...}: {
  networking.applicationFirewall = {
    allowSigned = true;
    allowSignedApp = true;
    blockAllIncoming = false;
    enable = true;
    enableStealthMode = false;
  };

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    watchIdAuth = true;
  };

  system.defaults = {
    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };

    dock = {
      autohide = true;
      tilesize = 48;
      "expose-group-apps" = true;
      "wvous-tl-corner" = 2;
    };

    finder = {
      FXPreferredViewStyle = "Nlsv";
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = false;
      ShowRemovableMediaOnDesktop = true;
    };

    screencapture = {
      disable-shadow = true;
      location = "/Users/${username}/Pictures/Screenshots";
      show-thumbnail = true;
      type = "png";
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
    };
  };
}
