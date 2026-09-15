{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.workstation.obs;

  canvas = {
    width = 3840;
    height = 2160;
  };

  # Camera inset: 22% of the canvas width, 16:9, 64 px from the corner.
  camera = {
    width = 848;
    height = 477;
    margin = 64;
  };

  cameraMask = pkgs.runCommand "obs-camera-mask" {nativeBuildInputs = [pkgs.imagemagick];} ''
    mkdir -p "$out"
    magick -size 1920x1080 xc:none -fill white \
      -draw "roundrectangle 0,0,1919,1079,96,96" "$out/camera-mask.png"
  '';

  uuids = {
    backdrop = "dfecff9d-106c-4ba3-98c2-b9893284c84b";
    display = "712ae2a3-5b78-4540-a8dd-c5247544b947";
    window = "bb13830e-092a-4d14-901c-a7c190ec6d5c";
    camera = "aa684550-0367-4493-a361-9d6a99e1cf85";
    cameraMask = "a29120b9-98ab-43e4-903e-24fcfb496da9";
    systemAudio = "dd6b6fd2-1d23-403c-8056-f2da5c6b1743";
    mic = "bf10fc96-4471-4f44-9c05-fa2a7554c8a3";
    micNoise = "b0e868a2-80c8-433e-922c-8ee5d6d49375";
    micCompressor = "af49a813-756c-46cc-a3ec-f51cc3b85b11";
    micLimiter = "f39e3e65-7fcd-4d2f-8972-8c784c75bf52";
    sceneCode = "4339ece7-a772-414c-89dc-b803afc5e216";
    sceneCodeOnly = "8b96645d-0475-4476-b3d9-128df0b80e55";
    sceneCamera = "07affe1e-5980-48b4-8210-901bf8df72bf";
    sceneWindow = "8f42103f-33af-4fd6-9e09-535dc87c7f29";
  };

  # Audio track bitmask: 1 = mic, 2 = system audio, 4 = mixed.
  tracks = {
    mic = 1 + 4;
    system = 2 + 4;
  };

  mkFilter = {
    name,
    uuid,
    id,
    settings,
  }: {
    inherit name uuid id settings;
    versioned_id = id;
    enabled = true;
  };

  mkSource = {
    name,
    uuid,
    id,
    settings ? {},
    filters ? [],
    mixers ? 0,
  }:
    {
      inherit name uuid id settings mixers;
      versioned_id = id;
      enabled = true;
      muted = false;
      volume = 1.0;
      balance = 0.5;
      sync = 0;
      flags = 0;
      monitoring_type = 0;
      deinterlace_mode = 0;
      deinterlace_field_order = 0;
      push-to-mute = false;
      push-to-mute-delay = 0;
      push-to-talk = false;
      push-to-talk-delay = 0;
      hotkeys = {};
      private_settings = {};
    }
    // lib.optionalAttrs (filters != []) {inherit filters;};

  # Items fit inside `bounds` (scale inner), so any source resolution works.
  mkItem = {
    id,
    name,
    uuid,
    x,
    y,
    width,
    height,
    scaleFilter ? "disable",
  }: {
    inherit id name;
    source_uuid = uuid;
    visible = true;
    locked = false;
    rot = 0.0;
    align = 5;
    bounds_type = 2;
    bounds_align = 0;
    bounds_crop = false;
    crop_left = 0;
    crop_top = 0;
    crop_right = 0;
    crop_bottom = 0;
    group_item_backup = false;
    pos = {
      x = x + 0.0;
      y = y + 0.0;
    };
    scale = {
      x = 1.0;
      y = 1.0;
    };
    bounds = {
      x = width + 0.0;
      y = height + 0.0;
    };
    scale_filter = scaleFilter;
    blend_method = "default";
    blend_type = "normal";
    show_transition = {duration = 0;};
    hide_transition = {duration = 0;};
    private_settings = {};
  };

  fullCanvas = {
    x = 0;
    y = 0;
    inherit (canvas) width height;
  };

  backdropItem = id:
    mkItem ({
        inherit id;
        name = "Backdrop";
        uuid = uuids.backdrop;
      }
      // fullCanvas);

  systemAudioItem = id:
    mkItem ({
        inherit id;
        name = "System Audio";
        uuid = uuids.systemAudio;
      }
      // fullCanvas);

  cameraInsetItem = id:
    mkItem {
      inherit id;
      name = "Camera";
      uuid = uuids.camera;
      x = canvas.width - camera.width - camera.margin;
      y = canvas.height - camera.height - camera.margin;
      inherit (camera) width height;
      scaleFilter = "lanczos";
    };

  mkScene = {
    name,
    uuid,
    items,
  }:
    mkSource {
      inherit name uuid;
      id = "scene";
      settings = {
        id_counter = builtins.length items;
        custom_size = false;
        inherit items;
      };
    };

  scenes = [
    (mkScene {
      name = "Code";
      uuid = uuids.sceneCode;
      items = [
        (backdropItem 1)
        (mkItem ({
            id = 2;
            name = "Display";
            uuid = uuids.display;
          }
          // fullCanvas))
        (cameraInsetItem 3)
        (systemAudioItem 4)
      ];
    })
    (mkScene {
      name = "Code only";
      uuid = uuids.sceneCodeOnly;
      items = [
        (backdropItem 1)
        (mkItem ({
            id = 2;
            name = "Display";
            uuid = uuids.display;
          }
          // fullCanvas))
        (systemAudioItem 3)
      ];
    })
    (mkScene {
      name = "Camera";
      uuid = uuids.sceneCamera;
      items = [
        (backdropItem 1)
        (mkItem {
          id = 2;
          name = "Camera";
          uuid = uuids.camera;
          x = canvas.width / 20;
          y = canvas.height / 20;
          width = canvas.width * 9 / 10;
          height = canvas.height * 9 / 10;
          scaleFilter = "lanczos";
        })
        (systemAudioItem 3)
      ];
    })
    (mkScene {
      name = "Window";
      uuid = uuids.sceneWindow;
      items = [
        (backdropItem 1)
        (mkItem {
          id = 2;
          name = "Window";
          uuid = uuids.window;
          x = canvas.width / 20;
          y = canvas.height / 20;
          width = canvas.width * 9 / 10;
          height = canvas.height * 9 / 10;
          scaleFilter = "lanczos";
        })
        (cameraInsetItem 3)
        (systemAudioItem 4)
      ];
    })
  ];

  sources =
    [
      (mkSource {
        name = "Backdrop";
        uuid = uuids.backdrop;
        id = "color_source_v3";
        # ABGR for #1E1F22, the Ghostty islands-dark background.
        settings = {
          color = 4280426270;
          inherit (canvas) width height;
        };
      })
      (mkSource {
        name = "Display";
        uuid = uuids.display;
        id = "screen_capture";
        settings =
          {
            type = 0;
            show_cursor = true;
          }
          // lib.optionalAttrs (cfg.display != null) {display_uuid = cfg.display;};
      })
      (mkSource {
        name = "Window";
        uuid = uuids.window;
        id = "screen_capture";
        settings = {
          type = 1;
          show_cursor = true;
        };
      })
      (mkSource {
        name = "Camera";
        uuid = uuids.camera;
        id = "av_capture_input_v2";
        settings =
          {
            use_preset = true;
            preset = "AVCaptureSessionPreset1920x1080";
          }
          // lib.optionalAttrs (cfg.camera != null) {device = cfg.camera;};
        filters = [
          (mkFilter {
            name = "Rounded corners";
            uuid = uuids.cameraMask;
            id = "mask_filter_v2";
            settings = {
              type = "mask_alpha_filter.effect";
              image_path = "${cameraMask}/camera-mask.png";
              stretch = true;
            };
          })
        ];
      })
      (mkSource {
        name = "System Audio";
        uuid = uuids.systemAudio;
        id = "sck_audio_capture";
        settings.type = 0;
        mixers = tracks.system;
      })
    ]
    ++ scenes;

  mic = mkSource {
    name = "Mic";
    uuid = uuids.mic;
    id = "coreaudio_input_capture";
    settings.device_id = cfg.microphone;
    mixers = tracks.mic;
    filters = [
      (mkFilter {
        name = "Noise suppression";
        uuid = uuids.micNoise;
        id = "noise_suppress_filter";
        settings.method = "rnnoise";
      })
      (mkFilter {
        name = "Compressor";
        uuid = uuids.micCompressor;
        id = "compressor_filter";
        settings = {
          ratio = 4.0;
          threshold = -18.0;
          attack_time = 6;
          release_time = 60;
          output_gain = 0.0;
          sidechain_source = "none";
        };
      })
      (mkFilter {
        name = "Limiter";
        uuid = uuids.micLimiter;
        id = "limiter_filter";
        settings = {
          threshold = -3.0;
          release_time = 60;
        };
      })
    ];
  };

  sceneCollection = pkgs.writeText "Screencast.json" (builtins.toJSON {
    name = "Screencast";
    current_scene = "Code";
    current_program_scene = "Code";
    scene_order = map (scene: {inherit (scene) name;}) scenes;
    current_transition = "Cut";
    transition_duration = 300;
    transitions = [];
    quick_transitions = [];
    groups = [];
    saved_projectors = [];
    modules = {};
    preview_locked = false;
    scaling_enabled = false;
    scaling_level = 0;
    scaling_off_x = 0.0;
    scaling_off_y = 0.0;
    AuxAudioDevice1 = mic;
    inherit sources;
  });

  profile = pkgs.writeText "basic.ini" (lib.generators.toINI {} {
    General.Name = "Screencast";
    Output.Mode = "Advanced";
    AdvOut = {
      RecType = "Standard";
      RecFilePath = cfg.recordingDirectory;
      RecFormat2 = "hybrid_mov";
      RecTracks = 7;
      RecEncoder = "com.apple.videotoolbox.videoencoder.ave.hevc";
      RecAudioEncoder = "CoreAudio_AAC";
      RecUseRescale = false;
      RecSplitFile = false;
      Track1Bitrate = 320;
      Track2Bitrate = 320;
      Track3Bitrate = 320;
      Track1Name = "Mic";
      Track2Name = "System";
      Track3Name = "Mix";
    };
    Video = {
      BaseCX = canvas.width;
      BaseCY = canvas.height;
      OutputCX = canvas.width;
      OutputCY = canvas.height;
      FPSType = 0;
      FPSCommon = 30;
      ScaleType = "lanczos";
      ColorFormat = "NV12";
      ColorSpace = "709";
      ColorRange = "Partial";
    };
    Audio = {
      SampleRate = 48000;
      ChannelSetup = "Stereo";
    };
    Hotkeys = {
      "OBSBasic.StartRecording" = ''{"bindings":[{"command":true,"shift":true,"key":"OBS_KEY_R"}]}'';
      "OBSBasic.StopRecording" = ''{"bindings":[{"command":true,"shift":true,"key":"OBS_KEY_R"}]}'';
    };
  });

  recordEncoder = pkgs.writeText "recordEncoder.json" (builtins.toJSON {
    rate_control = "ABR";
    bitrate = 50000;
    keyint_sec = 2;
    profile = "main";
    bframes = true;
  });

  obsDir = "${config.home.homeDirectory}/Library/Application Support/obs-studio";
in {
  options.workstation.obs = {
    enable = lib.mkEnableOption "the managed OBS screencast scene collection and profile";

    display = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "CoreGraphics UUID of the display to capture. Null captures the main display.";
    };

    camera = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "AVCapture unique ID of the camera. Null leaves the camera unselected.";
    };

    microphone = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = "CoreAudio device UID of the microphone, or default for the system input.";
    };

    recordingDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Movies/Screencasts";
      description = "Directory that receives recordings.";
    };
  };

  config = lib.mkIf cfg.enable {
    # OBS rewrites these files on exit, so they are copied, not linked.
    home.activation.obsScreencast = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p "${obsDir}/basic/scenes" "${obsDir}/basic/profiles/Screencast" "${cfg.recordingDirectory}"
      $DRY_RUN_CMD install -m 644 ${sceneCollection} "${obsDir}/basic/scenes/Screencast.json"
      $DRY_RUN_CMD install -m 644 ${profile} "${obsDir}/basic/profiles/Screencast/basic.ini"
      $DRY_RUN_CMD install -m 644 ${recordEncoder} "${obsDir}/basic/profiles/Screencast/recordEncoder.json"
    '';

    programs.zsh.shellAliases.screencast = "open -a OBS --args --collection Screencast --profile Screencast --scene Code";
  };
}
