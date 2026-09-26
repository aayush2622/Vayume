{
  pkgs,
  wallpaper,
}:
let
  c = {
    surface = "#11131c";
    surfaceContainer = "#1d1f2c";
    surfaceContainerHighest = "#333542";
    onSurface = "#e3e1ef";
    onSurfaceVariant = "#c6c5d6";
    outline = "#8f8fa0";
    primary = "#b8c4ff";
    primaryContainer = "#36437a";
    onPrimaryContainer = "#dde1ff";
  };

  roboto = "${pkgs.roboto}/share/fonts/truetype";
  serifCjk = "${pkgs.noto-fonts-cjk-serif}/share/fonts/opentype/noto-cjk/NotoSerifCJK-VF.otf.ttc";

  themeTxt = ''
    title-text: ""
    desktop-image: "background.png"
    desktop-color: "${c.surface}"
    terminal-font: "@body@"
    terminal-left: "0"
    terminal-top: "0"
    terminal-width: "100%"
    terminal-height: "100%"
    terminal-border: "0"

    + label {
      left = 50%-340
      top = 262
      width = 600
      height = 44
      text = "Vayume"
      font = "@title@"
      color = "${c.onSurface}"
    }

    + label {
      left = 50%-340
      top = 312
      width = 680
      height = 24
      text = "Choose what to start"
      font = "@body@"
      color = "${c.onSurfaceVariant}"
    }

    + boot_menu {
      left = 50%-326
      top = 382
      width = 652
      height = 384
      item_font = "@item@"
      selected_item_font = "@itemSelected@"
      item_color = "${c.onSurfaceVariant}"
      selected_item_color = "${c.onPrimaryContainer}"
      item_height = 28
      item_padding = 10
      item_spacing = 32
      icon_width = 0
      icon_height = 0
      item_icon_space = 0
      item_pixmap_style = "item_*.png"
      selected_item_pixmap_style = "select_*.png"
      scrollbar = true
      scrollbar_width = 6
      scrollbar_frame = "scrollframe_*.png"
      scrollbar_thumb = "scrollthumb_*.png"
    }

    + label {
      id = "__timeout__"
      left = 50%-340
      top = 800
      width = 680
      height = 22
      text = "Starting the highlighted entry in %d s"
      font = "@small@"
      color = "${c.onSurfaceVariant}"
    }

    + label {
      left = 50%-340
      top = 848
      width = 680
      height = 22
      text = "Up / Down to choose  ·  Enter to boot  ·  e to edit  ·  c for a command line"
      font = "@small@"
      color = "${c.outline}"
    }
  '';
in
pkgs.runCommand "vayume-grub-theme"
  {
    nativeBuildInputs = [
      pkgs.imagemagick
      pkgs.grub2
      pkgs.python3
    ];
    passAsFile = [ "themeTxt" ];
    inherit themeTxt;
  }
  ''
    mkdir -p $out
    cd $out

    magick ${wallpaper} -resize 1920x1080^ -gravity center -extent 1920x1080 \
      -blur 0x22 -modulate 100,80 \
      \( -size 1920x1080 xc:'${c.surface}' -alpha set -channel A -evaluate set 42% +channel \) -composite \
      \( -size 760x690 xc:none -fill '${c.surfaceContainer}e6' -draw 'roundrectangle 0,0 759,689 28,28' \) \
      -gravity northwest -geometry +580+205 -composite \
      -font ${serifCjk} -pointsize 30 -fill '${c.primary}' -annotate +1286+264 '夜' \
      -strip PNG24:background.png

    slice() {
      local name=$1 w=$2 h=$3 r=$4 color=$5
      magick -size ''${w}x''${h} xc:none -fill "$color" -draw "roundrectangle 0,0 $((w - 1)),$((h - 1)) $r,$r" PNG32:whole.png
      magick whole.png -crop ''${r}x''${r}+0+0 +repage PNG32:''${name}_nw.png
      magick whole.png -crop 1x''${r}+''${r}+0 +repage PNG32:''${name}_n.png
      magick whole.png -crop ''${r}x''${r}+$((w - r))+0 +repage PNG32:''${name}_ne.png
      magick whole.png -crop ''${r}x1+0+''${r} +repage PNG32:''${name}_w.png
      magick whole.png -crop 1x1+''${r}+''${r} +repage PNG32:''${name}_c.png
      magick whole.png -crop ''${r}x1+$((w - r))+''${r} +repage PNG32:''${name}_e.png
      magick whole.png -crop ''${r}x''${r}+0+$((h - r)) +repage PNG32:''${name}_sw.png
      magick whole.png -crop 1x''${r}+''${r}+$((h - r)) +repage PNG32:''${name}_s.png
      magick whole.png -crop ''${r}x''${r}+$((w - r))+$((h - r)) +repage PNG32:''${name}_se.png
      rm whole.png
    }

    slice select 120 29 14 '${c.primaryContainer}'
    slice scrollframe 6 40 3 '${c.surfaceContainerHighest}'
    slice scrollthumb 6 40 3 '${c.outline}'
    slice item 120 29 14 '#00000000'

    grub-mkfont -n "Roboto Medium" -s 34 -o title.pf2 ${roboto}/Roboto-Medium.ttf
    grub-mkfont -s 20 -o item.pf2 ${roboto}/Roboto-Regular.ttf
    grub-mkfont -n "Roboto Medium" -s 20 -o itemSelected.pf2 ${roboto}/Roboto-Medium.ttf
    grub-mkfont -s 17 -o body.pf2 ${roboto}/Roboto-Regular.ttf
    grub-mkfont -s 14 -o small.pf2 ${roboto}/Roboto-Regular.ttf

    python3 - "$themeTxtPath" > theme.txt <<'PY'
    import struct, sys
    def name(path):
        data = open(path, "rb").read()
        i = data.index(b"NAME")
        n = struct.unpack(">I", data[i + 4:i + 8])[0]
        return data[i + 8:i + 8 + n].rstrip(b"\0").decode()
    text = open(sys.argv[1]).read()
    for key in ["title", "item", "itemSelected", "body", "small"]:
        text = text.replace("@" + key + "@", name(key + ".pf2"))
    sys.stdout.write(text)
    PY
    ! grep -q '@[a-zA-Z]*@' theme.txt
  ''
