{
  flake.homeModules.apps.Vesktop = { self, pkgs, lib, config, vayoriTheme, ... }:
  let
    discordTemplate =
      lib.replaceStrings [ "@@FONT@@" ] [ vayoriTheme.font ] self.matugenTemplates.discord;

    vesktopSettings = {
      discordBranch = "stable";
      minimizeToTray = true;
      arRPC = true;
      spellCheckLanguages = [ "en-GB" "en-IN" "en" ];
      splashColor = "rgb(255, 255, 255)";
      splashBackground = "rgb(29, 37, 43)";
    };

    vencordSettings = {
      autoUpdate = true;
      autoUpdateNotification = true;
      useQuickCss = true;
      themeLinks = [ ];
      eagerPatches = false;
      enabledThemes = [ ];
      enableReactDevtools = false;
      frameless = false;
      transparent = false;
      winCtrlQ = false;
      disableMinSize = false;
      winNativeTitleBar = false;
      notifications = {
        timeout = 5000;
        position = "bottom-right";
        useNative = "not-focused";
        logLimit = 50;
      };
      cloud = {
        authenticated = false;
        url = "https://api.vencord.dev/";
        settingsSync = false;
        settingsSyncVersion = 1784232412821;
      };
      uiElements = {
        chatBarButtons = { };
        messagePopoverButtons = { };
      };
      windowsMaterial = "none";
    };

    vencordPlugins = {
      ChatInputButtonAPI = { enabled = true; };
      CommandsAPI = { enabled = true; };
      DynamicImageModalAPI = { enabled = true; };
      MemberListDecoratorsAPI = { enabled = true; };
      MessageAccessoriesAPI = { enabled = true; };
      MessageDecorationsAPI = { enabled = true; };
      MessageEventsAPI = { enabled = true; };
      MessagePopoverAPI = { enabled = false; };
      MessageUpdaterAPI = { enabled = true; };
      ServerListAPI = { enabled = false; };
      UserSettingsAPI = { enabled = true; };
      BadgeAPI = { enabled = true; };

      AlwaysExpandRoles = { enabled = true; };
      BetterGifPicker = { enabled = true; };
      BetterRoleContext = { enabled = true; };
      BetterRoleDot = {
        enabled = true;
        bothStyles = false;
        copyRoleColorInProfilePopout = false;
      };
      BetterSessions = {
        enabled = true;
        backgroundCheck = false;
      };
      BetterSettings = {
        enabled = true;
        disableFade = true;
        organizeMenu = true;
        eagerLoad = true;
      };
      BetterUploadButton = { enabled = true; };
      BiggerStreamPreview = { enabled = true; };
      BlurNSFW = {
        enabled = true;
        blurAmount = 10;
      };
      CallTimer = { enabled = true; };
      ClearURLs = { enabled = true; };
      CrashHandler = { enabled = true; };
      CustomIdle = {
        enabled = false;
        idleTimeout = 10;
        remainInIdle = true;
      };
      DisableCallIdle = { enabled = true; };
      Experiments = {
        enabled = true;
        toolbarDevMenu = false;
      };
      FakeNitro = {
        enabled = true;
        enableStickerBypass = true;
        enableStreamQualityBypass = true;
        enableEmojiBypass = true;
        transformEmojis = true;
        transformStickers = true;
        transformCompoundSentence = false;
      };
      FakeProfileThemes = {
        enabled = true;
        nitroFirst = true;
      };
      FavoriteEmojiFirst = { enabled = true; };
      FixImagesQuality = {
        enabled = true;
        originalImagesInChat = false;
      };
      FixSpotifyEmbeds = { enabled = true; };
      FixYoutubeEmbeds = { enabled = true; };
      ForceOwnerCrown = { enabled = true; };
      FriendsSince = { enabled = true; };
      GameActivityToggle = {
        enabled = true;
        location = "PANEL";
        oldIcon = false;
      };
      ImplicitRelationships = { enabled = true; };
      MemberCount = { enabled = true; };
      MentionAvatars = {
        enabled = true;
        showAtSymbol = true;
      };
      MessageClickActions = { enabled = true; };
      MessageLogger = {
        enabled = true;
        collapseDeleted = false;
        deleteStyle = "text";
        ignoreBots = false;
        ignoreSelf = false;
        ignoreUsers = "";
        ignoreChannels = "";
        ignoreGuilds = "";
        logEdits = true;
        logDeletes = true;
        inlineEdits = true;
      };
      NewGuildSettings = {
        enabled = false;
        guild = true;
        messages = 3;
        everyone = true;
        role = true;
        highlights = true;
        events = true;
        showAllChannels = true;
      };
      NoProfileThemes = { enabled = true; };
      OnePingPerDM = {
        enabled = true;
        channelToAffect = "both_dms";
        allowMentions = false;
        allowEveryone = false;
      };
      OpenInApp = {
        enabled = true;
        spotify = true;
        steam = true;
        epic = true;
        tidal = true;
        itunes = true;
      };
      PermissionsViewer = { enabled = true; };
      PlatformIndicators = {
        enabled = true;
        colorMobileIndicator = true;
        list = true;
        badges = true;
        messages = true;
      };
      PreviewMessage = { enabled = true; };
      RelationshipNotifier = {
        enabled = true;
        offlineRemovals = true;
        groups = true;
        servers = true;
        friends = true;
        friendRequestCancels = true;
      };
      RoleColorEverywhere = { enabled = true; };
      ServerInfo = { enabled = true; };
      ShikiCodeblocks = {
        enabled = true;
        theme = "https://cdn.jsdelivr.net/gh/shikijs/textmate-grammars-themes@bc5436518111d87ea58eb56d97b3f9bec30e6b83/packages/tm-themes/themes/one-dark-pro.json";
        tryHljs = "SECONDARY";
        useDevIcon = "GREYSCALE";
        bgOpacity = 100;
      };
      ShowConnections = {
        enabled = true;
        iconSpacing = 1;
        iconSize = 32;
      };
      ShowHiddenChannels = {
        enabled = true;
        showMode = 0;
        hideUnreads = true;
        defaultAllowedUsersAndRolesDropdownState = false;
      };
      ShowHiddenThings = {
        enabled = true;
        showTimeouts = true;
        showInvitesPaused = true;
        showModView = true;
      };
      ShowMeYourName = {
        enabled = true;
        mode = "user-nick";
        friendNicknames = "dms";
        displayNames = false;
        inReplies = false;
      };
      SpotifyControls = {
        enabled = true;
        hoverControls = false;
      };
      ViewIcons = { enabled = true; };
      VoiceDownload = { enabled = true; };
      WebKeybinds = { enabled = true; };
      WebScreenShareFixes = { enabled = true; };
      WhoReacted = { enabled = true; };
      NoTrack = {
        enabled = true;
        disableAnalytics = true;
      };
      Settings = {
        enabled = true;
        settingsLocation = "aboveNitro";
        includeVencordInfoWhenCopying = true;
      };
      DisableDeepLinks = { enabled = true; };
      SupportHelper = { enabled = true; };
      WebContextMenus = { enabled = true; };
      ConcatenatedComponentExtractor = { enabled = true; };
    };
  in
  {
    programs.vesktop = {
      enable = true;
      settings = vesktopSettings;
      vencord.settings = vencordSettings // { plugins = vencordPlugins; };
    };

    home.file.".config/matugen/templates/vayori-discord.css".text = discordTemplate;

    vayori.matugenTemplates.vesktop = ''
      [templates.vesktop]
      input_path = '${config.home.homeDirectory}/.config/matugen/templates/vayori-discord.css'
      output_path = '${config.home.homeDirectory}/.config/vesktop/themes/vayori-discord.css'
    '';

    home.activation.applyDmsVesktopTheme =
      let
        quickCss = pkgs.writeText "vesktop-quickcss" ''
          @import url("../themes/vayori-discord.css");
        '';
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "$HOME/.config/vesktop/settings" "$HOME/.config/vesktop/themes"
        run install -m 644 "${quickCss}" "$HOME/.config/vesktop/settings/quickCss.css"
      '';
  };
}
