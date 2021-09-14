// -*- javascript -*-
import Parser from '../package/contents/ui/parseTasks.mjs';
import fs from 'fs';

function mkTsvReportAccumulator() {
    var reportAccumulator = Parser.mkReportAccumulator();

    function escape(str) {
	return str
	    .replace(/;/g, '\\;')
	    .replace(/\t/g, '\\t');
    }

    return {
	add: reportAccumulator.add,
	result: () => {
	    var index = reportAccumulator.index();
	    
	    var rows = Object.keys(index)
		.sort()
		.map(date => {
		    var tasks = index[date];
		    var total = Object.values(tasks)
			.reduce((t, n) => t+n, 0);
		    var names = Object.keys(tasks)
			.sort()
			.map(escape)
			.join('; ');
		    
		    return [date,
			    Math.round(total/(60*30))/2,
			    names].join('\t');
		});
	    return rows.join('\n');
	}
    };
}


const data = fs.readFileSync('/home/nick/tasks.log').toString();
const output = Parser.parseTasks(data, mkTsvReportAccumulator());

console.log(output);

