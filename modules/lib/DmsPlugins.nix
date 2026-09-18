{ inputs, lib, ... }: {
  options.flake.vayumeLib.dmsPluginHelpers = lib.mkOption {
    type = lib.types.unspecified;
    default = { pkgs }:
      let
        assertPatched = file: needle: ''
          grep -qF ${lib.escapeShellArg needle} "${file}" || {
            echo "patch verification failed: ${lib.escapeShellArg needle} not found in ${file} (upstream source likely changed - update the patch)" >&2
            exit 1
          }
        '';

        assertPatchedLine = file: line: needle: ''
          sed -n '${toString line}p' "${file}" | grep -qF ${lib.escapeShellArg needle} || {
            echo "patch verification failed: line ${toString line} of ${file} doesn't say ${lib.escapeShellArg needle} (upstream source likely changed - update the patch)" >&2
            exit 1
          }
        '';

        mkPatchedPlugin = name: src: patchScript:
          pkgs.runCommand "dms-plugin-${name}-patched" { } ''
            cp -r ${src} $out
            chmod -R u+w $out
            ${patchScript}
          '';
      in {
        registryPlugins = pkgs.callPackage "${inputs.dms-plugin-registry}/nix/default.nix" { };

        audioIsPlayingScript = pkgs.writeShellScript "vayume-audio-is-playing" ''
          set -euo pipefail
          ${pkgs.pipewire}/bin/pw-dump | ${pkgs.jq}/bin/jq -e --arg cava cava '
            (map(select(.type=="PipeWire:Interface:Metadata" and .props["metadata.name"]=="default"))
              | .[0].metadata[]? | select(.key=="default.audio.sink") | .value.name) as $sinkname
            | . as $all
            | ($all | map(select(.type=="PipeWire:Interface:Node" and .info.props["node.name"]==$sinkname)) | .[0].id) as $sinkid
            | ($all | map(select(.type=="PipeWire:Interface:Node"))
                | map({(.id|tostring): (.info.props["application.name"] // .info.props["node.name"] // "")}) | add) as $nodenames
            | ($all | map(select(.type=="PipeWire:Interface:Link" and .info.state=="active" and .info.props["link.input.node"]==$sinkid))) as $activelinks
            | ($activelinks | map($nodenames[(.info.props["link.output.node"]|tostring)] // "")) as $names
            | ($names | any(. != $cava))
          ' > /dev/null
        '';

        inherit assertPatched assertPatchedLine mkPatchedPlugin;
      };
    description = ''
      { pkgs }: { registryPlugins, audioIsPlayingScript, assertPatched,
      assertPatchedLine, mkPatchedPlugin } - see
      modules/lib/DmsPlugins.nix for what each does.
    '';
  };
}
