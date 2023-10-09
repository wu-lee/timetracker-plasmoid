#!/bin/env node
import { parseTasks, mkReportAccumulator } from '../package/contents/ui/parseTasks.mjs';
import { durationHourDecimal, isoLocalTime } from '../package/contents/ui/dateFormat.mjs';
import fs from 'fs';
import process from 'process';

var regexps;
if (process.argv.length > 2) {
    regexps = process.argv.slice(2);
}


function mkTsvReportAccumulator() {
    var reportAccumulator = mkReportAccumulator(regexps);

    function escape(str) {
        return str
            .replace(/;/g, '\\;')
            .replace(/\t/g, '\\t');
    }

    return {
        add: reportAccumulator.add,
        result: () => {
            var index = reportAccumulator.index();

            var dates = Object.keys(index)
                              .sort();
            var rows = [];
            if (dates.length > 0) {
                var date = new Date(dates[0]);
                var end = new Date(dates[dates.length - 1]);
                while(date <= end) {
                    var key = isoLocalTime(date);

                    var tasks = index[key];
                    var total = 0;
                    var names = [];
                    if (tasks) {
                        total = Object.values(tasks)
                                      .reduce((t, n) => t+n, 0);
                        names = Object.keys(tasks)
                                      .sort()
                                      .map(name => `${name} (${durationHourDecimal(tasks[name])})`)
                                      .map(escape)
                                      .join('; ');
                    }                        
                    rows.push([key,
                               Math.round(total/(60*30))/2,
                               names].join('\t'));
                    
                    // Add one day
                    date.setDate(date.getDate() + 1);
                }
            }
            return rows.join('\n');
        }
    };
}


const data = fs.readFileSync('/home/nick/tasks.log').toString();
const output = parseTasks(data, mkTsvReportAccumulator());

console.log(output);
