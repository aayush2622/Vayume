import QtQuick
import qs.Common
import qs.Widgets

DankTextField {
    height: Vayori.controlHeight
    cornerRadius: Vayori.radius
    topPadding: 4
    bottomPadding: 4
    backgroundColor: Vayori.field
    normalBorderColor: Vayori.hairline
    focusedBorderColor: Vayori.focus
    focusedBorderWidth: 1
    placeholderColor: Vayori.inkGhost
    leftIconSize: 16
    leftIconColor: Vayori.inkFaint
    opacity: enabled ? 1 : 0.5
    onTextChanged: if (!getActiveFocus()) cursorPosition = 0
}
