{ self, ... }: {
  flake.nixosModules.PluginUpdateCheck = { config, lib, pkgs, ... }:
  let
    checkerScript = pkgs.writers.writePython3Bin "vayume-check-plugin-updates" { } ''
      import base64
      import hashlib
      import json
      import os
      import sys
      import time
      import urllib.error
      import urllib.request
      import xml.etree.ElementTree as ET
      from concurrent.futures import ThreadPoolExecutor
      from pathlib import Path

      DEFAULT_PINS = "/etc/vayume/plugin-pins.json"
      DEFAULT_CACHE = str(
          Path.home() / ".cache" / "vayume" / "plugin-update-check.json"
      )
      PINS_PATH = Path(os.environ.get("VAYUME_PLUGIN_PINS", DEFAULT_PINS))
      CACHE_PATH = Path(os.environ.get("VAYUME_PLUGIN_CHECK_CACHE", DEFAULT_CACHE))
      TTL = int(os.environ.get("VAYUME_PLUGIN_CHECK_TTL", "86400"))
      FORCE = os.environ.get("VAYUME_PLUGIN_CHECK_FORCE") == "1"
      REQUEST_TIMEOUT = 4

      VSCODE_QUERY_URL = (
          "https://marketplace.visualstudio.com/_apis/public/gallery"
          "/extensionquery"
      )
      JETBRAINS_LIST_URL = "https://plugins.jetbrains.com/plugins/list?pluginId={}"
      JETBRAINS_DOWNLOAD_URL = (
          "https://plugins.jetbrains.com/plugin/download?pluginId={}&version={}"
      )
      VSCODE_VSIX_URL = (
          "https://{publisher}.gallery.vsassets.io/_apis/public/gallery"
          "/publisher/{publisher}/extension/{name}/{version}/assetbyname"
          "/Microsoft.VisualStudio.Services.VSIXPackage"
      )
      DOWNLOAD_TIMEOUT = 60
      AMO_ADDON_URL = "https://addons.mozilla.org/api/v5/addons/addon/{}/"
      ZEN_THEME_STORE_URL = (
          "https://raw.githubusercontent.com/zen-browser/theme-store"
          "/main/themes.json"
      )


      def fetch_json(url, data=None, headers=None):
          req = urllib.request.Request(url, data=data, headers=headers or {})
          with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as resp:
              return json.loads(resp.read().decode())


      def sri_sha256(data):
          return "sha256-" + base64.b64encode(hashlib.sha256(data).digest()).decode()


      def compute_hash(item):
          """Fetch the artifact for the latest version and return its SRI hash.

          Mirrors what pkgs.fetchurl pins (flat sha256 over the raw file), so the
          value can be pasted straight into the matching *.nix plugin spec.
          """
          try:
              kind = item.get("kind")
              if kind == "jetbrains":
                  url = JETBRAINS_DOWNLOAD_URL.format(item["id"], item["latest"])
              elif kind == "vscode":
                  url = VSCODE_VSIX_URL.format(
                      publisher=item["publisher"],
                      name=item["pkg_name"],
                      version=item["latest"],
                  )
              else:
                  return None
              req = urllib.request.Request(
                  url, headers={"User-Agent": "vayume-plugin-update-check"}
              )
              with urllib.request.urlopen(req, timeout=DOWNLOAD_TIMEOUT) as resp:
                  return sri_sha256(resp.read())
          except Exception:
              return None


      def check_vscode(item):
          label = "{}.{}".format(item["publisher"], item["name"])
          body = json.dumps({
              "filters": [{
                  "criteria": [{"filterType": 7, "value": label}],
                  "pageNumber": 1,
                  "pageSize": 1,
                  "sortBy": 0,
                  "sortOrder": 0,
              }],
              "flags": 513,
          }).encode()
          headers = {
              "Content-Type": "application/json",
              "Accept": "application/json;api-version=3.0-preview.1",
          }
          try:
              data = fetch_json(VSCODE_QUERY_URL, body, headers)
          except Exception:
              return "skip"
          exts = data.get("results", [{}])[0].get("extensions", [])
          if not exts:
              return {
                  "app": "VS Code", "name": label, "pinned": item["version"],
                  "latest": None, "note": "not found on marketplace",
              }
          latest = exts[0]["versions"][0]["version"]
          if latest != item["version"]:
              return {
                  "app": "VS Code", "name": label, "pinned": item["version"],
                  "latest": latest, "note": None, "kind": "vscode",
                  "publisher": item["publisher"], "pkg_name": item["name"],
              }
          return None


      def check_android_studio(item):
          req = urllib.request.Request(JETBRAINS_LIST_URL.format(item["id"]))
          try:
              with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as resp:
                  root = ET.fromstring(resp.read())
          except Exception:
              return "skip"
          releases = []
          for el in root.findall(".//idea-plugin"):
              ver = el.find("version")
              date = el.get("updatedDate") or el.get("date")
              if ver is not None and ver.text and date is not None:
                  releases.append((int(date), ver.text))
          if not releases:
              return {
                  "app": "Android Studio", "name": item["dirName"],
                  "pinned": item["version"], "latest": None,
                  "note": "not found on JetBrains marketplace",
              }
          latest = max(releases, key=lambda r: r[0])[1]
          if latest != item["version"]:
              return {
                  "app": "Android Studio", "name": item["dirName"],
                  "pinned": item["version"], "latest": latest, "note": None,
                  "kind": "jetbrains", "id": item["id"],
              }
          return None


      def check_zen_extension(item):
          try:
              fetch_json(AMO_ADDON_URL.format(item["slug"]))
          except urllib.error.HTTPError as e:
              if e.code == 404:
                  return {
                      "app": "Zen Browser", "name": item["name"],
                      "pinned": "latest", "latest": None,
                      "note": "add-on not found on addons.mozilla.org",
                  }
              return "skip"
          except Exception:
              return "skip"
          return None


      def check_zen_mods(mods):
          try:
              index = fetch_json(ZEN_THEME_STORE_URL)
          except Exception:
              return []
          ids = set(index.keys())
          return [
              {
                  "app": "Zen Browser", "name": name, "pinned": "latest",
                  "latest": None, "note": "mod not found in theme-store index",
              }
              for name, mid in mods.items()
              if mid not in ids
          ]


      def run_checks(pins):
          zen = pins.get("ZenBrowser", {})
          with ThreadPoolExecutor(max_workers=24) as pool:
              futures = [
                  pool.submit(check_vscode, item)
                  for item in pins.get("Vscode", [])
              ] + [
                  pool.submit(check_android_studio, item)
                  for item in pins.get("AndroidStudio", [])
              ] + [
                  pool.submit(check_zen_extension, item)
                  for item in zen.get("extensions", [])
              ]
              mods_future = pool.submit(check_zen_mods, zen.get("mods", {}))
              results = [f.result() for f in futures]
              results.extend(mods_future.result())

          attempted = len(results)
          skipped = sum(1 for r in results if r == "skip")
          outdated = [r for r in results if isinstance(r, dict)]
          return outdated, attempted, skipped


      def format_report(outdated):
          lines = ["plugin updates available:"]
          pending_hash = False
          for item in outdated:
              if item["note"]:
                  lines.append(
                      "  [{}] {}  {}".format(
                          item["app"], item["name"], item["note"]
                      )
                  )
              else:
                  lines.append(
                      "  [{}] {}  {} -> {}".format(
                          item["app"], item["name"], item["pinned"],
                          item["latest"],
                      )
                  )
                  if item.get("hash"):
                      lines.append(
                          "      version = \"{}\"; hash = \"{}\";".format(
                              item["latest"], item["hash"]
                          )
                      )
                  elif item.get("kind"):
                      pending_hash = True
          lines.append(
              "update the pinned version/hash in the matching "
              "modules/apps/*/*.nix file"
          )
          if pending_hash:
              lines.append(
                  "  (resolving hashes... run `vayume-check-plugin-updates` "
                  "directly if they don't appear)"
              )
          return "\n".join(lines)


      def resolve_hashes(outdated):
          """Best-effort: fill item['hash'] for entries still missing it.

          Returns True if any hash was newly resolved. Kept separate from the
          report so a slow download can't delay (or, under `timeout`, suppress)
          the version listing.
          """
          todo = [
              r for r in outdated
              if r.get("kind") and r.get("note") is None
              and r.get("latest") and not r.get("hash")
          ]
          if not todo:
              return False
          resolved = False
          with ThreadPoolExecutor(max_workers=8) as pool:
              for item, digest in zip(todo, pool.map(compute_hash, todo)):
                  if digest:
                      item["hash"] = digest
                      resolved = True
          return resolved


      def write_cache(checked_at, outdated):
          CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
          CACHE_PATH.write_text(
              json.dumps({"checked_at": checked_at, "outdated": outdated})
          )


      def main():
          if not PINS_PATH.exists():
              return
          try:
              pins = json.loads(PINS_PATH.read_text())
          except Exception:
              return
          if not pins:
              return

          now = time.time()
          if not FORCE and CACHE_PATH.exists():
              try:
                  cache = json.loads(CACHE_PATH.read_text())
              except Exception:
                  cache = None
              if cache and now - cache.get("checked_at", 0) < TTL:
                  outdated = cache.get("outdated") or []
                  if outdated:
                      print(format_report(outdated), file=sys.stderr)
                      # An earlier run may have been killed before it could
                      # resolve every hash; try again and persist progress.
                      if resolve_hashes(outdated):
                          write_cache(cache.get("checked_at", now), outdated)
                          print(format_report(outdated), file=sys.stderr)
                  return

          outdated, attempted, skipped = run_checks(pins)

          if attempted == 0 or skipped < attempted:
              write_cache(now, outdated)

          if outdated:
              print(format_report(outdated), file=sys.stderr)
              if resolve_hashes(outdated):
                  if attempted == 0 or skipped < attempted:
                      write_cache(now, outdated)
                  print(format_report(outdated), file=sys.stderr)


      if __name__ == "__main__":
          main()
    '';
  in {
    environment.etc."vayume/plugin-pins.json".text = builtins.toJSON (
      lib.filterAttrs
        (name: _: config.vayume.apps.${name}.enable or false)
        self.pluginPins
    );
    environment.systemPackages = [ checkerScript pkgs.coreutils ];
  };
}
