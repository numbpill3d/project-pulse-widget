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
    property var snapshot: ({
        generated: "awaiting ledger",
        counts: ({ active: 0, stale: 0, paused: 0, blocked: 0, completed: 0 }),
        recent: [],
        projects: []
    })

    FontLoader {
        id: pixelHeader
        source: "file:///home/scorn/cityplex/public/fonts/pixelify-700.woff2"
    }

    Layout.minimumWidth: 400
    Layout.maximumWidth: 400
    Layout.minimumHeight: 68
    Layout.maximumHeight: 68
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    function refresh() {
        var script = decodeURIComponent(Qt.resolvedUrl("../../scripts/pulse.py").toString().replace(/^file:\/\//, ""))
        source.connectSource("python3 \"" + script + "\"")
    }

    function parse(stdout) {
        try {
            root.snapshot = JSON.parse(stdout)
        } catch (error) {
            console.log("Project Pulse parse error: " + error)
        }
    }

    function traceLine() {
        var active = Number(root.snapshot.counts.active) || 0
        var stale = Number(root.snapshot.counts.stale) || 0
        var width = 40
        var cursor = Math.floor(root.phase) % width
        var line = ""
        for (var i = 0; i < width; i++) {
            if (i === cursor) line += "|"
            else if (i < Math.min(active, width)) line += "#"
            else if (i < Math.min(active + stale, width)) line += "+"
            else line += "."
        }
        return line
    }

    function focusLine() {
        var projects = root.snapshot.projects || []
        if (!projects.length) return "NO PROJECT TRACE"
        var index = Math.floor(root.phase / 12) % projects.length
        var project = projects[index]
        return project.title.toUpperCase().slice(0, 28) + " / " + project.status.toUpperCase()
    }

    P5Support.DataSource {
        id: source
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            if (data["exit code"] === 0 && data.stdout) root.parse(data.stdout)
            disconnectSource(sourceName)
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        interval: 180
        running: true
        repeat: true
        onTriggered: root.phase += 1
    }

    Component.onCompleted: root.refresh()
    preferredRepresentation: fullRepresentation

    fullRepresentation: Item {
        id: strip
        width: 400
        height: 68
        Layout.minimumWidth: 400
        Layout.maximumWidth: 400
        Layout.minimumHeight: 68
        Layout.maximumHeight: 68

        Rectangle { x: 0; y: 0; width: 2; height: parent.height; color: root.red; opacity: 0.75 + (Math.sin(root.phase * 0.4) + 1) * 0.1 }
        Rectangle { x: 0; y: parent.height - 1; width: parent.width; height: 1; color: root.dim }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 3
            anchors.topMargin: 2
            anchors.bottomMargin: 2
            spacing: 1

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "PROJECT_PULSE"
                    color: root.ink
                    style: Text.Outline
                    styleColor: root.red
                    font.family: pixelHeader.status === FontLoader.Ready ? pixelHeader.name : "monospace"
                    font.pixelSize: 12
                    font.bold: true
                    Layout.fillWidth: true
                }
                Text { text: "A" + (root.snapshot.counts.active || 0) + " S" + (root.snapshot.counts.stale || 0) + " B" + (root.snapshot.counts.blocked || 0) + " D" + (root.snapshot.counts.completed || 0); color: root.ink; font.family: "monospace"; font.pixelSize: 8 }
                Text { text: "LIVE"; color: root.red; font.family: "monospace"; font.pixelSize: 8; opacity: 0.55 + (Math.sin(root.phase * 0.8) + 1) * 0.2 }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "TRACE["; color: root.dim; font.family: "monospace"; font.pixelSize: 8 }
                Text { text: root.traceLine(); color: root.red; font.family: "monospace"; font.pixelSize: 8; Layout.fillWidth: true }
                Text { text: "]"; color: root.dim; font.family: "monospace"; font.pixelSize: 8 }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: ">"; color: root.red; font.family: "monospace"; font.pixelSize: 8 }
                Text { text: root.focusLine(); color: root.ink; font.family: "monospace"; font.pixelSize: 8; elide: Text.ElideRight; Layout.fillWidth: true }
                Text { text: "[R]"; color: root.red; font.family: "monospace"; font.pixelSize: 8 }
            }
        }

        MouseArea { anchors.fill: parent; onClicked: root.refresh() }
    }
}
