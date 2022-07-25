// -*- javascript -*-
import { parseTasks, mkReportAccumulator } from '../package/contents/ui/parseTasks.mjs';
import { durationHourDecimal } from '../package/contents/ui/dateFormat.mjs';
import fs from 'fs';
import process from 'process';

var regexps;
if (process.argv.length > 2) {
    regexps = process.argv.slice(2);
}

const data = fs.readFileSync('/home/nick/tasks.log').toString();
const output = parseTasks(data, mkReportAccumulator(regexps));

console.log(output);

