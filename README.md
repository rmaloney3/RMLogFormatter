# RMLogFormatter

RMLogFormatter is a customizable log formatter for CocoaLumberjack.  The default log format is as follows:

    yyyy-MM-dd HH:mm:ss.SSS | FILENAME:LINE_NUMBER (TID:THREAD_ID) : LOG_MESSAGE

## Usage

Set the log formatter on a DDLogger instance:

``` objective-c
RMLogFormatter *logFormatter = [[RMLogFormatter alloc] init];

[[DDTTYLogger sharedInstance] setLogFormatter:logFormatter];
[DDLog addLogger:[DDTTYLogger sharedInstance]];
```

## License

RMLogFormatter is available under the MIT license. See the LICENSE for more info.
