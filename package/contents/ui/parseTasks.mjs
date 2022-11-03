// -*- javascript -*-
import DateFormat from './dateFormat.mjs';

export const schemaVersion = 1;


// Round the numeric values of a map to the nearest integer
function roundValues(map) {
    for(var k in map) {
	map[k] = Math.round(map[k]);
    }
}

function mkRegexFilter(regexps) {
    return function(task, lastTaskTime, taskTime) {
	for(const regexp of regexps) {
	    if (task.match(regexp)) {
		return true;
	    }
	}
	return false;
    };
}


function mkFilter(args) {
    switch(typeof args){
    case 'function': return args;
    case 'string': return mkRegexFilter([args]);
    case 'object': return mkRegexFilter(args);
    case 'undefined': return args;
    default: throw new Error(`don't know how to handle mkFilter parameter of type '${typeof args}' (${args})`);
    }
}

export function mkTaskListAccumulator(filter) {
    var index = {};

    filter = mkFilter(filter);
    
    return {
        add: (task, lastTaskTime, taskTime) => {
	    // Skip tasks which don't pass the filter - if one is supplied
	    if (filter && !filter(task, lastTaskTime, taskTime))
		return;
	    
            var milliseconds = taskTime.getTime() - lastTaskTime.getTime()
            
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

export function mkReportAccumulator(filter) {
    var index = {};

    filter = mkFilter(filter);
    
    return {
        add: (task, lastTaskTime, taskTime) => {
	    // Skip tasks which don't pass the filter - if one is supplied
	    if (filter && !filter(task, lastTaskTime, taskTime))
		return;
	    
            var milliseconds = taskTime.getTime() - lastTaskTime.getTime();
	    lastTaskTime.setHours(0,0,0,0);
            var date = DateFormat.isoLocalTime(lastTaskTime);
            
            if (!index[date])
                index[date] = {}

            var dateIndex = index[date];
            if (!dateIndex[task])
                dateIndex[task] = 0
            dateIndex[task] += milliseconds/1000;
        },
	index: () => index,
        result: () => {
	    function byDescendingDurationThenName(a, b) {
		return b[1] - a[1] || (a[0] > b[0]) - (a[0] < b[0]);
	    }
	    function formatTasks(tasks) {
		var taskEntries = Object.entries(tasks)
		      .filter(e => e[1] !== 0) // remove empty tasks
		      .sort(byDescendingDurationThenName)
		      .map(e => [e[0], DateFormat.duration(e[1])]); // format durations
		return Object.fromEntries(taskEntries);
	    }
	    function totalTasks(tasks) {
		return Object.values(tasks).reduce((a, v) => a+v, 0); // total durations
	    }
	    var reportDates = {};
	    var reportTotals = {};
	    for(var date in index) {
		var tasks = index[date];
		var total = totalTasks(tasks);
		var reportTasks = formatTasks(tasks);
		if (total === 0)
		    continue; // Don't add empty days

		reportTasks['total'] = DateFormat.duration(total);
		reportDates[date] = reportTasks;

		// Accumulate all the task durations in reportTotals
		Object.entries(tasks).forEach(e => {
		    var task = e[0];
		    var durationSecs = e[1];
		    if (task in reportTotals)
			reportTotals[task] += durationSecs;
		    else
			reportTotals[task] = durationSecs;
		});
	    }
	    var report = {
		dates: reportDates,
		totals: reportTotals,
	    };
	    var grandTotal = totalTasks(report.totals);
	    report.totals = formatTasks(report.totals);
	    report.totals.total = DateFormat.duration(grandTotal);
	    
	    return report;
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
            // console.log(`${currentTask} += ${taskEntry.param} @ ${taskEntry.time}`); // DEBUG
            if (currentTask !== undefined) {
                // We are working

                // Add on current task duration
                var lastTaskTime = new Date(taskEntry.prevTime)
                var taskTime = new Date(taskEntry.time)
                var milliseconds = taskTime.getTime() - lastTaskTime.getTime()
                // console.log(`   += ${milliseconds/1000}s`); // DEBUG
                accumulator.add(currentTask, lastTaskTime, taskTime);
            }
        }
        function switchTask(taskEntry) {
            // console.log(`${currentTask} -> ${taskEntry.param} @ ${taskEntry.time}`); // DEBUG
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

