const schemaVersion = 1;

function parseTasks(eventList) {
    var index = {}
    var prevTime
    var currentTask // the name of the current task, if set
    
    eventList.split('\n').map(parseLine).forEach(aggregate)
    
    //console.log('debug'+JSON.stringify(index, null, '  '))
    return index;

    // Local function definitions.
    function parseLine(line, ix) {
        // Skip whitespace
        if (line.match(/^[ ]*$/))
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
                addTaskTime(taskEntry);
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
                
                if (!index[currentTask])
                    index[currentTask] = 0
                index[currentTask] += Math.round(milliseconds/1000)
            }
        }
        function switchTask(taskEntry) {
            currentTask = taskEntry.param
            if (!index[currentTask])
                index[currentTask] = 0
        }
        function initTask(taskEntry) {
            // If we were working, discard state and start afresh
            currentTask = undefined
        }
    }
}

// NodeJS accomodation
if (module)
    module.exports = { parseTasks, schemaVersion };
