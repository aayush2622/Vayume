import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "data.js" as Data

ShellRoot {
    id: shell

    readonly property var cfg: Data.config
    readonly property var screenRef: {
        const all = Quickshell.screens;
        for (let i = 0; i < all.length; i++)
            if (all[i].name === cfg.monitor)
                return all[i];
        return all.length > 0 ? all[0] : null;
    }

    PanelWindow {
        id: win

        screen: shell.screenRef
        color: "transparent"
        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "vayume-pet"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.layer: shell.cfg.layer === "overlay" ? WlrLayer.Overlay : shell.cfg.layer === "bottom" ? WlrLayer.Bottom : WlrLayer.Top

        mask: Region {
            regions: pet.cellRegions[pet.cellKey] ?? []
        }

        Pet {
            id: pet
            cfg: shell.cfg
            masks: Data.masks
            areaWidth: win.width
            areaHeight: win.height
            screenX: shell.screenRef ? shell.screenRef.x : 0
            screenY: shell.screenRef ? shell.screenRef.y : 0

            property var cellRegions: ({})

            Component.onCompleted: {
                const built = {};
                for (const key in Data.masks)
                    built[key] = Data.masks[key].map(r => regionComponent.createObject(win, {
                                rx: r[0],
                                ry: r[1],
                                rw: r[2],
                                rh: r[3]
                            }));
                cellRegions = built;
            }
        }

        Component {
            id: regionComponent

            Region {
                property int rx
                property int ry
                property int rw
                property int rh

                x: Math.round(pet.x + rx * pet.px)
                y: Math.round(pet.y + ry * pet.px)
                width: Math.ceil(rw * pet.px)
                height: Math.ceil(rh * pet.px)
            }
        }
    }
}
