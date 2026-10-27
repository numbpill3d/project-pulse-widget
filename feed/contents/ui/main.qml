pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root
    readonly property color ink: "#f3f0df"
    readonly property color dim: "#77766f"
    readonly property color red: "#e3293b"
    property real phase: 0
    property var snapshot: ({ projects: [] })

    Layout.minimumWidth: 400
    Layout.maximumWidth: 400
    Layout.minimumHeight: 126
    Layout.maximumHeight: 126
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    function refresh() {
        var script = decodeURIComponent(Qt.resolvedUrl("../../scripts/pulse.py").toString().replace(/^file:\/\//, ""))
        source.connectSource("python3 \"" + script + "\"")
    }
    function statusMark(status) {
        if (status === "active") return "!"
        if (status === "blocked") return "X"
        if (status === "paused") return "="
        return "~"
    }

    P5Support.DataSource {
        id: source
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            if (data["exit code"] === 0 && data.stdout) {
                try { root.snapshot = JSON.parse(data.stdout) }
                catch (error) { console.log("Project Pulse Feed parse error: " + error) }
            }
            disconnectSource(sourceName)
        }
    }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.refresh() }
    Timer { interval: 220; running: true; repeat: true; onTriggered: root.phase += 1 }
    Component.onCompleted: root.refresh()
    preferredRepresentation: fullRepresentation

    fullRepresentation: Item {
        width: 400
        height: 126
        Rectangle { width: parent.width; height: 1; color: root.red; opacity: 0.85 }
        Rectangle { x: 8; width: 1; height: 8; color: root.red }
        Rectangle { x: 391; width: 1; height: 8; color: root.red }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.topMargin: 6
            anchors.bottomMargin: 4
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                Text { text: "PULSE_FEED // LEDGER SIGNALS"; color: root.dim; font.family: "monospace"; font.pixelSize: 8; Layout.fillWidth: true }
                Text { text: "03"; color: root.red; font.family: "monospace"; font.pixelSize: 8 }
            }

            Repeater {
                model: Math.min((root.snapshot.projects || []).length, 3)
                delegate: Rectangle {
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    color: "#090909"
                    border.width: 1
                    border.color: index === Math.floor(root.phase / 8) % 3 ? root.red : "#393939"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 6
                        Text { text: root.statusMark(root.snapshot.projects[index].status); color: root.red; font.family: "monospace"; font.pixelSize: 11; font.bold: true }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text { text: String(root.snapshot.projects[index].title).toUpperCase(); color: root.ink; font.family: "monospace"; font.pixelSize: 8; elide: Text.ElideRight; Layout.fillWidth: true }
                            Text { text: String(root.snapshot.projects[index].status).toUpperCase() + " // " + root.snapshot.projects[index].age + "D // " + root.snapshot.projects[index].events + " EVENTS"; color: root.dim; font.family: "monospace"; font.pixelSize: 7; Layout.fillWidth: true }
                        }
                        Text { text: ">"; color: root.red; font.family: "monospace"; font.pixelSize: 8 }
                    }
                }
            }
        }
    }
}
