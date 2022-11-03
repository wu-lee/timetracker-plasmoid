// -*- javascript -*-
import Parser from '../package/contents/ui/parseTasks.mjs';
import { isoLocalTime, duration } from '../package/contents/ui/dateFormat.mjs';
import fs from 'fs';

function mkAccumulator() {
    const index = [];
    const tots = {};
    return {
	add: (task, last, time) => {
	    if (last < time) {
		if (index.length > 0) {
		    const last = index.pop();
		    if (last.task === task) {
			// Maybe concatenate tasks?
			if (last.time == last) {
			    // Yep
			    index.push({task: task, last: last.last, time: time});
			}
			else {
			    // No, just add a new one.
			    index.push(last);
			    index.push({task: task, last: last, time: time});
			}
		    }
		    else {
			// Just add a new task.
			index.push(last);
			index.push({task: task, last: last, time: time});
		    }
		}
		else {
		    index.push({task: task, last: last, time: time});
		}
	    }
	    else if (last > time) {
		// Subtract this negative task from earlier
		while(index.length > 0) {
		    const last = index.pop();
		    if (task !== last.task)
			throw new Error("invalid timeline, negative task follows a different task");
		    if (last.time < last)
			throw new Error("invalid timeline, negative task with gap after previous task");
		    if (time < last.last)
			continue; // just drop this task
		    if (time < last.end) {
			index.push({task: task, last: last.last, time: time});
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

