{
  lib,
  options,
  config,
}:
let
  vayume = config.vayume;

  dedicated = [
    "apps"
    "commands"
    "defaultApps"
    "defaultAppsResolved"
    "settingsGroups"
    "settingsMeta"
    "theme"
    "users"
  ];

  humanize =
    s:
    let
      spaced = lib.concatStrings (
        map (c: if c != lib.toLower c then " ${lib.toLower c}" else c) (lib.stringToCharacters s)
      );
    in
    lib.toUpper (lib.substring 0 1 spaced) + lib.substring 1 (-1) spaced;

  scalar =
    t:
    let
      n = t.name;
    in
    if n == "bool" then
      { kind = "bool"; }
    else if n == "enum" then
      {
        kind = "enum";
        choices = t.functor.payload.values;
      }
    else if builtins.match "(unsigned|signed|positive|nonnegative)?[iI]nt.*" n != null then
      {
        kind = "int";
        min =
          if n == "positiveInt" then
            1
          else if n == "unsignedInt" || n == "nonnegativeInt" then
            0
          else
            null;
      }
    else if
      builtins.elem n [
        "str"
        "nonEmptyStr"
        "singleLineStr"
        "lines"
        "separatedString"
      ]
    then
      { kind = "str"; }
    else
      null;

  describe =
    t:
    if t.name == "nullOr" then
      let
        inner = describe t.nestedTypes.elemType;
      in
      if inner == null then null else inner // { nullable = true; }
    else if t.name == "listOf" then
      let
        e = scalar t.nestedTypes.elemType;
      in
      if
        e == null
        || !(builtins.elem e.kind [
          "str"
          "enum"
        ])
      then
        null
      else
        {
          kind = "list";
          choices = e.choices or null;
        }
    else
      scalar t;

  safe =
    v:
    let
      r = builtins.tryEval (builtins.deepSeq v v);
    in
    if r.success then r.value else null;

  fromOtherFiles =
    o:
    let
      defs = builtins.filter (d: !(lib.hasSuffix "/_config.nix" (toString d.file))) (
        o.definitionsWithLocations or [ ]
      );
      strip = v: if builtins.isAttrs v && (v._type or null) == "override" then v.content else v;
      prio = v: if builtins.isAttrs v && (v._type or null) == "override" then v.priority else 100;
      sorted = lib.sort (a: b: prio a.value < prio b.value) defs;
    in
    if sorted == [ ] then
      if o ? default then safe o.default else null
    else
      safe (strip (builtins.head sorted).value);

  firstParagraph = s: lib.trim (builtins.head (lib.splitString "\n\n" (lib.trim s)));

  walk =
    rel: v:
    if v ? _type && v._type == "option" then
      let
        path = lib.concatStringsSep "." rel;
        meta =
          vayume.settingsMeta.${path} or {
            label = null;
            group = null;
            icon = null;
            app = null;
            order = 100;
            hidden = false;
          };
        groupName = if meta.group != null then meta.group else humanize (builtins.head rel);
        groupMeta =
          vayume.settingsGroups.${groupName} or {
            icon = null;
            description = null;
            order = 100;
            page = null;
          };
        shape = describe v.type;
      in
      lib.optional
        (
          shape != null
          && !(v.readOnly or false)
          && !(v.internal or false)
          && (v.visible or true) != false
          && !meta.hidden
        )
        (
          {
            inherit path;
            group = groupName;
            label =
              if meta.label != null then
                meta.label
              else if builtins.length rel > 1 then
                humanize (lib.concatStringsSep " " (builtins.tail rel))
              else
                humanize path;
            description = firstParagraph (
              if builtins.isString (v.description or null) then v.description else ""
            );
            icon = meta.icon;
            order = meta.order;
            app = meta.app;
            groupIcon = groupMeta.icon;
            groupDescription = groupMeta.description;
            groupPage = groupMeta.page;
            groupOrder = groupMeta.order;
            value = safe (lib.attrByPath rel null vayume);
            base = fromOtherFiles v;
            default = if v ? default then safe v.default else null;
            nullable = false;
            choices = null;
            min = null;
          }
          // shape
        )
    else if builtins.isAttrs v then
      lib.concatLists (lib.mapAttrsToList (n: x: walk (rel ++ [ n ]) x) v)
    else
      [ ];

  top = lib.filterAttrs (n: _: !(builtins.elem n dedicated)) options.vayume;
in
builtins.concatLists (lib.mapAttrsToList (n: v: walk [ n ] v) top)
