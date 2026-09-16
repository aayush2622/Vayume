    ccWidgetIcon: root.showBatteryIcon ? root.getBatteryIcon(root.batteryStatus) : root.getModeIcon(root.activeProfile)
    ccWidgetPrimaryText: "Power Profile"
    ccWidgetSecondaryText: root.showBatteryIcon ? (root.batteryLevel + "%") : root.activeProfile
    ccWidgetIsActive: !root.asusCtlInfo.includes("MISSING")

    // DragDropGrid's own detailHeight.js sizes the popup from
    // ccDetailHeight, defaulting to 250 (PluginComponent.qml) when a
    // plugin doesn't set it - our content (profile picker, battery
    // slider, GPU mode buttons) runs taller than that, so it was
    // getting clipped and GPU Mode - being last - never showed at all.
    ccDetailHeight: 480

    // DMS's CompoundPill (used whenever ccDetailContent is set) has two
    // independent click zones: the icon tile fires ccWidgetToggled, the
    // text label fires ccWidgetExpanded and opens ccDetailContent below.
    // There's no real on/off state here to toggle - profile switching
    // belongs in the detail view where you can see and pick a specific
    // one, not behind a silent cycle-and-toast on a stray icon tap.
    onCcWidgetToggled: { }

    ccDetailContent: Component {
        Rectangle {
            id: detailRoot
            implicitHeight: detailCol.implicitHeight + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            Column {
                id: detailCol
                width: parent.width - Theme.spacingM * 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Theme.spacingM
                spacing: Theme.spacingM

                StyledText {
                    text: "Power Profile"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceVariantText
                    visible: !root.asusCtlInfo.includes("MISSING")
                }
                Row {
                    spacing: Theme.spacingS
                    width: parent.width
                    visible: !root.asusCtlInfo.includes("MISSING")

                    Repeater {
                        id: ccProfileRepeater
                        model: root.supportedPowerProfiles.length > 0 ? root.supportedPowerProfiles : ["Quiet", "Balanced", "Performance"]

                        StyledRect {
                            width: (parent.width - (Theme.spacingS * (ccProfileRepeater.count - 1))) / ccProfileRepeater.count
                            height: 70
                            radius: Theme.cornerRadius

                            color: root.activeProfile === modelData ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow
                            border.width: root.activeProfile === modelData ? 2 : 0
                            border.color: root.getModeColor(modelData)

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                DankIcon {
                                    name: root.getModeIcon(modelData)
                                    size: 20
                                    color: root.getModeColor(modelData)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                StyledText {
                                    text: modelData
                                    font.pixelSize: Theme.fontSizeSmall
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setPowerProfile(modelData)
                            }
                        }
                    }
                }

                StyledText {
                    text: "Battery Charge Limit"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceVariantText
                    visible: !root.asusCtlInfo.includes("MISSING")
                }
                Row {
                    width: parent.width
                    spacing: Theme.spacingS
                    visible: !root.asusCtlInfo.includes("MISSING")

                    DankSlider {
                        width: parent.width - 80
                        value: root.batteryLimit
                        minimum: 20
                        maximum: 100
                        step: 5
                        unit: "%"
                        leftIcon: "battery_std"
                        rightIcon: "battery_charging_full"
                        onSliderDragFinished: finalValue => root.setBatteryLimit(finalValue)
                    }
                    StyledText {
                        text: root.batteryLimit + "%"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                        width: 50
                        horizontalAlignment: Text.AlignRight
                    }
                }

                StyledText {
                    text: "Display"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceVariantText
                    visible: !root.asusCtlInfo.includes("MISSING") && (root.panelOverdriveAvailable || root.screenAutoBrightnessAvailable)
                }
                Row {
                    width: parent.width
                    spacing: Theme.spacingS
                    visible: !root.asusCtlInfo.includes("MISSING") && root.panelOverdriveAvailable

                    StyledText {
                        text: "Panel Overdrive"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Item { width: 1; height: 1 }
                    DankIcon {
                        name: root.panelOverdriveStash ? "toggle_on" : "toggle_off"
                        size: 24
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.togglePanelOverdrive()
                        }
                    }
                }
                Row {
                    width: parent.width
                    spacing: Theme.spacingS
                    visible: !root.asusCtlInfo.includes("MISSING") && root.screenAutoBrightnessAvailable

                    StyledText {
                        text: "Screen Auto Brightness"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Item { width: 1; height: 1 }
                    DankIcon {
                        name: root.screenAutoBrightnessStash ? "toggle_on" : "toggle_off"
                        size: 24
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleScreenAutoBrightness()
                        }
                    }
                }

                StyledText {
                    text: "GPU Mode"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceVariantText
                    visible: !root.supergfxCtlInfo.includes("MISSING")
                }
                StyledText {
                    width: parent.width
                    text: "Switching GPU mode will trigger an immediate logout."
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.error
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    visible: !root.supergfxCtlInfo.includes("MISSING")
                }
                Flow {
                    width: parent.width
                    spacing: Theme.spacingS
                    visible: !root.supergfxCtlInfo.includes("MISSING")

                    Repeater {
                        model: root.supportedGpuModes

                        StyledRect {
                            width: (detailCol.width / 2) - Theme.spacingS
                            height: 45
                            radius: Theme.cornerRadius

                            color: root.activeGpuMode === modelData ? root.colorGpu : Theme.surfaceContainerLow

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingS

                                DankIcon {
                                    name: "memory"
                                    size: 18
                                    color: root.activeGpuMode === modelData ? Theme.base : Theme.surfaceText
                                }

                                StyledText {
                                    text: modelData
                                    color: root.activeGpuMode === modelData ? Theme.base : Theme.surfaceText
                                    font.weight: root.activeGpuMode === modelData ? Font.Bold : Font.Normal
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setGpuMode(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
