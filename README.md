# RMLogFormatter

[![Build Status](https://travis-ci.org/rmaloney3/RMLogFormatter.svg?branch=master)](https://travis-ci.org/rmaloney3/RMLogFormatter)

`RMLogFormatter` is a customizable log formatter for CocoaLumberjack.  The default log format is as follows:

    yyyy-MM-dd HH:mm:ss.SSS | FILENAME:LINE_NUMBER (TID:THREAD_ID) : LOG_MESSAGE

## Usage

Set the log formatter as follows:

```objective-c
RMLogFormatter *logFormatter = [[RMLogFormatter alloc] init];

[[DDTTYLogger sharedInstance] setLogFormatter:logFormatter];
[DDLog addLogger:[DDTTYLogger sharedInstance]];
```

### Customization

The information contained in the log output is customizable using `RMLogFormatterOptions`.  `RMLogFormatterOptions` are a bit-mask of options telling `RMLogFormatter` what to include in the log statements and how to format it.  Formatter options must be passed in on initialization:

```objective-c
// e.g. 00:04:10.627 | Error | -[AppDelegate application:didFinishLaunchingWithOptions:]:46 : Error message
RMLogFormatterOptions options = RMLogFormatterOptionsTimestampShort | 
                                RMLogFormatterOptionsMethodName | 
                                RMLogFormatterOptionsLineNumber | 
                                RMLogFormatterOptionsLogFlagLong;

RMLogFormatter *logFormatter = [[RMLogFormatter alloc] initWithOptions:options];
```

If you would rather your logs speak for themselves set `RMLogFormatterOptionsNone` in the `options` parameter of `-[RMLogFormatter initWithOptions:]`.

#### RMLogFormatterOptions

```objective-c
typedef NS_OPTIONS(NSInteger, RMLogFormatterOptions) {
    RMLogFormatterOptionsNone           = 0,
    RMLogFormatterOptionsWordWrap       = 1 << 0,
    RMLogFormatterOptionsTimestampShort = 1 << 1,
    RMLogFormatterOptionsTimestampLong  = 1 << 2,
    RMLogFormatterOptionsFilePath       = 1 << 3,
    RMLogFormatterOptionsFileName       = 1 << 4,
    RMLogFormatterOptionsMethodName     = 1 << 5,
    RMLogFormatterOptionsLineNumber     = 1 << 6,
    RMLogFormatterOptionsThreadName     = 1 << 7,
    RMLogFormatterOptionsThreadID       = 1 << 8,
    RMLogFormatterOptionsLogFlagShort   = 1 << 9,
    RMLogFormatterOptionsLogFlagLong    = 1 << 10
};
```

## License

RMLogFormatter is available under the MIT license. See the LICENSE for more info.
