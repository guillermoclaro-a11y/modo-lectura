import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_minutes: minutesSpin.value
    property alias cfg_lockScreen: lockCheck.checked
    property alias cfg_playSound: soundCheck.checked
    property alias cfg_announceProgress: announceCheck.checked
    property alias cfg_sites: sitesArea.text
    property int cfg_minutesDefault
    property bool cfg_lockScreenDefault
    property bool cfg_playSoundDefault
    property bool cfg_announceProgressDefault
    property string cfg_sitesDefault

    readonly property var presets: [
        { label: "YouTube", sites: ["youtube.com", "m.youtube.com", "music.youtube.com", "youtu.be", "youtube-nocookie.com", "youtubei.googleapis.com"] },
        { label: "Instagram", sites: ["instagram.com", "cdninstagram.com"] },
        { label: "TikTok", sites: ["tiktok.com", "tiktokv.com", "tiktokcdn.com"] },
        { label: "Facebook", sites: ["facebook.com", "m.facebook.com", "fb.com"] },
        { label: "X / Twitter", sites: ["x.com", "twitter.com", "t.co"] },
        { label: "Reddit", sites: ["reddit.com", "old.reddit.com", "redd.it"] },
        { label: "Netflix", sites: ["netflix.com"] },
        { label: "Twitch", sites: ["twitch.tv", "m.twitch.tv"] }
    ]
    readonly property var domainRe: /^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$/

    function siteList() {
        return sitesArea.text.toLowerCase().split(/[\s,]+/).filter(s => s.length > 0)
    }
    function invalidSites() {
        return siteList().filter(s => !domainRe.test(s))
    }
    function addPreset(list) {
        var cur = siteList()
        list.forEach(s => { if (cur.indexOf(s) === -1) cur.push(s) })
        sitesArea.text = cur.join("\n")
    }

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: minutesSpin
            Kirigami.FormData.label: i18n("Default duration (minutes):")
            from: 1; to: 240
            Accessible.name: i18n("Default duration in minutes")
        }

        QQC2.CheckBox {
            id: lockCheck
            Kirigami.FormData.label: i18n("When a session starts:")
            text: i18n("Lock the screen")
        }

        QQC2.CheckBox {
            id: soundCheck
            Kirigami.FormData.label: i18n("When time is up:")
            text: i18n("Play an alarm sound")
        }
        QQC2.Label {
            text: i18n("A notification that stays on screen is always shown.")
            font: Kirigami.Theme.smallFont
            opacity: 0.75
            wrapMode: Text.WordWrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
        }

        QQC2.CheckBox {
            id: announceCheck
            Kirigami.FormData.label: i18n("Screen reader:")
            text: i18n("Announce the remaining time every 5 minutes")
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.TextArea {
            id: sitesArea
            Kirigami.FormData.label: i18n("Sites to block:")
            Layout.minimumWidth: Kirigami.Units.gridUnit * 18
            Layout.minimumHeight: Kirigami.Units.gridUnit * 8
            wrapMode: TextEdit.NoWrap
            Accessible.name: i18n("Sites to block, one per line")
        }
        QQC2.Label {
            text: i18n("One site per line, without http:// (for example: instagram.com). The www. version is blocked too.")
            font: Kirigami.Theme.smallFont
            opacity: 0.75
            wrapMode: Text.WordWrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
        }
        QQC2.Label {
            readonly property var bad: page.invalidSites()
            visible: bad.length > 0
            text: i18n("These entries are not valid sites and will be ignored: %1", bad.join(", "))
            color: Kirigami.Theme.negativeTextColor
            wrapMode: Text.WordWrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
            Accessible.role: Accessible.AlertMessage
        }

        Flow {
            Kirigami.FormData.label: i18n("Add:")
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
            spacing: Kirigami.Units.smallSpacing
            Repeater {
                model: page.presets
                QQC2.Button {
                    text: modelData.label
                    icon.name: "list-add"
                    onClicked: page.addPreset(modelData.sites)
                    Accessible.name: i18n("Add %1 to the blocked sites", modelData.label)
                }
            }
        }
    }
}
