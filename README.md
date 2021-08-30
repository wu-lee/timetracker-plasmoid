# Time-tracker plasmoid

A plasma widget for tracking time spent on your various tasks.

This lives in your panel, and on right-click shows a list of task
names with time already logged, and a text field for creating an entry
with a new task name. Clicking a task name or the button next to it
starts the task if it is not the current task, switching from any
previous task. Otherwise, it stops the task.

The plasmoid can detect a session's idle time, and will prompt the
user on return weather to keep or discard the idle time time on the
current task.

State changes are written to a log file which can be used to generate
reports.

## Install

Before installing/upgrading, you need to restart plasmashell, because it caches QML files:

    killall plasmashell; kstart5 plasmashell

Then to install the first time:

    kpackagetool5 -t Plasma/Applet -i package
	
To upgrade:

	kpackagetool5 -t Plasma/Applet -u package

To remove:

    kpackagetool5 -t Plasma/Applet -r package

## Test

For testing/development, you need plasmoidviewer:

    sudo apt install plasma-sdk

Then for a minimised view:

    plasmoidviewer --applet package --containment org.kde.panel  -l bottomedge -s 800x100

For a maximised view:

    plasmoidviewer --applet package

## Log format

The log file is a tab-delimited data file. It has no headers, but the fields are named as follows:

    version    action    prevtime    time    parameters...

Tab and new-line characters are delimiters and so cannot be present
literally in field data. Instead they should be escaped with the
values `\t` and `\n` respectively.

The fields function are as follows. The version field indicating the
semantics to expect in the other fields, which can vary between
versions. Typically a logfile will not contain more than one version,
and the plasmoid will only support one version.

- version: a hexadecimal schema version number for this log entry, 

### Version 1

The other fields include:

- `action`, one of:
  - `start`: start working on the current task
  - `stop`: stop working on the current task
  - `mark`: continue working on the current task (emitted periodically)
  - `switch`: change the current task
- `prevtime`: the timestamp of the last entry, if from this session.
- `time`: the timestamp of this log entry
- `prevtime`: the timestamp of the previous log entry (an integrity check)
- `parameters`: one or more fields which are optional parameters of this entry
  - for `switch`:
    - `name`: the name of the new task

