/*
 * Modo lectura — Plasma 6 widget.
 * Starts/ends distraction-free reading sessions through contents/code/modo-lectura:
 * blocks the configured sites, mutes notifications, locks the screen and
 * signals the end of the session.
 *
 * SPDX-License-Identifier: MIT
 */
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string script: Qt.resolvedUrl("../code/modo-lectura").toString().replace("file://", "")
    readonly property var domainRe: /^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$/

    property bool installed: true
    property bool active: false
    property int endEpoch: 0
    property int sessionMinutes: 0
    property int remaining: 0                 // seconds
    property int chosenMinutes: Plasmoid.configuration.minutes
    property string error: ""
    property bool busy: false
    property int lastAnnouncedMinute: -1

    preferredRepresentation: compactRepresentation
    Plasmoid.icon: "accessories-dictionary"
    Plasmoid.status: active ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus
    toolTipMainText: i18n("Reading mode")
    toolTipSubText: active ? i18n("Reading — %1 left\nSites blocked", clock(remaining))
                           : i18n("Click to start a reading session")

    // --- Formatting -------------------------------------------------------
    function clock(s) {
        var m = Math.floor(s / 60), r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
    }
    // Spoken form for screen readers: "12 minutes 5 seconds left".
    function spoken(s) {
        var m = Math.floor(s / 60), r = s % 60
        if (m > 0 && r > 0) return i18np("%1 minute", "%1 minutes", m) + " " + i18np("%1 second", "%1 seconds", r)
        if (m > 0) return i18np("%1 minute", "%1 minutes", m)
        return i18np("%1 second", "%1 seconds", r)
    }
    function announce(text) {
        try { root.Accessible.announce(text) } catch (e) { /* Qt < 6.8 */ }
    }
    function sites() {
        return Plasmoid.configuration.sites.toLowerCase().split(/[\s,]+/)
            .filter(s => domainRe.test(s))
    }

    function tick() {
        if (!active) return
        remaining = Math.max(0, endEpoch - Math.floor(Date.now() / 1000))
        var min = Math.ceil(remaining / 60)
        if (Plasmoid.configuration.announceProgress && remaining > 0
                && min % 5 === 0 && remaining % 60 === 0 && min !== lastAnnouncedMinute) {
            lastAnnouncedMinute = min
            announce(i18n("%1 left", spoken(remaining)))
        }
        if (remaining === 0) {
            active = false
            announce(i18n("Reading session finished. Take a break."))
            refresh()
        }
    }

    // --- Commands ---------------------------------------------------------
    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source)
            var r
            try { r = JSON.parse(data["stdout"].trim().split("\n").pop()) }
            catch (e) { r = { ok: false, error: (data["stderr"] || i18n("Unexpected response")).trim() } }

            if (source.indexOf("' status") !== -1) {
                if (r.ok) {
                    root.installed = r.installed
                    root.active = r.active
                    if (r.active) {
                        root.endEpoch = r.end
                        root.sessionMinutes = r.minutes
                        root.tick()
                    }
                }
                return
            }
            root.busy = false
            root.error = r.ok ? "" : (r.error || i18n("Unknown error"))
            if (!r.ok) {
                root.announce(root.error)
            } else if (source.indexOf("# setup ") !== -1) {
                root.announce(i18n("Setup finished"))
            } else if (source.indexOf("' start ") !== -1) {
                root.announce(i18n("Reading session started: %1", root.spoken(root.chosenMinutes * 60)))
                root.expanded = false
            } else {
                root.announce(i18n("Reading session ended"))
            }
            root.refresh()
        }
    }
    // A trailing comment makes every command string unique for the data engine.
    function run(args) { exec.connectSource("'" + script + "' " + args + " # " + Date.now()) }
    function refresh() { run("status") }
    function start() {
        var list = sites()
        if (list.length === 0) {
            error = i18n("There are no sites to block. Add some in the widget settings.")
            announce(error)
            return
        }
        busy = true; error = ""; lastAnnouncedMinute = -1
        run("start " + chosenMinutes
            + (Plasmoid.configuration.lockScreen ? "" : " --no-lock")
            + (Plasmoid.configuration.playSound ? "" : " --no-sound")
            + " --sites '" + list.join(" ") + "'")
    }
    function stop() { busy = true; error = ""; run("stop") }
    function installSystem() {
        busy = true; error = ""
        var installer = script.replace(/modo-lectura$/, "install-system.sh")
        exec.connectSource("pkexec /bin/bash '" + installer + "' >/dev/null 2>&1"
            + " && echo '{\"ok\":true}' || echo '{\"ok\":false,\"error\":\"" + i18n("The setup was cancelled or failed.") + "\"}'"
            + " # setup " + Date.now())
    }

    Timer { interval: 1000; running: root.active; repeat: true; onTriggered: root.tick() }
    Timer { interval: 10000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

    // --- Panel icon -------------------------------------------------------
    compactRepresentation: MouseArea {
        id: compact
        Layout.minimumWidth: row.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        hoverEnabled: true
        activeFocusOnTab: true
        onClicked: root.expanded = !root.expanded
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.expanded = !root.expanded
                event.accepted = true
            }
        }

        Accessible.role: Accessible.Button
        Accessible.name: i18n("Reading mode")
        Accessible.description: root.active ? i18n("%1 left", root.spoken(root.remaining))
                                            : i18n("Start a reading session")
        Accessible.onPressAction: root.expanded = !root.expanded

        Rectangle {
            anchors.fill: parent
            visible: compact.activeFocus
            color: "transparent"
            border.color: Kirigami.Theme.focusColor
            border.width: 2
            radius: Kirigami.Units.cornerRadius
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing
            Kirigami.Icon {
                source: "accessories-dictionary"
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Layout.preferredWidth
                active: compact.containsMouse || compact.activeFocus
            }
            PlasmaComponents.Label {
                visible: root.active
                text: root.clock(root.remaining)
                font.bold: true
                font.features: { "tnum": 1 }
                Accessible.ignored: true
            }
        }
    }

    // --- Popup ------------------------------------------------------------
    fullRepresentation: PlasmaExtras.Representation {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 17
        Layout.minimumHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2
        collapseMarginsHint: true

        header: PlasmaExtras.PlasmoidHeading {
            RowLayout {
                anchors.fill: parent
                Kirigami.Heading {
                    level: 3
                    text: i18n("Reading mode")
                    Layout.fillWidth: true
                }
                PlasmaComponents.ToolButton {
                    icon.name: "configure"
                    display: QQC2.AbstractButton.IconOnly
                    text: i18n("Settings: sites, sound and screen lock")
                    onClicked: Plasmoid.internalAction("configure").trigger()
                    PlasmaComponents.ToolTip { text: parent.text }
                }
            }
        }

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            // System part missing
            ColumnLayout {
                visible: !root.installed
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: i18n("To block sites, Reading mode needs a small one-time system setup. Your administrator password will be requested.")
                    Accessible.role: Accessible.AlertMessage
                }
                PlasmaComponents.Button {
                    Layout.alignment: Qt.AlignHCenter
                    icon.name: "run-install"
                    text: i18n("Set up now")
                    enabled: !root.busy
                    onClicked: root.installSystem()
                }
            }

            // --- Active session ---
            ColumnLayout {
                visible: root.active
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.clock(root.remaining)
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 3
                    font.bold: true
                    font.features: { "tnum": 1 }
                    Accessible.role: Accessible.StaticText
                    Accessible.name: i18n("%1 left", root.spoken(root.remaining))
                }
                PlasmaComponents.ProgressBar {
                    Layout.fillWidth: true
                    from: 0; to: Math.max(1, root.sessionMinutes * 60)
                    value: to - root.remaining
                    Accessible.name: i18n("Session progress")
                }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    opacity: 0.8
                    text: i18n("Sites blocked · notifications muted")
                }
                PlasmaComponents.Button {
                    Layout.alignment: Qt.AlignHCenter
                    icon.name: "media-playback-stop"
                    text: i18n("End now")
                    enabled: !root.busy
                    onClicked: root.stop()
                    Accessible.description: i18n("Unblocks the sites and turns notifications back on")
                }
            }

            // --- No session ---
            ColumnLayout {
                visible: !root.active && root.installed
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    id: durationLabel
                    text: i18n("How long will you read?")
                    opacity: 0.8
                }
                RowLayout {
                    Layout.fillWidth: true
                    Accessible.role: Accessible.Grouping
                    Accessible.name: durationLabel.text
                    QQC2.ButtonGroup { id: durations }
                    Repeater {
                        model: [15, 25, 45, 60]
                        PlasmaComponents.Button {
                            Layout.fillWidth: true
                            text: i18nc("short form, e.g. 25 min", "%1 min", modelData)
                            checkable: true
                            checked: root.chosenMinutes === modelData
                            QQC2.ButtonGroup.group: durations
                            onClicked: root.chosenMinutes = modelData
                            Accessible.name: i18np("%1 minute", "%1 minutes", modelData)
                        }
                    }
                }
                RowLayout {
                    PlasmaComponents.Label { text: i18n("Other:"); opacity: 0.8 }
                    PlasmaComponents.SpinBox {
                        from: 1; to: 240
                        value: root.chosenMinutes
                        onValueModified: root.chosenMinutes = value
                        Accessible.name: i18n("Duration in minutes")
                    }
                    PlasmaComponents.Label { text: i18nc("minutes", "min"); opacity: 0.8 }
                }
                PlasmaComponents.CheckBox {
                    text: i18n("Lock the screen when starting")
                    checked: Plasmoid.configuration.lockScreen
                    onToggled: Plasmoid.configuration.lockScreen = checked
                }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.7
                    font: Kirigami.Theme.smallFont
                    text: i18np("Blocks 1 site.", "Blocks %1 sites.", root.sites().length)
                          + " " + root.sites().slice(0, 3).join(", ")
                          + (root.sites().length > 3 ? "…" : "")
                }
                PlasmaComponents.Button {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    icon.name: "media-playback-start"
                    text: i18n("Start reading")
                    enabled: !root.busy
                    onClicked: root.start()
                    Accessible.description: i18n("Blocks the sites and mutes notifications for %1", root.spoken(root.chosenMinutes * 60))
                }
            }

            PlasmaComponents.Label {
                visible: root.error !== ""
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Kirigami.Theme.negativeTextColor
                text: root.error
                Accessible.role: Accessible.AlertMessage
            }
        }
    }
}
