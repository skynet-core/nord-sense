import strutils, terminal

type
    LogLevel* = enum
        llDebug,
        llWarn,
        llError,
        llInfo
    Logger* = object
        level: LogLevel

proc `$`*(level: LogLevel): string =
    case level:
    of llDebug:
        "DEBUG"
    of llWarn:
        "WARN"
    of llError:
        "ERROR"
    of llInfo:
        "INFO"
    
proc fromString*(str: string): LogLevel =
    case str.toUpper():
    of "DEBUG":
        llDebug
    of "WARN", "WARNING":
        llWarn
    of "ERROR","ERR":
        llError
    else: llDebug

proc color*(level: LogLevel): ForegroundColor =
    case level:
    of llDebug:
        fgGreen
    of llWarn:
        fgMagenta
    of llError:
        fgRed
    of llInfo:
        fgYellow
    
proc newLogger*(level: LogLevel): Logger =
    result = Logger(level: level)

proc writeLog*(logger: Logger,
        level: LogLevel,
        msg: string
        ): void =
    
    if level >= logger.level or level == llInfo:
        stderr.write("[")
        setForegroundColor(stderr, level.color)
        stderr.write($level)
        # setForegroundColor(stderr, fgDefault)
        resetAttributes(stderr)
        stderr.writeLine("]: " & msg)

proc debug*(logger: Logger, msg: string): void =
    logger.writeLog(llDebug, msg)

proc warn*(logger: Logger, msg: string): void =
    logger.writeLog(llWarn, msg)

proc error*(logger: Logger, msg: string): void =
    logger.writeLog(llError, msg)

proc info*(logger: Logger, msg: string): void =
    logger.writeLog(llInfo, msg)