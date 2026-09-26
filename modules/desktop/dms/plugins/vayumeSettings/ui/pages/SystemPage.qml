import QtQuick
import qs.Common
import qs.Widgets
import "../components"

Column {
    id: root

    required property var vm
    required property string page
    width: parent.width
    spacing: Vayori.gap

    readonly property string meta: options.pendingCount > 0 ? I18n.tr("%1 waiting for a rebuild").arg(options.pendingCount) : I18n.tr("changes apply on rebuild")

    PageOptions {
        id: options
        vm: root.vm
        page: root.page
    }
}
