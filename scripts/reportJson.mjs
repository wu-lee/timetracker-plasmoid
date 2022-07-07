// -*- javascript -*-
import { parseTasks, mkReportAccumulator } from '../package/contents/ui/parseTasks.mjs';
import { durationHourDecimal } from '../package/contents/ui/dateFormat.mjs';
import fs from 'fs';

const data = fs.readFileSync('/home/nick/tasks.log').toString();
const output = parseTasks(data, mkReportAccumulator());

console.log(output);

