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

  card = {
    width = 880;
    height = 680;
    left = 40;
    right = 40;
    top = 144;
    bottom = 112;
  };

  roboto = "${pkgs.roboto}/share/fonts/truetype";
  serifCjk = "${pkgs.noto-fonts-cjk-serif}/share/fonts/opentype/noto-cjk/NotoSerifCJK-VF.otf.ttc";

  themeTxt = ''
    title-text: ""
    desktop-image: "background.png"
    desktop-image-scale-method: "crop"
    desktop-color: "${c.surface}"
    terminal-font: "@body@"
    terminal-left: "0"
    terminal-top: "0"
    terminal-width: "100%"
    terminal-height: "100%"
    terminal-border: "0"

    + label {
      left = 50%-${toString (card.width / 2 - card.left)}
      top = 50%-${toString (card.height / 2 - 40)}
      width = 600
      height = 44
      text = "Vayume"
      font = "@title@"
      color = "${c.onSurface}"
    }

    + label {
      left = 50%-${toString (card.width / 2 - card.left)}
      top = 50%-${toString (card.height / 2 - 88)}
      width = 600
      height = 24
      text = "Choose what to start"
      font = "@body@"
      color = "${c.onSurfaceVariant}"
    }

    + label {
      left = 50%+${toString (card.width / 2 - card.right - 40)}
      top = 50%-${toString (card.height / 2 - 40)}
      width = 40
      height = 44
      align = "right"
      text = "夜"
      font = "@kanji@"
      color = "${c.primary}"
    }

    + label {
      id = "__timeout__"
      left = 50%-${toString (card.width / 2 - card.left)}
      top = 50%+${toString (card.height / 2 - 82)}
      width = ${toString (card.width - card.left - card.right)}
      height = 22
      text = "Starting the highlighted entry in %d s"
      font = "@small@"
      color = "${c.onSurfaceVariant}"
    }

    + label {
      left = 50%-${toString (card.width / 2 - card.left)}
      top = 50%+${toString (card.height / 2 - 50)}
      width = ${toString (card.width - card.left - card.right)}
      height = 22
      text = "Up / Down to choose  ·  Enter to boot  ·  Esc to go back  ·  e to edit  ·  c for a command line"
      font = "@small@"
      color = "${c.outline}"
    }

    + boot_menu {
      left = 50%-${toString (card.width / 2)}
      top = 50%-${toString (card.height / 2)}
      width = ${toString card.width}
      height = ${toString card.height}
      menu_pixmap_style = "card_*.png"
      item_font = "@item@"
      selected_item_font = "@itemSelected@"
      item_color = "${c.onSurfaceVariant}"
      selected_item_color = "${c.onPrimaryContainer}"
      item_height = 28
      item_padding = 0
      item_spacing = 30
      icon_width = 0
      icon_height = 0
      item_icon_space = 0
      item_pixmap_style = "item_*.png"
      selected_item_pixmap_style = "select_*.png"
      scrollbar = true
      scrollbar_width = 6
      scrollbar_thumb_overlay = true
      scrollbar_frame = "scrollframe_*.png"
      scrollbar_thumb = "scrollthumb_*.png"
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
      -strip PNG24:background.png

    slice() {
      local name=$1 w=$2 h=$3 r=$4 color=$5 left=$6 top=$7 right=$8 bottom=$9
      magick -size ''${w}x''${h} xc:none -fill "$color" -draw "roundrectangle 0,0 $((w - 1)),$((h - 1)) $r,$r" PNG32:whole.png
      magick whole.png -crop ''${left}x''${top}+0+0 +repage PNG32:''${name}_nw.png
      magick whole.png -crop 1x''${top}+''${left}+0 +repage PNG32:''${name}_n.png
      magick whole.png -crop ''${right}x''${top}+$((w - right))+0 +repage PNG32:''${name}_ne.png
      magick whole.png -crop ''${left}x1+0+''${top} +repage PNG32:''${name}_w.png
      magick whole.png -crop 1x1+''${left}+''${top} +repage PNG32:''${name}_c.png
      magick whole.png -crop ''${right}x1+$((w - right))+''${top} +repage PNG32:''${name}_e.png
      magick whole.png -crop ''${left}x''${bottom}+0+$((h - bottom)) +repage PNG32:''${name}_sw.png
      magick whole.png -crop 1x''${bottom}+''${left}+$((h - bottom)) +repage PNG32:''${name}_s.png
      magick whole.png -crop ''${right}x''${bottom}+$((w - right))+$((h - bottom)) +repage PNG32:''${name}_se.png
      rm whole.png
    }

    slice card ${toString card.width} ${toString card.height} 28 '${c.surfaceContainer}' \
      ${toString card.left} ${toString card.top} ${toString card.right} ${toString card.bottom}
    slice select 200 56 14 '${c.primaryContainer}' 14 14 14 14
    slice item 200 56 14 '#00000000' 14 14 14 14
    slice scrollframe 6 40 3 '${c.surfaceContainerHighest}' 3 3 3 3
    slice scrollthumb 6 40 3 '${c.primary}' 3 3 3 3

    grub-mkfont -n "Roboto Medium" -s 34 -o title.pf2 ${roboto}/Roboto-Medium.ttf
    grub-mkfont -s 20 -o item.pf2 ${roboto}/Roboto-Regular.ttf
    grub-mkfont -n "Roboto Medium" -s 20 -o itemSelected.pf2 ${roboto}/Roboto-Medium.ttf
    grub-mkfont -s 17 -o body.pf2 ${roboto}/Roboto-Regular.ttf
    grub-mkfont -s 14 -o small.pf2 ${roboto}/Roboto-Regular.ttf
    grub-mkfont -n "Vayume Kanji" -s 30 -r 0x591C-0x591C -o kanji.pf2 ${serifCjk}

    python3 - "$themeTxtPath" > theme.txt <<'PY'
    import struct, sys
    def name(path):
        data = open(path, "rb").read()
        i = data.index(b"NAME")
        n = struct.unpack(">I", data[i + 4:i + 8])[0]
        return data[i + 8:i + 8 + n].rstrip(b"\0").decode()
    text = open(sys.argv[1]).read()
    for key in ["title", "item", "itemSelected", "body", "small", "kanji"]:
        text = text.replace("@" + key + "@", name(key + ".pf2"))
    sys.stdout.write(text)
    PY
    ! grep -q '@[a-zA-Z]*@' theme.txt
  ''
