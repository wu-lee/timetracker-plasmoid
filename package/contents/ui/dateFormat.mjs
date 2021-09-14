// -*- javascript -*-

export function pad(n) {
    n = '00' + n;
    return n.substr(n.length-2);
}

export function durationHour(seconds) {
    const sign = seconds >= 0? '' : '-';
    seconds = Math.abs(seconds);
    return sign + pad(Math.floor(seconds / 3600));
}

export function durationMin(seconds) {
    const sign = seconds >= 0? '' : '-';
    seconds = Math.abs(seconds);
    return sign + pad(Math.floor(seconds / 60) % 60);
}

export function durationSec(seconds) {
    const sign = seconds >= 0? '' : '-';
    seconds = Math.abs(seconds);
    return sign + pad(Math.floor(seconds) % 60);
}

export function duration(seconds) {
    const sign = seconds >= 0? '' : '-';
    seconds = Math.abs(seconds);
    return sign + [
	durationHour(seconds),
        durationMin(seconds),
        durationSec(seconds)
    ].join(':');
}
    


// This writes an ISO8601 formatted localtime date with timezone
//
// Instead of the built-in toISOString() and toJSON() methods, this writes
// a version in local time, with a zone offset.
//
// This way, users get to see their own timezone in the logs, and
// JS can still parse it reliably (or at least I hope so!)
//
// Adapted from this SO answer:
// https://stackoverflow.com/a/17415677/2960236
export function isoLocalTime(date) {
    var tzo = -date.getTimezoneOffset(),
        dif = tzo >= 0 ? '+' : '-';
    
    return date.getFullYear() +
           '-' + pad(date.getMonth() + 1) +
           '-' + pad(date.getDate()) +
           'T' + pad(date.getHours()) +
           ':' + pad(date.getMinutes()) +
           ':' + pad(date.getSeconds()) +
           dif + pad(tzo / 60) + pad(tzo % 60);
}

export default {
    isoLocalTime,
    durationSec,
    durationHour,
    durationMin,
    duration,
    pad,
};
