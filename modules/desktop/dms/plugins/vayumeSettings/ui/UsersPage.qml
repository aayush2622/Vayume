import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    required property var vm
    width: parent.width
    spacing: Vayori.gap

    readonly property var secretFields: [
        { key: "WAKATIME_API_KEY", label: I18n.tr("WakaTime API Key"), description: I18n.tr("Used by the Vscode/Zed/AndroidStudio WakaTime integration.") },
        { key: "RBW_EMAIL", label: I18n.tr("Bitwarden (rbw) Email"), description: I18n.tr("Used by Bitwarden.nix's rbw config.") }
    ]

    readonly property var usersList: {
        const names = Object.keys(root.vm.users).sort();
        return names.map(n => Object.assign({ name: n }, root.vm.users[n]));
    }

    readonly property string meta: root.vm.usersLoading ? "" : I18n.tr("%1 account(s) · changes apply on rebuild").arg(root.usersList.length)

    component LabeledToggle: Item {
        id: line
        property string label: ""
        property string hint: ""
        property bool checked: false
        signal toggled(bool value)

        height: 30
        implicitWidth: lineToggle.width + 10 + lineLabel.implicitWidth + (lineHint.visible ? lineHint.implicitWidth + 8 : 0)

        Toggle {
            id: lineToggle
            checked: line.checked
            enabled: line.enabled
            anchors.verticalCenter: parent.verticalCenter
            onToggled: value => line.toggled(value)
        }

        StyledText {
            id: lineLabel
            x: lineToggle.width + 10
            width: Math.min(implicitWidth, line.width - x)
            anchors.verticalCenter: parent.verticalCenter
            text: line.label
            isMonospace: true
            font.pixelSize: Vayori.body
            color: line.checked ? Vayori.ink : Vayori.inkMuted
            wrapMode: Text.NoWrap

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: lineToggle.flip()
            }
        }

        StyledText {
            id: lineHint
            visible: line.hint.length > 0
            anchors.left: lineLabel.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: line.hint
            font.pixelSize: Vayori.micro
            color: Theme.warning
            wrapMode: Text.NoWrap
        }
    }

    Notice {
        tone: "warning"
        text: I18n.tr("Display name and app secrets are cosmetic/per-app; groups and password control real access to this machine - double-check before changing either, especially \"wheel\" (sudo/admin).")
    }

    Notice {
        visible: root.vm.usersLoading
        text: I18n.tr("Loading users...")
        busy: true
    }

    SettingsCard {
        title: I18n.tr("Add User")

        SettingItem {
            id: addUserItem
            stacked: true
            description: I18n.tr("Starts with no password (falls back to \"changeme\") and the default groups (networkmanager, video, input) - set those below once added.")

            readonly property bool validName: /^[a-z_][a-z0-9_-]*$/.test(newUserNameField.text)
            readonly property bool alreadyExists: newUserNameField.text in root.vm.users
            readonly property bool canSubmit: validName && !alreadyExists && !root.vm.usersSaving

            notes: [
                StyledText {
                    visible: newUserNameField.text.length > 0 && !addUserItem.validName
                    text: I18n.tr("Usernames start with a lowercase letter or underscore, then only lowercase letters/digits/-/_.")
                    width: parent ? parent.width : 0
                    font.pixelSize: Vayori.body
                    color: Theme.error
                    wrapMode: Text.WordWrap
                    elide: Text.ElideNone
                },
                StyledText {
                    visible: addUserItem.alreadyExists
                    text: I18n.tr("A user with that name already exists.")
                    font.pixelSize: Vayori.body
                    color: Theme.error
                    wrapMode: Text.NoWrap
                }
            ]

            Field {
                id: newUserNameField
                width: (parent.width - addUserButton.width - 16) * 0.45
                placeholderText: I18n.tr("username")
            }

            Field {
                id: newUserFullNameField
                width: (parent.width - addUserButton.width - 16) * 0.55
                placeholderText: I18n.tr("Full name (optional)")
            }

            TextButton {
                id: addUserButton
                variant: "primary"
                icon: "person_add"
                text: I18n.tr("Add User")
                enabled: addUserItem.canSubmit
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    root.vm.addUser(newUserNameField.text, newUserFullNameField.text);
                    newUserNameField.text = "";
                    newUserFullNameField.text = "";
                }
            }
        }
    }

    SettingsCard {
        title: I18n.tr("Add a Package")
        meta: root.vm.packageSearchResults.length > 0 ? I18n.tr("%1 results").arg(root.vm.packageSearchResults.length) : ""

        SettingItem {
            stacked: true
            description: I18n.tr("Searches this flake's own pinned nixpkgs, not a system channel - a result here is guaranteed addable. The first search after a nixpkgs update can take a while to build its index; every one after is fast.")

            notes: StyledText {
                visible: root.vm.packageSearchError.length > 0
                text: root.vm.packageSearchError
                width: parent ? parent.width : 0
                font.pixelSize: Vayori.body
                color: Theme.error
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
            }

            Field {
                id: packageSearchField
                width: parent.width - packageUserPicker.width - searchButton.width - 16
                leftIconName: "search"
                placeholderText: I18n.tr("package name")
                onEditingFinished: if (text.length > 0) root.vm.searchPackages(text)
            }

            Select {
                id: packageUserPicker
                width: 150
                currentValue: root.usersList.length > 0 ? root.usersList[0].name : ""
                options: root.usersList.map(u => u.name)
                emptyText: I18n.tr("No users")
                anchors.verticalCenter: parent.verticalCenter
                onValueChanged: value => currentValue = value
            }

            TextButton {
                id: searchButton
                text: root.vm.packageSearching ? I18n.tr("Searching") : I18n.tr("Search")
                busy: root.vm.packageSearching
                enabled: packageSearchField.text.length > 0
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.vm.searchPackages(packageSearchField.text)
            }
        }

        Repeater {
            model: root.vm.packageSearchResults

            SettingItem {
                id: resultRow
                required property var modelData
                readonly property var targetUser: root.vm.users[packageUserPicker.currentValue]
                readonly property bool alreadyAdded: targetUser !== undefined && modelData.path in (targetUser.packages ?? {})
                readonly property bool canAdd: packageUserPicker.currentValue.length > 0 && !alreadyAdded

                title: modelData.path
                description: modelData.description
                meta: modelData.version.length > 0 ? modelData.version : ""

                TextButton {
                    width: 84
                    icon: resultRow.alreadyAdded ? "check" : "add"
                    text: resultRow.alreadyAdded ? I18n.tr("Added") : I18n.tr("Add")
                    enabled: resultRow.canAdd
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: root.vm.setUserPackage(packageUserPicker.currentValue, resultRow.modelData.path, true)
                }
            }
        }
    }

    Repeater {
        model: root.vm.usersLoading ? [] : root.usersList

        SettingsCard {
            id: userCard
            required property var modelData
            readonly property var packageNames: Object.keys(modelData.packages).sort()

            title: modelData.fullName.length > 0 ? modelData.fullName : modelData.name
            meta: "@" + modelData.name + (modelData.extraGroups.includes("wheel") ? " · wheel" : "")
            collapsible: true
            collapsed: false

            SettingItem {
                title: I18n.tr("Display Name")
                description: I18n.tr("Cosmetic only - GECOS/login display name.")

                Field {
                    id: nameField
                    width: userCard.width < 640 ? 200 : 260
                    anchors.verticalCenter: parent.verticalCenter
                    Component.onCompleted: text = userCard.modelData.fullName
                    onEditingFinished: {
                        if (text !== userCard.modelData.fullName) root.vm.setUserFullName(userCard.modelData.name, text);
                    }
                }
            }

            SettingItem {
                stacked: true
                title: I18n.tr("Groups")
                description: I18n.tr("Takes effect on the next rebuild, like everything else here. \"wheel\" grants full sudo/admin access.")

                Flow {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.vm.groupOptions

                        LabeledToggle {
                            id: groupLine
                            required property string modelData
                            width: 190
                            label: modelData
                            hint: modelData === "wheel" ? I18n.tr("admin") : ""
                            checked: userCard.modelData.extraGroups.includes(modelData)
                            onToggled: value => root.vm.setUserGroup(userCard.modelData.name, groupLine.modelData, value)
                        }
                    }
                }
            }

            SettingItem {
                stacked: true
                title: I18n.tr("Extra Packages")
                description: I18n.tr("Added via the search above - toggling one off disables it without losing track of it, so it's a click to bring back rather than a re-search. Takes effect on the next rebuild.")

                notes: StyledText {
                    visible: userCard.packageNames.length === 0
                    text: I18n.tr("None yet.")
                    isMonospace: true
                    font.pixelSize: Vayori.micro
                    color: Vayori.inkGhost
                    wrapMode: Text.NoWrap
                }

                Flow {
                    visible: userCard.packageNames.length > 0
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: userCard.packageNames

                        LabeledToggle {
                            id: packageLine
                            required property string modelData
                            width: Math.min(implicitWidth + 24, parent.width)
                            label: modelData
                            checked: userCard.modelData.packages[modelData]
                            onToggled: value => root.vm.setUserPackage(userCard.modelData.name, packageLine.modelData, value)
                        }
                    }
                }
            }

            Repeater {
                model: root.secretFields

                SettingItem {
                    id: secretRow
                    required property var modelData
                    title: modelData.label
                    description: modelData.description
                    meta: modelData.key

                    Field {
                        id: secretField
                        width: userCard.width < 640 ? 200 : 260
                        anchors.verticalCenter: parent.verticalCenter
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

            SettingItem {
                id: passwordItem
                stacked: true
                title: I18n.tr("Password")

                readonly property bool mismatch: newPasswordField.text.length > 0 && confirmPasswordField.text.length > 0
                    && newPasswordField.text !== confirmPasswordField.text
                readonly property bool canSubmit: newPasswordField.text.length > 0 && newPasswordField.text === confirmPasswordField.text

                tags: Badge {
                    label: userCard.modelData.hasPassword ? I18n.tr("Set") : I18n.tr("Falls back to \"changeme\"")
                    tone: userCard.modelData.hasPassword ? "success" : "warning"
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                }

                notes: StyledText {
                    visible: passwordItem.mismatch
                    text: I18n.tr("Passwords don't match.")
                    font.pixelSize: Vayori.body
                    color: Theme.error
                    wrapMode: Text.NoWrap
                }

                Field {
                    id: newPasswordField
                    width: (parent.width - setPasswordButton.width - 16) / 2
                    echoMode: newPasswordField.passwordVisible ? TextInput.Normal : TextInput.Password
                    showPasswordToggle: true
                    placeholderText: I18n.tr("New password")
                }

                Field {
                    id: confirmPasswordField
                    width: (parent.width - setPasswordButton.width - 16) / 2
                    echoMode: confirmPasswordField.passwordVisible ? TextInput.Normal : TextInput.Password
                    showPasswordToggle: true
                    placeholderText: I18n.tr("Confirm password")
                }

                TextButton {
                    id: setPasswordButton
                    variant: "primary"
                    text: I18n.tr("Set Password")
                    enabled: passwordItem.canSubmit
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {
                        root.vm.setUserPassword(userCard.modelData.name, newPasswordField.text);
                        newPasswordField.text = "";
                        confirmPasswordField.text = "";
                    }
                }
            }

            SettingItem {
                id: removeItem
                property bool confirming: false
                title: I18n.tr("Remove account")
                description: I18n.tr("Deletes this account from _config.nix - it's actually removed from the machine on the next rebuild, not before.")
                marker: removeItem.confirming ? "error" : ""

                Timer {
                    id: removeConfirmTimer
                    interval: 4000
                    onTriggered: removeItem.confirming = false
                }

                TextButton {
                    variant: "danger"
                    icon: removeItem.confirming ? "priority_high" : "person_remove"
                    text: removeItem.confirming ? I18n.tr("Confirm Remove") : I18n.tr("Remove")
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {
                        if (removeItem.confirming) {
                            root.vm.removeUser(userCard.modelData.name);
                        } else {
                            removeItem.confirming = true;
                            removeConfirmTimer.restart();
                        }
                    }
                }
            }
        }
    }

    Notice {
        text: root.vm.usersStatus
        tone: root.vm.usersError ? "error" : "neutral"
    }
}
