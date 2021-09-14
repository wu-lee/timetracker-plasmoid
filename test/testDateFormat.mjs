// -*- javascript -*-
import Parser from '../package/contents/ui/dateFormat.mjs';
import fs from 'fs';

function testDuration(input) {
    return Parser.duration(input);
}


const testCases = [
    {name: 'hours 10000',
     func: Parser.durationHour,
     input: 10000,
     expect: '02'},
    {name: 'hours -10000',
     func: Parser.durationHour,
     input: -10000,
     expect: '-02'},

    {name: 'minutes 10000',
     func: Parser.durationMin,
     input: 10000,
     expect: '46'},
    {name: 'minutes -10000',
     func: Parser.durationMin,
     input: -10000,
     expect: '-46'},

    {name: 'seconds 10000',
     func: Parser.durationSec,
     input: 10000,
     expect: '40'},
    {name: 'seconds -10000',
     func: Parser.durationSec,
     input: -10000,
     expect: '-40'},

    {name: 'duration 10000',
     func: Parser.duration,
     input: 10000,
     expect: '02:46:40'},
    {name: 'duration -10000',
     func: Parser.duration,
     input: -10000,
     expect: '-02:46:40'},
];

testCases.forEach((c) => {
    const output = c.func(c.input);
    if (JSON.stringify(output) !== JSON.stringify(c.expect))
        console.log(c.name,": failed", output);
    else
        console.log(c.name,": passed");
})

