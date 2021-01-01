import argparse, logger

type 
    App* = object 
        config*: Option[string]
        pidfile*: string
        logLevel*: LogLevel
        force*:  bool


proc newApp*(): App = 
    result = App(config: none[string](), pidfile: "", force: false)


proc parseCli*(args: seq[TaintedString]): App = 
    result = newApp()
    var p = newParser("nsense"):
        option("-l","--level", default = some("DEBUG"), help = "log level to use")
        option("-c","--config", default = none[string](), help = "config file's path")
        option("-p","--pidfile",default = some("/run/nsense.pid"), help = "pifile's path")
        flag("-f","--force", help = "force daemon start")

    let opts = p.parse(args)
    result.config = 
        if opts.config.len > 0: 
            some(opts.config) 
        else:
            none[string]()
    
    result.logLevel = fromString(opts.level)
    result.pidfile = opts.pidfile
    result.force = opts.force
    