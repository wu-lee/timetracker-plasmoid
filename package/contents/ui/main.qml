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
    property int idleThresholdMins: 5
    property string clock_fontfamily: plasmoid.configuration.clock_fontfamily || "Noto Mono"
    property var taskSeconds: 0
    property var taskIndex: undefined
    property var timeText: formatDuration(taskSeconds)
    property var taskLog: "~/tasks.log"

    // Initial size of the window in gridUnits
    width: units.gridUnit * 28
    height: units.gridUnit * 20

    Plasmoid.switchWidth: units.gridUnit * 11
    Plasmoid.switchHeight: units.gridUnit * 11

    //    Plasmoid.expanded: mouseArea.containsMouse

    
    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
    Plasmoid.status: PlasmaCore.Types.PassiveStatus
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    Plasmoid.toolTipMainText: formatToolTipMainText()

    Timer {
        id: clockTimer
        interval: 1000 // milliseconds
        repeat: true
        running: false
        triggeredOnStart: false
        onTriggered: secondTick()
    }

    function formatToolTipMainText() {
        var task = selectedTask()
        if (task)
            return task.name + ': ' + timeText + (clockTimer.running? '' : ' (paused)')
        return 'No task currently' 
    }

    function formatDuration(seconds) {
        function formatNum(length, seconds) {
            seconds = '00' + seconds
            return seconds.substr(seconds.length-length);
        }
        if (seconds) {
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
        var task = selectedTask()
        if (!task)
            return
        console.log("tick! "+formatDuration(taskSeconds))
        taskSeconds += 1
        timeText = formatDuration(taskSeconds)
        task.duration = taskSeconds
        tasksModel.set(taskIndex, task)

        if (clockTimer.running && taskSeconds % 60 == 0) {
            getIdleTime(); // will check the idle time and stop the clock if it is too long
        }
    }

    // Get current task set by taskIndex
    function selectedTask() {
        if (taskIndex >= 0 && taskIndex < tasksModel.count) {
            return tasksModel.get(taskIndex)
        }
        return undefined;
    }

    function findTask(name) {
        for(var ix = 0; ix < tasksModel.count; ix += 1) {
            var task = tasksModel.get(ix)
            if (task.name == name)
                return ix
        }
        return undefined
    }

    function isSelectedTask(name) {
        var task = selectedTask()
        if (task)
            return task.name == name
        else
            return false 
    }

    function isActiveTask(name) {
        return clockTimer.running && isSelectedTask(name)
    }

    function activeTask() {
        return clockTimer.running? selectedTask() : undefined
    }
    
    function start(taskName) {
        var task
        if (taskName) {
            var ix = findTask(taskName)
            if (ix === undefined) {
                console.warn("can't start, unknown task", taskName);
                return
            }
            taskIndex = ix
        }

        task = selectedTask()
        if (!task) {
            console.warn("can't start, no task set");
            return
        }
            
        taskSeconds = task.duration // FIXME duration needs to be set correctly
        clockTimer.start()
        executable.logTask('start', task.name)
    }

    function pause() {
        clockTimer.stop()
        var task = selectedTask()
        if (task)
            executable.logTask('stop', task.name)
    }

    function stop() {
        clockTimer.stop()
        taskSeconds = 0
        var task = selectedTask()
        if (task)
            executable.logTask('stop', task.name)
    }

    function getIdleTime() {
        executable.pollIdle()
    }

    function addTask(name) {
        if (findTask(name) !== undefined)
            return // don't duplicate
        taskIndex = tasksModel.count
        tasksModel.append({
            name: name,
            duration: 0,
        });
    }

    function parseTasks(eventList) {
        var index = {}
        var lastTime
        var currentTask // tracks the state of the worker whilst aggregating the log entries
        
        eventList.split('\n').map(parseLine).forEach(aggregate)
            
        //console.log('debug'+JSON.stringify(index, null, '  '))
        return index;

        // Local function definitions.
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

            // Monitor the time sequence.
            if (lastTime) {
                if (lastTime > taskEntry.time)
                    warn('log entry out of time sequence');
            }
            lastTime = taskEntry.time

            // Manage the working state...
            switch(taskEntry.event) {
            case 'start':
                startTask(taskEntry)
                break

            case 'stop':
                stopTask(taskEntry);
                break
                
            default:
                warn('unknown event "'+taskEntry.event+'"')
                break
            }        

            return;

            function warn(message) {
                console.warn(message,
                             "for",taskEntry.name,
                             "at", taskEntry.time);
            }
            function startTask(taskEntry) {
                if (currentTask) {
                    // We are working already!
                    warn('unexpected start event, stopping old one first')
                    stopTask(taskEntry);
                }
                // In any case, start the new one
                currentTask = {
                    name: taskEntry.name,
                    started: taskEntry.time,
                }
                // Initialise an index entry
                if (!index[currentTask.name])
                    index[currentTask.name] = 0
            }

            function stopTask(taskEntry) {
                if (currentTask) {
                    // We are working

                    if (currentTask.name !== taskEntry.name) {
                        warn('stop event for unexpected task, stopping current task anyway');
                    }
                    // Assume aggregator will catch events out of time sequence
                    // so no check for that here.

                    // Add on task duration
                    var milliseconds = taskEntry.time.getTime() - currentTask.started.getTime();
                    if (milliseconds < 0)
                        warn('stop event before start event, ignoring')
                    else
                        index[currentTask.name] += Math.round(milliseconds/1000)
                }
                else {
                    // We are not working!?
                    warn('stop event when not working!')
                }

                // In any case
                currentTask = undefined
            }
        }
    }

    ListModel {
        id: tasksModel
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
            if (sourceName.substr(0,5) == 'qdbus') {
			    exited('pollIdle', exitCode, exitStatus, stdout, stderr)
            }
            else if (sourceName.substr(0,3) == 'cat') {
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

        // Utility for escaping tab and other special characters for TSV data fields
        function qt(str) {
            return str
                .replace(/\t/g, '\\t')
                .replace(/\n/g, '\\n')
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
                q(qt(date)),
                q(qt(state)),
                q(qt(name)),
                '>> ', taskLogQuoted,
                '&& cat ', taskLogQuoted
            ].join(' ')
			connectSource(cmd)
		}

        function pollIdle() {
			connectSource('qdbus org.freedesktop.ScreenSaver /ScreenSaver org.freedesktop.ScreenSaver.GetSessionIdleTime')
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
                        duration: task[1]
                    }));
                    break
                case 'pollIdle':
                    if (!clockTimer.running)
                        break
                    var millis = parseInt(stdout, 10)
                    if (millis / 60000 > idleThresholdMins) {
                        stop()
                    }
                    break
                default:
                    console.warn('ignoring unknown command id', cmdId);
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
                id: taskListRect
                color: "transparent"
                width: parent.width
