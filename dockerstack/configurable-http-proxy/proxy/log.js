"use strict";
var strftime = require("strftime"),
    winston = require("winston");

const jsonFormat = winston.format.printf((info) => {
    var msg = {
        name: "ConfigProxy",
        timestamp: info.timestamp,
        logType: "OPER",
        level: info.level,
        body: {
            message: info.message
        }
    }
    return `${JSON.stringify(msg)}`
});

function defaultLogger(options) {
    options = options || {};
    options.format = winston.format.combine(
        winston.format.splat(),
        winston.format.timestamp({
            format: () => strftime("%F %H:%M:%S.%L", new Date()),
        }),
        jsonFormat
    );
    options.transports = [new winston.transports.Console()];
    return winston.createLogger(options);
}

exports.defaultLogger = defaultLogger