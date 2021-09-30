// -*- javascript -*-
import DateFormat from './dateFormat.mjs';

export const schemaVersion = 1;


// Round the numeric values of a map to the nearest integer
function roundValues(map) {
    for(var k in map) {
	map[k] = Math.round(map[k]);
    }
}

export function mkTaskListAccumulator() {
    var index = {};

    return {
        add: (task, startTime, stopTime) => {
            var milliseconds = stopTime.getTime() - startTime.getTime()
            
            if (!index[task])
                index[task] = 0
            index[task] += milliseconds/1000;
        },
        result: () => {
	    roundValues(index);
	    return index;
	}
    };
}

export function mkReportAccumulator() {
    var index = {};

    return {
        add: (task, startTime, stopTime) => {
            var milliseconds = stopTime.getTime() - startTime.getTime();
	    startTime.setHours(0,0,0,0);
            var date = DateFormat.isoLocalTime(startTime);
            
            if (!index[date])
                index[date] = {}

            var dateIndex = index[date];
            if (!dateIndex[task])
                dateIndex[task] = 0
            dateIndex[task] += milliseconds/1000;
        },
	index: () => index,
        result: () => {
	    for(var date in index) {
		var tasks = index[date];
		var total = 0;
		for(var task in tasks) {
		    total += tasks[task];
		    tasks[task] = DateFormat.duration(tasks[task]);
		}
		tasks['total'] = DateFormat.duration(total);
	    }
	    return index;
	}
    };
}

export function parseTasks(eventList, accumulator) {
    var prevTime
    var currentTask // the name of the current task, if set
    
    eventList.split('\n').map(parseLine).forEach(aggregate)
    
    //console.log('debug'+JSON.stringify(index, null, '  '))
    return accumulator.result();

    // Local function definitions.
    function parseLine(line, ix) {
        // Skip whitespace
        if (line.match(/^[ \t]*$/))
            return

        // Skip comments (leading '#' or ';'), JSON objects/arrays (leading '{' or '[')
        // This is for convenient noting, and insertion of other data by other applications.
        if (line.match(/^[#;\[\{]/))
            return
        
        var components = line.split('\t')
        var expectedSchemaVersion = Number(schemaVersion).toString(16)
        if (components[0] !== expectedSchemaVersion) {
            console.error('Unrecognised schema version',components[0],'.',
                          '(Expected ',expectedSchemaVersion,')')
            return
        }
        
        // We assume the supported schema
        if (components.length < 4) { // min length
            console.debug('log line '+ix+' contains too few fields: '+line);
            return;
        }
        return {
            action: components[1],
            prevTime: components[2],
            time: components[3],
            param: components[4],
        }
    }
    function aggregate(taskEntry) {
        
        if (!taskEntry)
            return
        //console.log(JSON.stringify(taskEntry))

        // Monitor the time sequence.
        if (prevTime !== undefined) {
            if (taskEntry.action != 'init' && prevTime !== taskEntry.prevTime) {
                warn('log entry mismatches previous entrys timestamp sequence - '+
                     'probably corrupt! ('+ prevTime +' vs '+ taskEntry.prevTime +')')
            }
        }
        switch(taskEntry.action) {
            case 'stop':
            case 'mark':
            case 'init':
                // No check, these can all contain timestamps out of sequence
                // (or miss the first, in the case of init)
                break 
                
            default:
                if (new Date(taskEntry.time) < new Date(taskEntry.prevTime)) {
                    warn('log entry has a timestamp fields out of sequence')
                }
        }
        prevTime = taskEntry.time

        // Manage the working state...
        //console.debug(taskEntry.action, taskEntry.param)
        switch(taskEntry.action) {
            case 'start':
                if (!currentTask)
                    warn('unexpected start entry - no current task set')
                break

            case 'stop':
            case 'mark':
                if (currentTask === undefined)
                    // We are not working!?
                    warn('stop/mask action without a current task set')
                addTaskTime(taskEntry);
                break
                
            case 'switch':
                //switch task has no task-related duration, so don't addTaskTime
                switchTask(taskEntry);
                break

            case 'init':
                initTask(taskEntry)
                break
                
            default:
                warn('unknown action "'+taskEntry.action+'"')
                break
        }        

        return;

        function warn(message) {
            console.warn(message,
                         "for",taskEntry.action,
                         "at", taskEntry.time);
        }
        function addTaskTime(taskEntry) {
            if (currentTask !== undefined) {
                // We are working

                // Add on current task duration
                var startTime = new Date(taskEntry.prevTime)
                var stopTime = new Date(taskEntry.time)
                var milliseconds = stopTime.getTime() - startTime.getTime()

                accumulator.add(currentTask, startTime, stopTime);
            }
        }
        function switchTask(taskEntry) {
            currentTask = taskEntry.param;
	    var switchTime = new Date(taskEntry.time);
	    accumulator.add(currentTask, switchTime, switchTime); // initialise an entry to 0
        }
        function initTask(taskEntry) {
            // If we were working, discard state and start afresh
            currentTask = undefined
        }
    }
}

export default {
    schemaVersion,
    mkTaskListAccumulator,
    mkReportAccumulator,
    parseTasks,
};

// NodeJS accomodation
//if (typeof module === 'object')
//    module.exports = { parseTasks, schemaVersion };

