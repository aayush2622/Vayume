//@ pragma UseQApplication

import QtQuick
import Quickshell
import qs.Common
import qs.DankCommon.Common
import "./ui"

ShellRoot {
    id: root

    Component.onCompleted: Style.theme = Theme

    VayumeModel {
        id: model
        Component.onCompleted: ensurePage("overview")
    }

    SettingsWindow {
        vm: model
        visible: true
        onVisibleChanged: if (!visible) Qt.quit()
    }
}
