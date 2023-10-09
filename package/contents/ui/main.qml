// -*- javascript -*-
import QtQuick 2.3
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.0 as QtControls
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.12

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 2.0 as PlasmaComponents

import 'parseTasks.mjs' as Parser
import 'dateFormat.mjs' as DateFormat

Item {
    id: root

    property string widgetVersion: '0.1.0'
    property int idleThresholdMins: 10
    property string clock_fontfamily: plasmoid.configuration.clock_fontfamily || "Noto Mono"
    property var taskSeconds: 0
    property var taskIndex: undefined
    property var logPrevTime: undefined
    property var timeText: DateFormat.duration(taskSeconds)
    property var taskLog: "~/tasks.log"

    // Initial size of the window in gridUnits
    width: units.gridUnit * 28
    height: units.gridUnit * 20

    Plasmoid.switchWidth: units.gridUnit * 11
    Plasmoid.switchHeight: units.gridUnit * 11

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
    Plasmoid.status: PlasmaCore.Types.PassiveStatus
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    Plasmoid.toolTipMainText: formatToolTipMainText()
    Plasmoid.toolTipSubText: "Time tracker plasmoid v0.1"

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

    function secondTick() {
        var task = selectedTask()
        if (!task)
            return
        //console.debug("tick! "+DateFormat.duration(taskSeconds))
        taskSeconds += 1
        task.duration = taskSeconds
        tasksModel.set(taskIndex, task)

        if (clockTimer.running) {
            if (taskSeconds % 60 < 1) {
                getIdleTime(); // will check the idle time and stop the clock if it is too long
            }
            if (taskSeconds % (60*idleThresholdMins) < 1) {
                mark()
            }
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
                console.warn("can't start, unknown task", taskName)
                return
            }
            if (taskIndex !== ix) {
                taskIndex = ix
                executable.logTask('switch', taskName)
            }
        }

        task = selectedTask()
        if (!task) {
            console.warn("can't start, no task set");
            return
        }
        
        taskSeconds = task.duration
        clockTimer.start()
        executable.logTask('start')
    }
    
    function mark(reason) {
        // Don't write marks when the idle alert is showing,
        if (idleDialog.visible) {
            console.warn("can't mark, idle alert open")
            return
        }
        var task = selectedTask()
        if (!task) {
            console.warn("can't mark, no current task")
            return
        }
        if (!clockTimer.running) {
            console.warn("can't mark, task not in progress", task.name)
            return
        }
        if (!clockTimer.running) {
            console.warn("can't mark, task not in progress", task.name)
            return
        }
        executable.logTask('mark', reason)
    }

    // Discard idle time and stop task
    function idleStop(atTime) {
        var task = selectedTask()
        clockTimer.stop()
        if (task) {
            executable.logTask('stop', 'idle-stop', DateFormat.isoLocalTime(atTime))
        }        
    }
    
    // Discard idle time and continue task
    function idleDiscard(fromTime) {
        var task = selectedTask()
        if (task) {
            executable.logTask('mark', 'idle-discard', DateFormat.isoLocalTime(fromTime))
        }
    }

    function stop() {
        clockTimer.stop()
        var task = selectedTask()
        if (task)
            executable.logTask('stop')
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
        taskSeconds = 0
        executable.logTask('switch', name)
    }

    // refreshes all the UI info when a new list of tasks is set
    function updateTasks(tasks) {
        tasksModel.clear();
        Object.entries(tasks).map(task => tasksModel.append({
            name: task[0],
            duration: task[1]
        }));
        // update taskSeconds
        var task = selectedTask();
        taskSeconds = task? task.duration : 0;
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
            return "'"+(str||'').replace(/'/g, "'\"'\"'")+"'";
        }

        // Utility for escaping and double-quoting and escaping strings for the command line.
        // This means that interpolation, but no tilde expansion etc. occurs.
        function qq(str) {
            return '"'+(str||'').replace(/"/g, "\\\"")+'"';
        }

        // Utility for escaping shell metacharacters in strings for the command line.
        // This means that interpolation, tilde expansion etc. will occur.
        function sq(str) {
            return (str||'').replace(/([*?\[\]'"\\$;&()|^<>\n\t\ ])/g, '\\$1');
        }

        // Utility for escaping tab and other special characters for TSV data fields
        function qt(str) {
            return (str||'')
                .replace(/\t/g, '\\t')
                .replace(/\n/g, '\\n')
        }

        // Commands
        function initTasks() {
            var taskLogQuoted = sq(taskLog)

            logPrevTime = DateFormat.isoLocalTime(new Date())
            connectSource('mkdir -p $(dirname '+taskLogQuoted+') && '+
                          'printf "'+Parser.schemaVersion.toString(16)+
                          '\\tinit\\t\\t'+logPrevTime+'\\t'+sq(widgetVersion)+
                          '\\n" >>'+taskLogQuoted+' && '+
                          'cat '+taskLogQuoted);
        }

        // Lists all tasks in the task log
        function loadTasks() {
            connectSource('cat '+sq(taskLog));
        }

        // Logs a new task status change, and re-list the task log
        function logTask(action, param, timestamp) {
            if (!timestamp)
                timestamp = DateFormat.isoLocalTime(new Date())
            var taskLogQuoted = sq(taskLog)
            var cmd = [
                'printf "%x\\t%s\\t%s\\t%s\\t%s\\n"',
                Parser.schemaVersion,
                q(qt(action)),
                q(qt(logPrevTime||'')),
                q(qt(timestamp)),
                q(qt(param||'')),
                '>> ', taskLogQuoted,
                '&& cat ', taskLogQuoted
            ].join(' ')
            logPrevTime = timestamp

            //console.debug('>>', cmd);
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
        function onExited(cmdId, exitCode, exitStatus, stdout, stderr) {
            if (exitCode == 0) {
                switch(cmdId) {
                case 'initTasks':
                case 'logTask':
                case 'loadTasks':
                    var tasks = Parser.parseTasks(stdout, Parser.mkTaskListAccumulator());
		            updateTasks(tasks);		    
                    break
                case 'pollIdle':
                    // Clock should be running, if it isn't just bail
                    if (!clockTimer.running)
                        break

                    // Task should be selected, if it isn't just bail
                    if (taskIndex === undefined)
                        break

                    // Get the idle time
                    var millis = parseInt(stdout, 10)

                    // If it's large enough, go into idle-alert mode
                    if (millis / 60000 >= idleThresholdMins) {
                        idleDialog.idleAt = new Date(Date.now()-millis)
                        idleDialog.open()
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
            case Qt.RightButton:
                if (clockTimer.running)
                    stop()
                else
                    start()
                break
                
            case Qt.MiddleButton:
                break
                
            case Qt.LeftButton:
                if (!plasmoid.expanded) {
                    executable.loadTasks()
                }
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
                
                Column {
                    height: parent.height
                    width: parent.width
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    property string startedColor: "red"
                    property string stoppedColor: "white"
                    
                    PlasmaComponents.Label {
                        id: trayLabel1
                        height: parent.height/3
                        width: parent.width
                        font.pointSize: -1
                        font.pixelSize: height
                        fontSizeMode: Text.FixedSize
                        font.family: clock_fontfamily
                        text: DateFormat.durationHour(taskSeconds)
                        minimumPixelSize: 1
                        Layout.alignment: Qt.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        color: clockTimer.running? parent.startedColor:parent.stoppedColor
                        smooth: true
                    }
                    PlasmaComponents.Label {
                        id: trayLabel2
                        height: parent.height/3
                        width: parent.width
                        font.pointSize: -1
                        font.pixelSize: height
                        fontSizeMode: Text.FixedSize
                        font.family: clock_fontfamily
                        text: DateFormat.durationMin(taskSeconds)
                        minimumPixelSize: 1
                        Layout.alignment: Qt.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        color: clockTimer.running? parent.startedColor:parent.stoppedColor
                        smooth: true
                    }
                    PlasmaComponents.Label {
                        id: trayLabel3
                        height: parent.height/3
                        width: parent.width
                        font.pointSize: -1
                        font.pixelSize: height
                        fontSizeMode: Text.FixedSize
                        font.family: clock_fontfamily
                        text: DateFormat.durationSec(taskSeconds)
                        minimumPixelSize: 1
                        Layout.alignment: Qt.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        color: clockTimer.running? parent.startedColor:parent.stoppedColor
                        smooth: true
                    }
                }
                
            }
            
            /*
              
              PlasmaComponents.Label {
              visible: true //!plasmoid.configuration.show_time_in_compact_mode
              font.pointSize: -1
              font.pixelSize: compactRoot.height * 0.6
              //fontSizeMode: Text.FixedSize
              font.family: clock_fontfamily
              text: DateFormat.duration(taskSeconds)
              minimumPixelSize: 1
              Layout.alignment: Qt.AlignVCenter
              //                color: getTextColor()
              smooth: true
              }*/
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
                                id: taskItemButton
                                implicitWidth: minimumWidth
                                iconSource: isActive? "media-playback-stop" : "media-playback-start"
                                Layout.alignment: Qt.AlignLeft
                                onClicked: toggle()
                            }
                            Text {
                                id: taskItemName
                                text: name
                                elide: Text.ElideRight
                                Layout.alignment: Qt.AlignLeft
                                Layout.preferredWidth: Layout.maximumWidth
                                Layout.maximumWidth: taskItem.width - taskItemButton.width - taskItemDuration.width
                                Layout.minimumWidth: 10
                                font.pixelSize: 14
                                color: textColor

                                QtControls.ToolTip.text: name
                                QtControls.ToolTip.visible: truncated && taskItemNameArea.containsMouse
                                MouseArea {
                                    id: taskItemNameArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                            Text {
                                id: taskItemDuration
                                text: DateFormat.duration(duration)
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

                /*
                // Background box
                Rectangle {
                    id: greenRect
                    border.color: "#0ff"
                    color: "transparent"
                    width: parent.width
                    height: parent.height
                }*/
                
                QtControls.TextField {
                    id: taskInput
                    font.pixelSize: 24
                    width: parent.width
                    color: "white"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 5
                    placeholderText: "New Task..."
                    onAccepted: parent.newTask()
                }

                PlasmaComponents.Button {
                    implicitWidth: minimumWidth
                    text: "Add"
                    Layout.alignment: Qt.AlignRight
                    Layout.margins: 5
                    onClicked: parent.newTask()
                }
            }
        }
    }

    MessageDialog {
        id: idleDialog
        property var idleAt: new Date()
        title: "Title"
        icon: StandardIcon.Question
        modality: Qt.ApplicationModal
        text: "You seem to have stopped working at "+idleAt+
            "... Keep the intervening time and continue (Save), "+
            "discard it and continue (Discard), or "+
            "discard it and stop (Reset)?"
        standardButtons:  StandardButton.Save | StandardButton.Discard | StandardButton.Reset
        onAccepted: mark('idle-continue')
        onDiscard: idleDiscard(idleAt)
        onReset: idleStop(idleAt)
    }
}           
