// -*- javascript -*-
import QtQuick 2.3
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.0 as QtControls
import QtGraphicalEffects 1.12

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 2.0 as PlasmaComponents

Item {
    id: root

    property var startIconSource: plasmoid.file("", "icons/start-light.svg")
    property string clock_fontfamily: plasmoid.configuration.clock_fontfamily || "Noto Mono"
    property var taskSeconds: 0
    property var taskName: 'default task'
    property var timeText: formatDuration()
    property var taskLog: "~/tasks.log"

    // FIXME create directory
    
    // Initial size of the window in gridUnits
    width: units.gridUnit * 28
    height: units.gridUnit * 20

    Plasmoid.switchWidth: units.gridUnit * 11
    Plasmoid.switchHeight: units.gridUnit * 11

    //    Plasmoid.expanded: mouseArea.containsMouse

    
    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
    Plasmoid.status: PlasmaCore.Types.PassiveStatus
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground

    Timer {
        id: clockTimer
        interval: 1000 // milliseconds
        repeat: true
        running: false
        triggeredOnStart: false
        onTriggered: secondTick()
    }

    function formatDuration() {
        function formatNum(length, seconds) {
            seconds = '00' + seconds
            return seconds.substr(seconds.length-length);
        }
        if (taskSeconds) {
            var seconds = taskSeconds
            var minutes = Math.floor(seconds / 60)
            seconds -= minutes * 60
            var hours = Math.floor(minutes / 60)
            minutes -= hours * 60
            return [hours, formatNum(2, minutes), formatNum(2, seconds)].join(':');
        }
        else {
            return '0:00:00'
        }
    }
    
    function secondTick() {
        console.log("tick! "+formatDuration())
        taskSeconds += 1
        timeText = formatDuration()
    }

    function start() {
        clockTimer.start()
        executable.logTask('start', taskName.replace(/\t/g, ' '))
    }

    function pause() {
        clockTimer.stop()
        executable.logTask('stop', taskName.replace(/\t/g, ' '))
    }

    function stop() {
        clockTimer.stop()
        taskSeconds = 0
        executable.logTask('stop', taskName.replace(/\t/g, ' '))
    }

    function parseTasks(eventList) {
        var taskIndex = {}
        function parseLine(line, ix) {
            if (line.match(/^[ ]*$/))
                return
            var components = line.split('\t')
            if (components.length !== 3) {
                console.debug("malformed log line "+ix+": "+line);
                return;
            }
            return {
                time: new Date(components[0]),
                event: components[1],
                name: components[2]
            }
        }
        function aggregate(taskEntry) {
            if (!taskEntry)
                return
            //console.log(JSON.stringify(taskEntry))
            var name = taskEntry.name
            if (taskIndex[name])
                taskIndex[name].push(taskEntry)
            else
                taskIndex[name] = [taskEntry]

            // FIXME validate event order
        }
        eventList.split('\n').map(parseLine).forEach(aggregate)

        //console.log('debug'+JSON.stringify(taskIndex, null, '  '))
        return taskIndex;
    }

    ListModel {
        id: tasksModel

        ListElement {
            name: "some task"
            duration: 1.0
        }
        ListElement {
            name: "some other task"
            duration: 1.0
        }
        ListElement {
            name: "some task"
            duration: 1.0
        }
        ListElement {
            name: "some other task"
            duration: 1.0
        }
        ListElement {
            name: "some task"
            duration: 1.0
        }
        ListElement {
            name: "some other task"
            duration: 1.0
        }
        ListElement {
            name: "some task"
            duration: 1.0
        }
        ListElement {
            name: "some other task"
            duration: 1.0
        }
        ListElement {
            name: "some task"
            duration: 1.0
        }
        ListElement {
            name: "some other task"
            duration: 1.0
        }
        ListElement {
            name: "some task"
            duration: 1.0
        }
        ListElement {
            name: "some other task"
            duration: 1.0
        }
        ListElement {
            name: "some task"
            duration: 1.0
        }
        ListElement {
            name: "some other task"
            duration: 1.0
        }
    }
    
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

        // Captures data from commands
		onNewData: {
			var exitCode = data["exit code"]
			var exitStatus = data["exit status"]
			var stdout = data["stdout"]
			var stderr = data["stderr"]
            //            console.log(sourceName);

            // Detect which command ran and send the exited notification accordingly.
            if (sourceName.substr(0,3) == 'cat') {
			    exited('loadTasks', exitCode, exitStatus, stdout, stderr)
            }
            else if (sourceName.substr(0,6) == 'printf') {
                exited('logTask', exitCode, exitStatus, stdout, stderr)
            }
            else if (sourceName.substr(0,5) == 'mkdir') {
                exited('initTasks', exitCode, exitStatus, stdout, stderr)
            }
            else {
                console.error("unknown sourceName:", sourceName,
                              "\nexitStatus", exitStatus,
                              "\nstdout", stdout,
                              "\nstderr", stderr)
            }
			disconnectSource(sourceName) // cmd finished
		}

        // Utility for escaping and single-quoting and escaping strings for the command line.
        // This means that no interpolation, tilde expansion etc. occurs.
        function q(str) {
            return "'"+str.replace(/'/g, "'\"'\"'")+"'";
        }

        // Utility for escaping and double-quoting and escaping strings for the command line.
        // This means that interpolation, but no tilde expansion etc. occurs.
        function qq(str) {
            return '"'+str.replace(/"/g, "\\\"")+'"';
        }

        // Utility for escaping shell metacharacters in strings for the command line.
        // This means that interpolation, tilde expansion etc. will occur.
        function sq(str) {
            return str.replace(/([*?\[\]'"\\$;&()|^<>\n\t\ ])/g, '\\$1');
        }

        // Commands
        function initTasks() {
            var taskLogQuoted = sq(taskLog)
			connectSource('mkdir -p $(dirname '+taskLogQuoted+') && touch '+taskLogQuoted+' && cat '+taskLogQuoted);
        }

        // Lists all tasks in the task log
		function loadTasks() {
			connectSource('cat '+sq(taskLog));
		}

        // Logs a new task status change, and re-list the task log
		function logTask(state, name) {
            var date = new Date().toJSON()
            var taskLogQuoted = sq(taskLog)
            var cmd = [
                'printf "%s\\t%s\\t%s\\n"',
                q(date),
                q(state),
                q(name),
                '>> ', taskLogQuoted,
                '&& cat ', taskLogQuoted
            ].join(' ')
			connectSource(cmd)
		}

        // Define the edited signal
		signal exited(string cmdId, int exitCode, int exitStatus, string stdout, string stderr)
	}

    Connections {
		target: executable
		onExited: {
			if (exitCode == 0) {
                switch(cmdId) {
                case 'initTasks':
                case 'logTask':
                case 'loadTasks':
                    var tasks = parseTasks(stdout);
                    tasksModel.clear();
                    Object.entries(tasks).map(task => tasksModel.append({
                        name: task[0],
                        duration: task[1].length
                    }));
                    break
                }
				//console.debug('[commandoutput]', cmdId, 'stdout', stdout)
			}
            else {
                console.debug('[commandoutput]', cmdId, exitCode, 'stderr', stderr)
            }
		}
    }

    // On start, initialise the log (e.g. ensure the log's directory exists)
    Component.onCompleted: executable.initTasks()

    Plasmoid.compactRepresentation: MouseArea {
        id: compactRoot
        
        Layout.minimumWidth: units.iconSizes.small
        Layout.minimumHeight: units.iconSizes.small
        Layout.preferredHeight: Layout.minimumHeight
        Layout.maximumHeight: Layout.minimumHeight
        
        //            Layout.preferredWidth: row.width //plasmoid.configuration.show_time_in_compact_mode ? row.width : root.width
        
        property int wheelDelta: 0
            
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        
        onClicked: {

            switch(mouse.button) {
            case Qt.LeftButton:
                if (clockTimer.running)
                    pause()
                else
                    start()
                break
                
            case Qt.MiddleButton:
                break
                
            case Qt.RightButton:
                plasmoid.expanded = !plasmoid.expanded
                break
                
            default:
                console.error("unknown mouse button "+mouse.button);
                break
            }
        }

        onWheel: {
            //wheelDelta = scrollByWheel(wheelDelta, wheel.angleDelta.y);
        }

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

    }

    Plasmoid.fullRepresentation: Item {
        id: fullRoot
        
        Layout.minimumWidth: units.gridUnit * 12
        Layout.maximumWidth: units.gridUnit * 18
        Layout.minimumHeight: units.gridUnit * 11
        Layout.maximumHeight: units.gridUnit * 18

        // Backgground box for all
        Rectangle {
            width: parent.width - 10
            height: parent.height - 10
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            color: "transparent"
            
            // Background box for content
            Rectangle {
                id: redRect
                //color: "#f22"
                color: "transparent"
                width: parent.width
                height: parent.height
                border.color: "red"
            }

            // Background box for list 
            Rectangle {
                color: "transparent"
                width: parent.width
                height: parent.height
                anchors {
                    top: parent.top
                    bottom: buttonsRow.top
                }
                border.color: "yellow"
                
                ListView {
                    property int margin: 50
                    property int taskItemHeight: 10
	                id: taskList
	                width: parent.width
	                spacing: 0 //margin
//                    height: childrenRect.height 
//	                height: model.count * (taskItemHeight)//(taskItemHeight + spacing)
	                interactive: true
                    clip: true
//                    Layout.alignment: Qt.AlignVCenter
                    anchors.fill: parent
                    //                    anchors.bottom: parent.bottom
                    Layout.fillWidth: true
                    Layout.fillHeight: true
	                model: tasksModel
                    QtControls.ScrollBar.vertical: QtControls.ScrollBar {}
	                onModelChanged: {
//		                taskList.height = taskList.model.count * (taskItemHeight + spacing)
	                }
                    
	                delegate: RowLayout {
		                id: taskItem
		                width: parent.width-20
		                //height: taskList.height 
//		                radius: 10
		                anchors.horizontalCenter: parent.horizontalCenter
                        //border.color: "orange"
		                //color: "#0f0"
			            Text {
				            id: taskItemName
				            text: name
				            //anchors.centerIn: parent
                            Layout.alignment: Qt.AlignLeft
				            font.pixelSize: 14
				            color: "white"
			            }
			            Text {
				            id: taskItemDuration
				            text: duration
				            //anchors.centerIn: parent
                            Layout.alignment: Qt.AlignRight
				            font.pixelSize: 14
				            color: "red"
			            }
		            }
	            }
           
            }

            RowLayout {
                id: buttonsRow
                width: parent.width-10
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                }
                
                // Background box
                Rectangle {
                    id: blueRect
                    color: "#00f"
                    width: parent.width
                    height: parent.height
                    border.width: 0
                }
            
                PlasmaComponents.Button {
                    text: "Skip"
                    implicitWidth: minimumWidth
                    iconSource: "media-skip-forward"
                    onClicked: skip()
                    Layout.alignment: Qt.AlignLeft
                }
                
                PlasmaComponents.Button {
                    id: sessionBtn
                    text: "session" //sessionBtnText
                    implicitWidth: minimumWidth
                    Layout.alignment: Qt.AlignCenter
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
                    Layout.alignment: Qt.AlignRight
                }
            }
        }
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

    }
                              // The central area is a rectangle
                Rectangle {
                    // The id is used to reference this item from the
                    // button's onClicked function
                    id: redRect
                    color: "#f00"
                    
                    width: parent.width*0.9
                    height: parent.height/2
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                    //    top: parent.top
                    //    bottom:  parent.bottom
                    }

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
        }

    Plasmoid.fullRepresentation: Item {
        id: fullRoot

        Layout.minimumWidth: units.gridUnit * 12
        Layout.maximumWidth: units.gridUnit * 18
        Layout.minimumHeight: units.gridUnit * 11
        Layout.maximumHeight: units.gridUnit * 18

        Column {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                bottom: buttonsRow.top
            }

            // The central area is a rectangle
            Rectangle {
                // The id is used to reference this item from the
                // button's onClicked function
                id: redRect
                color: "#f00"
                
                width: parent.width*0.9
                height: parent.height/2
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    //    top: parent.top
                    //    bottom:  parent.bottom
                }
            }
        }
    }
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
*//*
            ColumnLayout {
//                anchors.centerIn: parent
                height: parent.height
                width: parent.width
                //Layout.alignment: Qt.AlignVCenter

*//*

                PlasmaComponents.Label {
                    id: time
                    text: timeText
//                    font.pointSize: progressCircle.width / 8
                    font.family: clock_fontfamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }
*//*
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
*//*
                PlasmaComponents.Label {
                    text: "Tasks:" //statusText
//                    font.pointSize: progressCircle.width / 24
//                    color: getTextColor()

                    anchors {
//                        top: time.bottom
                        horizontalCenter: parent.horizontalCenter
//                        topMargin: progressCircle.width / 20
                    }
                }

                      // The central area is a rectangle
                Rectangle {
                    // The id is used to reference this item from the
                    // button's onClicked function
                    id: redRect
                    color: "#f00"
                    
                    width: parent.width*0.9
                    height: parent.height/2
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                    //    top: parent.top
                    //    bottom:  parent.bottom
                    }
                    // It's supposed to grow in both direction
                    //Layout.fillWidth: true
                    //Layout.fillHeight: true
*//*            anchors {
              top: parent.top
              left: parent.left
              right: parent.right
              bottom: parent.bottom
              }*//*
                    
                    
                    ListView{
                        property int margin: 50
                        property int taskItemHeight: 10
	                    id: taskList
	                    width: parent.width
	                    spacing: margin
	                    height: model.count * (taskItemHeight + spacing)
	                    interactive: false
                        Layout.alignment: Qt.AlignVCenter
                        //	                anchors.top: parent.bottom
                        //	                anchors.topMargin: margin
	                    model: tasksModel
	                    onModelChanged: {
		                    taskList.height = taskList.model.count * (taskItemHeight + spacing)
	                    }
                        
	                    delegate: Rectangle{
		                    id: taskItem
		                    width: taskList.width
		                    height: taskList.height / 5
		                    radius: 10
		                    anchors.horizontalCenter: parent.horizontalCenter
		                    color: "#0f0"
			                Text {
				                id: taskItemText
				                text: name
				                anchors.centerIn: parent
				                font.pixelSize: 14
				            color: "white"
			                }
		                }
	                }*//*
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
*/
