// -*- javascript -*-
import Parser from '../package/contents/ui/parseTasks.mjs';
import { isoLocalTime, duration } from '../package/contents/ui/dateFormat.mjs';
import fs from 'fs';

function mkAccumulator() {
    const index = [];
    const tots = {};
    return {
	add: (task, start, stop) => {
	    if (start < stop) {
		if (index.length > 0) {
		    const last = index.pop();
		    if (last.task === task) {
			// Maybe concatenate tasks?
			if (last.stop == start) {
			    // Yep
			    index.push({task: task, start: last.start, stop: stop});
			}
			else {
			    // No, just add a new one.
			    index.push(last);
			    index.push({task: task, start: start, stop: stop});
			}
		    }
		    else {
			// Just add a new task.
			index.push(last);
			index.push({task: task, start: start, stop: stop});
		    }
		}
		else {
		    index.push({task: task, start: start, stop: stop});
		}
	    }
	    else if (start > stop) {
		// Subtract this negative task from earlier
		while(index.length > 0) {
		    const last = index.pop();
		    if (task !== last.task)
			throw "invalid timeline, negative task follows a different task";
		    if (last.stop < start)
			throw "invalid timeline, negative task with gap after previous task";
		    if (stop < last.start)
			continue; // just drop this task
		    if (stop < last.end) {
			index.push({task: task, start: last.start, stop: stop});
			break;
		    }
		}
	    }
	},
	result: () => {
	    const tasks = index; //.flatMap(splitByDay);
	    // group by day
	    
	    return tasks;
	},
    };
}

const data = fs.readFileSync('/home/nick/tasks.log').toString();
const output = Parser.parseTasks(data, mkAccumulator())

console.log(output);

