# Some packages take a long time to build from source with no public
# binary cache to fall back on (spotifast, currently). loadOrBuild lets
# a module offer a manual escape hatch: drop a zip of an already-built
# output at bin/<name>.zip in the repo root (gitignored, machine-specific,
# never committed - see .gitignore), and every future build just unzips
# it (seconds) instead of rebuilding from source. No zip present, no
# change in behavior - falls straight through to the real derivation.
#
# The zip is expected to be a plain zip of a built output's file tree,
# e.g.:
#   cd /nix/store/<hash>-spotifast-1.2.3 && zip -r name.zip .
# For a multi-output derivation, merge every output's tree into one
# zip (they don't overlap) - the unzipped result is used as a single
# combined output on the loaded-from-zip path, which is fine for
# pkg-config/binary lookups even though the real derivation keeps
# out/dev/devdoc split.
#
# Because bin/*.zip is gitignored, it's invisible to a pure flake
# evaluation unless `git add -f -N bin/<name>.zip` has been run at
# least once - the same requirement this repo already has for
# modules/hosts/*/_hardware.nix and friends.
{ lib, ... }: {
  options.flake.vayumeLib.loadOrBuild = lib.mkOption {
    type = lib.types.unspecified;
    default = { self, pkgs }: name: realDrv:
      let
        zipPath = self.outPath + "/bin/${name}.zip";
      in
      if builtins.pathExists zipPath then
        pkgs.runCommand name { nativeBuildInputs = [ pkgs.unzip ]; } ''
          mkdir -p $out
          cd $out
          unzip -q ${zipPath}
        ''
      else
        realDrv;
    description = ''
      { self, pkgs }: name: realDrv: derivation - returns a fast unzip
      of bin/<name>.zip when present, otherwise realDrv unchanged. See
      modules/lib/LoadOrBuild.nix for the zip format and why this
      exists.
    '';
  };
}
