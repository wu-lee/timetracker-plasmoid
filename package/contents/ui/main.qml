// -*- javascript -*-
import QtQuick 2.3
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.0 as QtControls
import QtGraphicalEffects 1.12

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 2.0 as PlasmaComponents

Item {
    id: root

    property var startIconSource: plasmoid.file("", "icons/start-light.svg")
    property string clock_fontfamily: plasmoid.configuration.clock_fontfamily || "Noto Mono"
    property var timeText: "0:00"
    
    // Initial size of the window in gridUnits
    width: units.gridUnit * 28
    height: units.gridUnit * 20

    Plasmoid.switchWidth: units.gridUnit * 11
    Plasmoid.switchHeight: units.gridUnit * 11

    //    Plasmoid.expanded: mouseArea.containsMouse

    
    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
    Plasmoid.status: PlasmaCore.Types.PassiveStatus
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground

    // From https://github.com/Zren/plasma-applet-commandoutput/blob/master/package/contents/ui/main.qml
	// https://github.com/KDE/plasma-workspace/blob/master/dataengines/executable/executable.h
	// https://github.com/KDE/plasma-workspace/blob/master/dataengines/executable/executable.cpp
	// https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/core/datasource.h
	// https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/core/datasource.cpp
	// https://github.com/KDE/plasma-framework/blob/master/src/plasma/scripting/dataenginescript.cpp
	PlasmaCore.DataSource {
		id: executable
		engine: "executable"
		connectedSources: []
		onNewData: {
			var exitCode = data["exit code"]
			var exitStatus = data["exit status"]
			var stdout = data["stdout"]
			var stderr = data["stderr"]
			exited("banana", sourceName, exitCode, exitStatus, stdout, stderr)
			disconnectSource(sourceName) // cmd finished
		}
		function exec(cmd) {
			if (cmd) {
				connectSource(cmd)
			}
		}
		signal exited(string cmdId, string cmd, int exitCode, int exitStatus, string stdout, string stderr)
	}

    Connections {
		target: executable
		onExited: {
			if (true) { //cmd == config.command) {
				var formattedText = stdout
				if (plasmoid.configuration.replaceAllNewlines) {
					formattedText = formattedText.replace('\n', ' ').trim()
				} else if (formattedText.length >= 1 && formattedText[formattedText.length-1] == '\n') {
					formattedText = formattedText.substr(0, formattedText.length-1)
				}
				console.log('[commandoutput]', 'stdout', cmdId, JSON.parse(stdout).count)
				// console.log('[commandoutput]', 'format', JSON.stringify(formattedText))
				//widget.outputText = formattedText
                
				if (config.waitForCompletion) {
					timer.restart()
				}
			}
		}
    }

    Plasmoid.compactRepresentation: MouseArea {
            id: compactRoot
            
            Layout.minimumWidth: units.iconSizes.small
            Layout.minimumHeight: units.iconSizes.small
            Layout.preferredHeight: Layout.minimumHeight
            Layout.maximumHeight: Layout.minimumHeight
            
//            Layout.preferredWidth: row.width //plasmoid.configuration.show_time_in_compact_mode ? row.width : root.width
            
            property int wheelDelta: 0
            
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        
        onClicked: {
            executable.exec("cat ~/data.json");
        }
        /*{    if (mouse.button == Qt.LeftButton) {
                plasmoid.expanded = !plasmoid.expanded
            } else {
                timer.running ? pause() : start()
            }
        }

        onWheel: {
            wheelDelta = scrollByWheel(wheelDelta, wheel.angleDelta.y);
        }*/

        RowLayout {
            id: row
            spacing: units.smallSpacing
            Layout.margins: units.smallSpacing
//            visible: plasmoid.configuration.show_time_in_compact_mode ? true : false

            width: parent.width
            height: parent.height
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            
            Item {
                Layout.preferredHeight: compactRoot.height
                Layout.preferredWidth: compactRoot.height
                Layout.fillHeight: true

                PlasmaCore.IconItem {
                    id: trayIconCompact
                    height: parent.height
                    width: parent.width
                    source: startIconSource
                    smooth: true
                    /*
                    layer {
                        enabled: true
                        effect: ColorOverlay {
                            color: "#0f0"
                        }
                    }*/
                }
            }

            
            PlasmaComponents.Label {
                visible: false //!plasmoid.configuration.show_time_in_compact_mode
                font.pointSize: -1
                font.pixelSize: compactRoot.height * 0.6
                fontSizeMode: Text.FixedSize
                font.family: clock_fontfamily
                text: timeText
                minimumPixelSize: 1
                Layout.alignment: Qt.AlignVCenter
//                color: getTextColor()
                smooth: true
            }
        }
/*
        Item {

            PlasmaCore.IconItem {
                id: trayIcon
                width: compactRoot.width
                height: compactRoot.height
                Layout.preferredWidth: height
                source: startIconSource
                smooth: true
            }

/ *            ColorOverlay {
                anchors.fill: trayIcon
                source: trayIcon
//                color: getTextColor()
            }* /
        }*/
/*
        function scrollByWheel(wheelDelta, eventDelta) {
            // magic number 120 for common "one click"
            // See: http://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
            wheelDelta += eventDelta;

            var increment = 0;

            while (wheelDelta >= 120) {
                wheelDelta -= 120;
                increment++;
            }

            while (wheelDelta <= -120) {
                wheelDelta += 120;
                increment--;
            }

            while (increment != 0) {
                if(increment > 0) {
                    shiftCountdown(60)
                } else {
                    shiftCountdown(-60)
                }

                updateTime()
                increment += (increment < 0) ? 1 : -1;
            }

            return wheelDelta;
        }
    }
*/
    }
        /*
    // We use a ColumnLayout to position and size the individual items
    ColumnLayout {

        // Our ColumnLayout is fills the parent item with a bit of margin
        anchors {
            fill: parent
            margins: units.largeSpacing
        }

        spacing: units.gridUnit

        // A title on top
        PlasmaExtras.Heading {
            level: 1 // from 1 to 5; level 1 is the size used for titles
            text: i18n("Hello Plasma World!")
        }

        // The central area is a rectangle
        Rectangle {
            // The id is used to reference this item from the
            // button's onClicked function
            id: colorRect

            // It's supposed to grow in both direction
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        // A button to change the color to blue or green
        QtControls.Button {

            // The button is aligned to the right
            Layout.alignment: Qt.AlignRight

            // The button's label, ready for translations
            text: i18n("Change Color")

            onClicked: {
                // Simply switch colors of the rectangle around
                if (colorRect.color != "#b0c4de") {
                    colorRect.color = "#b0c4de"; // lightsteelblue
                } else {
                    colorRect.color = "lightgreen";
                }
                // This message will end up being printed to the terminal
                print("Color is now " + colorRect.color);
            }
        }
    }

    // Overlay everything with a decorative, large, translucent icon
    PlasmaCore.IconItem {

        // We use an anchor layout and dpi-corrected sizing
        width: units.iconSizes.large * 4
        height: width
        anchors {
            left: parent.left
            bottom: parent.bottom
        }

        source: "akregator"
        opacity: 0.1
        }*/

    Plasmoid.fullRepresentation: Item {
        id: fullRoot

        Layout.minimumWidth: units.gridUnit * 12
        Layout.maximumWidth: units.gridUnit * 18
        Layout.minimumHeight: units.gridUnit * 11
        Layout.maximumHeight: units.gridUnit * 18

        Column {
/*            anchors {
                top: fullRoot.top
                left: fullRoot.left
                right: fullRoot.right
                bottom: buttonsRow.top
            }

            MouseArea {
                anchors.fill: parent
                property int wheelDelta: 0

                function scrollByWheel(wheelDelta, eventDelta) {
                    // magic number 120 for common "one click"
                    // See: http://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
                    wheelDelta += eventDelta;

                    var increment = 0;

                    while (wheelDelta >= 120) {
                        wheelDelta -= 120;
                        increment++;
                    }

                    while (wheelDelta <= -120) {
                        wheelDelta += 120;
                        increment--;
                    }

                    while (increment != 0) {
                        if(increment > 0) {
                            shiftCountdown(60)
                        } else {
                            shiftCountdown(-60)
                        }

                        updateTime()
                        increment += (increment < 0) ? 1 : -1;
                    }

                    return wheelDelta;
                }

                onWheel: {
                    wheelDelta = scrollByWheel(wheelDelta, wheel.angleDelta.y);
                }
            }
/*
            ProgressCircle {
                id: progressCircle
                anchors.centerIn: parent
                size: Math.min(parent.width / 1.4, parent.height / 1.4)
                colorCircle: getCircleColor()
                arcBegin: 0
                arcEnd: Math.ceil((countdownSeconds / maxSeconds) * 360)
                lineWidth: size / 30
            }
*/
            Column {
//                anchors.centerIn: parent
                height: time.height

                PlasmaComponents.Label {
                    id: time
                    text: timeText
//                    font.pointSize: progressCircle.width / 8
                    font.family: clock_fontfamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }
/*
                Controls.PageIndicator {
                    id: pageIndicator
                    count: 4
                    currentIndex: (stateVal - 1) / 2

                    anchors {
                        bottom: time.top
                        horizontalCenter: parent.horizontalCenter
                        bottomMargin: progressCircle.width / 15
                    }

                    spacing: progressCircle.width / 25
                    delegate: Rectangle {
                        implicitWidth: progressCircle.width / 34
                        implicitHeight: width
                        radius: width / 2
                        color: theme.textColor

                        opacity: index === pageIndicator.currentIndex ? 0.95 : 0.45

                        Behavior on opacity {
                            OpacityAnimator {
                                duration: 100
                            }
                        }
                    }
                }
*/
                PlasmaComponents.Label {
                    text: "status" //statusText
//                    font.pointSize: progressCircle.width / 24
//                    color: getTextColor()

                    anchors {
//                        top: time.bottom
                        horizontalCenter: parent.horizontalCenter
//                        topMargin: progressCircle.width / 20
                    }

                }
            }
        }

        RowLayout {
            id: buttonsRow
            spacing: 10

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
            }

            PlasmaComponents.Button {
                text: "Skip"
                implicitWidth: minimumWidth
                iconSource: "media-skip-forward"
                onClicked: skip()
            }

            PlasmaComponents.Button {
                id: sessionBtn
                text: "session btn" //sessionBtnText
                implicitWidth: minimumWidth
//                iconSource: sessionBtnIconSource
                onClicked: {
                    if (sessionBtnText == "Start") {
                        start()
                    } else {
                        pause()
                    }
                }
            }

            PlasmaComponents.Button {
                text: "Stop"
                implicitWidth: minimumWidth
                iconSource: "media-playback-stop"
                onClicked: stop()
            }
        }
    }
}
