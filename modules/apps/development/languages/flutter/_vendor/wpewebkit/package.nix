# WPE WebKit isn't packaged in nixpkgs at all (only the lower-level
# libwpe/libwpe-fdo backend libraries are) - flutter_inappwebview_linux
# needs the actual wpe-webkit-2.0 pkg-config module to build its Linux
# desktop CMake target. Vendored from eval-exec/nix-wpe-webkit
# (github.com/eval-exec/nix-wpe-webkit, commit as of 2026-09-14), since
# that's the only known working derivation for this and there's no
# public binary cache to depend on instead - copying it in means a
# from-scratch WebKit build here isn't at the mercy of that repo's
# continued existence.
{
  at-spi2-core,
  bison,
  bubblewrap,
  cairo,
  cmake,
  expat,
  fetchurl,
  flex,
  fontconfig,
  freetype,
  gettext,
  gi-docgen,
  glib,
  gobject-introspection,
  gperf,
  gst_all_1,
  harfbuzz,
  hyphen,
  icu,
  lcms2,
  lib,
  libavif,
  libdrm,
  libedit,
  libepoxy,
  libgbm,
  libgcrypt,
  libgpg-error,
  libinput,
  libjpeg,
  libjxl,
  libpng,
  libseccomp,
  libsoup_3,
  libsysprof-capture,
  libtasn1,
  libunwind,
  libwebp,
  libwpe,
  libwpe-fdo,
  libxkbcommon,
  libxml2,
  libxslt,
  mesa,
  ninja,
  p11-kit,
  pcre2,
  perl,
  pkg-config,
  python3,
  ruby,
  sqlite,
  stdenv,
  systemd,
  testers,
  unifdef,
  wayland,
  wayland-protocols,
  wayland-scanner,
  woff2,
  xdg-dbus-proxy,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "wpewebkit";
  version = "2.52.3";

  outputs = [
    "out"
    "dev"
    "devdoc"
  ];

  outputBin = "dev";

  src = fetchurl {
    url = "https://wpewebkit.org/releases/wpewebkit-${finalAttrs.version}.tar.xz";
    hash = "sha256-tRsdsebumdF3H0o1jBKP3ieneYTfIO5stZhY5SBmLQs=";
  };

  nativeBuildInputs = [
    bison
    cmake
    flex
    gettext
    gi-docgen
    gobject-introspection
    gperf
    libsysprof-capture
    ninja
    perl
    pkg-config
    python3
    ruby
    unifdef
    wayland-protocols
    wayland-scanner
  ];

  buildInputs = [
    at-spi2-core
    bubblewrap
    cairo
    expat
    fontconfig
    freetype
    glib
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-base
    gst_all_1.gstreamer
    icu
    (harfbuzz.override { withIcu = true; })
    hyphen
    lcms2
    libavif
    libdrm
    libedit
    libepoxy
    libgbm
    libgcrypt
    libgpg-error
    libinput
    libjpeg
    libjxl
    libpng
    libseccomp
    libsoup_3
    libtasn1
    libunwind
    libwebp
    libwpe
    libwpe-fdo
    libxkbcommon
    libxml2
    libxslt
    mesa
    p11-kit
    pcre2
    sqlite
    systemd
    wayland
    woff2
    xdg-dbus-proxy
    zlib
  ];

  # WebKitMacros.cmake's _WEBKIT_TARGET_LINK_FRAMEWORK uses unquoted
  # ${_linked_into} inside STREQUAL/IN_LIST checks. get_property()
  # commonly returns empty, and an unquoted empty expansion vanishes
  # from the if() argument list entirely (STREQUAL/IN_LIST left with
  # no operand) rather than becoming an empty-string token - CMake 4
  # is stricter about this than the CMake version WPEWebKit 2.52.3 was
  # written against, so it fails with "Unknown arguments specified"
  # instead of silently tolerating it. Quoting the variable is the
  # standard, minimal fix distros carry for this (e.g. Arch's
  # webkit2gtk package ships an equivalent cmake4-linked-into-quoting
  # patch) - applied here directly against this exact source rather
  # than depending on fetching that patch file.
  postPatch = ''
    substituteInPlace Source/cmake/WebKitMacros.cmake \
      --replace-fail \
        'if ((NOT _linked_into) OR (''${framework} STREQUAL ''${_linked_into}) OR (NOT ''${_linked_into} IN_LIST ''${_target}_FRAMEWORKS))' \
        'if ((NOT _linked_into) OR ("''${framework}" STREQUAL "''${_linked_into}") OR (NOT "''${_linked_into}" IN_LIST ''${_target}_FRAMEWORKS))'
  '';

  cmakeFlags = [
    (lib.cmakeFeature "PORT" "WPE")
    (lib.cmakeBool "ENABLE_DOCUMENTATION" true)
    (lib.cmakeBool "ENABLE_INTROSPECTION" true)
    (lib.cmakeBool "ENABLE_MINIBROWSER" true)
    (lib.cmakeBool "ENABLE_SPEECH_SYNTHESIS" false)
    (lib.cmakeBool "ENABLE_WPE_PLATFORM" true)
    (lib.cmakeBool "USE_LIBBACKTRACE" false)
  ];

  postFixup = ''
    moveToOutput "share/doc" "$devdoc"
  '';

  passthru.tests = {
    pkg-config = testers.hasPkgConfigModules {
      package = finalAttrs.finalPackage;
    };
  };

  meta = {
    description = "WPE WebKit port optimized for embedded devices";
    homepage = "https://wpewebkit.org";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.linux;
    pkgConfigModules = [ "wpe-webkit-2.0" ];
  };
})
