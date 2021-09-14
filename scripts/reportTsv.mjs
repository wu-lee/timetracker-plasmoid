// -*- javascript -*-
import Parser from '../package/contents/ui/parseTasks.mjs';
import fs from 'fs';

const data = fs.readFileSync('/home/nick/tasks.log').toString();
const output = Parser.parseTasks(data, Parser.mkTsvReportAccumulator());

console.log(output);

