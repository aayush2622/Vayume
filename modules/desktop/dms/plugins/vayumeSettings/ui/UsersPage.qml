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

    SettingsCard {
        title: I18n.tr("Add User")
        icon: "person_add"
        width: parent.width

        Column {
            width: parent.width
            spacing: Theme.spacingS

            StyledText {
                text: I18n.tr("Starts with no password (falls back to \"changeme\") and the default groups (networkmanager, video, input) - set those below once added.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                width: parent.width
            }

            Row {
                width: parent.width
                spacing: Theme.spacingS

                DankTextField {
                    id: newUserNameField
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - newUserFullNameField.width - addUserButton.width - Theme.spacingS * 2
                    placeholderText: I18n.tr("username")
                }

                DankTextField {
                    id: newUserFullNameField
                    anchors.verticalCenter: parent.verticalCenter
                    width: 180
                    placeholderText: I18n.tr("Full name (optional)")
                }

                StyledRect {
                    id: addUserButton
                    anchors.verticalCenter: parent.verticalCenter
                    width: 100
                    height: 36
                    readonly property bool validName: /^[a-z_][a-z0-9_-]*$/.test(newUserNameField.text)
                    readonly property bool alreadyExists: newUserNameField.text in root.vm.users
                    readonly property bool canSubmit: validName && !alreadyExists && !root.vm.usersSaving
                    radius: Theme.cornerRadius
                    color: canSubmit ? Theme.primary : Theme.surfaceContainerLow

                    StyledText {
                        anchors.centerIn: parent
                        text: I18n.tr("Add User")
                        font.pixelSize: Theme.fontSizeSmall
                        color: addUserButton.canSubmit ? Theme.onPrimary : Theme.surfaceVariantText
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: addUserButton.canSubmit
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.vm.addUser(newUserNameField.text, newUserFullNameField.text);
                            newUserNameField.text = "";
                            newUserFullNameField.text = "";
                        }
                    }
                }
            }

            StyledText {
                visible: newUserNameField.text.length > 0 && !addUserButton.validName
                text: I18n.tr("Usernames start with a lowercase letter or underscore, then only lowercase letters/digits/-/_.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.error
            }

            StyledText {
                visible: addUserButton.alreadyExists
                text: I18n.tr("A user with that name already exists.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.error
            }
        }
    }

    Repeater {
        model: root.vm.usersLoading ? [] : root.usersList

        SettingsCard {
            id: userCard
            required property var modelData
            title: modelData.fullName.length > 0 ? modelData.fullName : modelData.name
            icon: "person"
            width: parent.width

            // --- remove ---
            Row {
                width: parent.width
                Item { width: parent.width - removeButton.width; height: 1 }

                StyledRect {
                    id: removeButton
                    property bool confirming: false
                    width: confirming ? 150 : 90
                    height: 30
                    radius: Theme.cornerRadius
                    color: confirming ? Theme.error : Theme.surfaceContainerHigh
                    Behavior on width { NumberAnimation { duration: 100 } }

                    StyledText {
                        anchors.centerIn: parent
                        text: removeButton.confirming ? I18n.tr("Confirm Remove") : I18n.tr("Remove")
                        font.pixelSize: Theme.fontSizeSmall
                        color: removeButton.confirming ? "#FFFFFF" : Theme.error
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (removeButton.confirming) {
                                root.vm.removeUser(userCard.modelData.name);
                            } else {
                                removeButton.confirming = true;
                                removeConfirmTimer.restart();
                            }
                        }
                    }

                    Timer {
                        id: removeConfirmTimer
                        interval: 4000
                        onTriggered: removeButton.confirming = false
                    }
                }
            }

            StyledText {
                visible: removeButton.confirming
                text: I18n.tr("Deletes this account from _config.nix - it's actually removed from the machine on the next rebuild, not before.")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.error
                wrapMode: Text.WordWrap
                width: parent.width
            }

            Rectangle { width: parent.width; height: 1; color: Theme.outline; opacity: 0.2 }

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
                            // DankTextField's own eye button only flips its
                            // `passwordVisible` property - it never touches
                            // echoMode itself (checked its source directly:
                            // no internal binding from one to the other, in
                            // this dms pin), so a hardcoded
                            // `echoMode: TextInput.Password` clicks the eye
                            // but never reveals anything. Bind echoMode to
                            // passwordVisible instead - the wiring the
                            // component clearly expects the caller to do.
                            echoMode: secretField.passwordVisible ? TextInput.Normal : TextInput.Password
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
                        echoMode: newPasswordField.passwordVisible ? TextInput.Normal : TextInput.Password
                        showPasswordToggle: true
                        placeholderText: I18n.tr("New password")
                    }

                    DankTextField {
                        id: confirmPasswordField
                        width: (parent.width - setPasswordButton.width - Theme.spacingS * 2) / 2
                        echoMode: confirmPasswordField.passwordVisible ? TextInput.Normal : TextInput.Password
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
