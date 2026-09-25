import QtQuick
import qs.Common
import qs.Widgets

DankTextField {
    height: Vayori.controlHeight + 4
    cornerRadius: Vayori.radiusSmall + 2
    topPadding: 4
    bottomPadding: 4
    backgroundColor: Vayori.field
    normalBorderColor: "transparent"
    focusedBorderColor: Vayori.focus
    focusedBorderWidth: 2
    placeholderColor: Vayori.inkGhost
    leftIconSize: 18
    leftIconColor: Vayori.inkFaint
    opacity: enabled ? 1 : 0.5
    onTextChanged: if (!getActiveFocus()) cursorPosition = 0
}