//                height: parent.height
                anchors {
                    top: parent.top
                    bottom: taskInputRow.top
                }
                border.color: "yellow"
                
                ListView {
                    property int margin: 50
                    property int taskItemHeight: 10
	                id: taskList
	                width: parent.width
	                spacing: 0 
	                interactive: true
                    clip: true
                    anchors.fill: parent
                    Layout.fillWidth: true
                    Layout.fillHeight: true
	                model: tasksModel
                    QtControls.ScrollBar.vertical: QtControls.ScrollBar {}
                    
	                delegate: MouseArea {
                        height: childrenRect.height
                        width: parent.width
                        property bool isSelected: taskIndex === index
                        property bool isActive: clockTimer.running && taskIndex === index
                        property var textColor: isSelected ? "red" : "white"
                        onClicked: toggle()
                        
                        function toggle() {
                            if (isActive)
                                stop(name)
                            else
                                start(name)
                        }
                        
                        RowLayout {
		                    id: taskItem
		                    width: parent.width-20
		                    anchors.horizontalCenter: parent.horizontalCenter

                            PlasmaComponents.Button {
                                implicitWidth: minimumWidth
                                iconSource: isActive? "media-playback-stop" : "media-playback-start"
                                Layout.alignment: Qt.AlignLeft
                                onClicked: toggle()
                            }
                        	Text {
				                id: taskItemName
				                text: name
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignLeft
				                font.pixelSize: 14
				                color: textColor
			                }
			                Text {
				                id: taskItemDuration
				                text: formatDuration(duration)
                                Layout.alignment: Qt.AlignRight
				                font.pixelSize: 14
				                color: textColor
			                }
                        }
		            }
                }
            }

            RowLayout {
                id: taskInputRow
                width: parent.width 
                anchors {
                    bottom: parent.bottom
                }
                
                function newTask() {
                    if (taskInput.text.match(/^ *$/))
                        return
                    addTask(taskInput.text)
                    taskInput.clear()
                }
                
                // Background box
                Rectangle {
                    id: greenRect
                    border.color: "#0ff"
                    color: "transparent"
                    width: parent.width
                    height: parent.height
                }
            
                TextInput {
                    id: taskInput
                    font.pixelSize: 24
                    width: parent.width
                    color: "white"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 5
                    onAccepted: parent.newTask()
                }

                PlasmaComponents.Button {
                    implicitWidth: minimumWidth
                    text: "New Task"
                    Layout.alignment: Qt.AlignRight
                    Layout.margins: 5
                    onClicked: parent.newTask()
                }
            }
        }
    }
}           
