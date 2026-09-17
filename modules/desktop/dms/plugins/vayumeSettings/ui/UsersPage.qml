import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Theme.spacingM

    readonly property var secretFields: [
        { key: "WAKATIME_API_KEY", label: I18n.tr("WakaTime API Key"), description: I18n.tr("Used by the Vscode/Zed/AndroidStudio WakaTime integration.") },
        { key: "RBW_EMAIL", label: I18n.tr("Bitwarden (rbw) Email"), description: I18n.tr("Used by Bitwarden.nix's rbw config.") }
    ]

    readonly property var usersList: {
        const names = Object.keys(root.vm.users).sort();
        return names.map(n => Object.assign({ name: n }, root.vm.users[n]));
    }

    StyledText {
        text: I18n.tr("Users")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        text: I18n.tr("Every person configured on this machine (vayume.users). Display name and app secrets are cosmetic/per-app; groups and password control real access to this machine - double-check before changing either, especially \"wheel\" (sudo/admin).")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
        width: parent.width
    }

    StyledText {
        visible: root.vm.usersLoading
        text: I18n.tr("Loading users...")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }

    Repeater {
        model: root.vm.usersLoading ? [] : root.usersList

        SettingsCard {
            id: userCard
            required property var modelData
            title: modelData.fullName.length > 0 ? modelData.fullName : modelData.name
            icon: "person"
            width: parent.width

            // --- display name ---
            Row {
                width: parent.width
                spacing: Theme.spacingS

                Column {
                    width: parent.width - nameField.width - Theme.spacingM
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                    StyledText {
                        text: I18n.tr("Display Name")
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }
                    StyledText {
                        text: I18n.tr("Cosmetic only - GECOS/login display name.")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }
                }

                DankTextField {
                    id: nameField
                    width: 240
                    anchors.verticalCenter: parent.verticalCenter
                    Component.onCompleted: text = userCard.modelData.fullName
                    onEditingFinished: {
                        if (text !== userCard.modelData.fullName) root.vm.setUserFullName(userCard.modelData.name, text);
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.outline; opacity: 0.2 }

            // --- groups ---
            Column {
                width: parent.width
                spacing: Theme.spacingXS

                StyledText {
                    text: I18n.tr("Groups")
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                }
                StyledText {
                    text: I18n.tr("Takes effect on the next rebuild, like everything else here. \"wheel\" grants full sudo/admin access.")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Flow {
                    width: parent.width
                    spacing: Theme.spacingM

                    Repeater {
                        model: root.vm.groupOptions

                        DankToggle {
                            id: groupToggle
                            required property string modelData
                            width: 220
                            hideText: false
                            text: modelData
                            description: modelData === "wheel" ? I18n.tr("Full admin (sudo) access") : ""
                            checked: userCard.modelData.extraGroups.includes(modelData)
                            onToggled: isChecked => root.vm.setUserGroup(userCard.modelData.name, groupToggle.modelData, isChecked)
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.outline; opacity: 0.2 }

            // --- app secrets ---
            Column {
                width: parent.width
                spacing: Theme.spacingM

                StyledText {
                    text: I18n.tr("App Secrets")
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                }

                Repeater {
                    model: root.secretFields

                    Row {
                        id: secretRow
                        required property var modelData
                        width: parent.width
                        spacing: Theme.spacingS

                        Column {
                            width: parent.width - 240 - Theme.spacingM
                            spacing: 2
                            anchors.verticalCenter: parent.verticalCenter
                            StyledText {
                                text: secretRow.modelData.label
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                            }
                            StyledText {
                                text: secretRow.modelData.description
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }

                        DankTextField {
                            id: secretField
                            width: 240
                            anchors.verticalCenter: parent.verticalCenter
                            echoMode: TextInput.Password
                            showPasswordToggle: true
                            placeholderText: I18n.tr("Not set")
                            Component.onCompleted: text = userCard.modelData.secrets[secretRow.modelData.key] ?? ""
                            onEditingFinished: {
                                const current = userCard.modelData.secrets[secretRow.modelData.key] ?? "";
                                if (text !== current) root.vm.setUserSecret(userCard.modelData.name, secretRow.modelData.key, text);
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.outline; opacity: 0.2 }

            // --- password ---
            Column {
                width: parent.width
                spacing: Theme.spacingS

                Row {
                    spacing: Theme.spacingS
                    StyledText {
                        text: I18n.tr("Password")
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                    }
                    Badge {
                        label: userCard.modelData.hasPassword ? I18n.tr("Set") : I18n.tr("Falls back to \"changeme\"")
                        tone: userCard.modelData.hasPassword ? "success" : "warning"
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    DankTextField {
                        id: newPasswordField
                        width: (parent.width - setPasswordButton.width - Theme.spacingS * 2) / 2
                        echoMode: TextInput.Password
                        showPasswordToggle: true
                        placeholderText: I18n.tr("New password")
                    }

                    DankTextField {
                        id: confirmPasswordField
                        width: (parent.width - setPasswordButton.width - Theme.spacingS * 2) / 2
                        echoMode: TextInput.Password
                        showPasswordToggle: true
                        placeholderText: I18n.tr("Confirm password")
                    }

                    StyledRect {
                        id: setPasswordButton
                        width: 110
                        height: 36
                        readonly property bool canSubmit: newPasswordField.text.length > 0
                            && newPasswordField.text === confirmPasswordField.text
                        radius: Theme.cornerRadius
                        color: canSubmit ? Theme.primary : Theme.surfaceContainerLow

                        StyledText {
                            anchors.centerIn: parent
                            text: I18n.tr("Set Password")
                            font.pixelSize: Theme.fontSizeSmall
                            color: setPasswordButton.canSubmit ? Theme.onPrimary : Theme.surfaceVariantText
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: setPasswordButton.canSubmit
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.vm.setUserPassword(userCard.modelData.name, newPasswordField.text);
                                newPasswordField.text = "";
                                confirmPasswordField.text = "";
                            }
                        }
                    }
                }

                StyledText {
                    visible: newPasswordField.text.length > 0 && confirmPasswordField.text.length > 0
                        && newPasswordField.text !== confirmPasswordField.text
                    text: I18n.tr("Passwords don't match.")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.error
                }
            }
        }
    }

    Row {
        width: parent.width
        visible: root.vm.usersStatus.length > 0
        StyledText {
            text: root.vm.usersStatus
            font.pixelSize: Theme.fontSizeSmall
            color: root.vm.usersError ? Theme.error : Theme.surfaceVariantText
            wrapMode: Text.WordWrap
            width: parent.width
        }
    }
}
