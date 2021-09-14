// -*- javascript -*-
import Parser from '../package/contents/ui/parseTasks.mjs';
import { isoLocalTime, duration } from '../package/contents/ui/dateFormat.mjs';
import fs from 'fs';

function mkAccumulator() {
    const log = [];
    const tots = {};
    return {
	add: (task, start, stop) => {
            const seconds = (stop.getTime() - start.getTime())/1000;
	    if (!tots[task])
		tots[task]= 0
	    tots[task] += seconds;
            const localtime = isoLocalTime(start);
	    log.push(`${localtime}\t${duration(seconds)}\t${duration(tots[task])}\t${task}`);
	},
	result: () => {
	    return log.join('\n');
	},
    };
}

const data = fs.readFileSync('/home/nick/tasks.log').toString();
const output = Parser.parseTasks(data, mkAccumulator())

console.log(output);

