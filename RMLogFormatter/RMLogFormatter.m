//
//  RMLogFormatter.m
//
//  Created by Ryan Maloney on 9/6/14.
//  Copyright (c) 2014 Ryan Maloney
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import <libkern/OSAtomic.h>

#import "RMLogFormatter.h"
#import "RMStringWordWrapper.h"

static const NSUInteger RMLogFormatterMinimumLineLength = 80;
static const NSUInteger RMLogFormatterDefaultLineLength = 120;
static const RMLogFormatterOptions RMLogFormatterDefaultOptions =   RMLogFormatterOptionsNone |
                                                                    RMLogFormatterOptionsWordWrap |
                                                                    RMLogFormatterOptionsTimestampLong |
                                                                    RMLogFormatterOptionsFileName |
                                                                    RMLogFormatterOptionsLineNumber |
                                                                    RMLogFormatterOptionsThreadID;

@implementation RMLogFormatter {
    int _atomicLoggerCount;
    
    RMLogFormatterOptions _logOptions;
    
    NSString *_logStatsFormatString;
    NSDateFormatterStyle _dateFormatTimeStyle;
    
    RMStringWordWrapper *_stringWordWrapper;
}

#pragma mark - Initializers

- (instancetype)init {
    return [self initWithLogLineLength:RMLogFormatterDefaultLineLength options:RMLogFormatterDefaultOptions];
}

- (instancetype)initWithLogLineLength:(NSUInteger)logLineLength {
    return [self initWithLogLineLength:logLineLength options:RMLogFormatterDefaultOptions];
}

- (instancetype)initWithOptions:(RMLogFormatterOptions)options {
    return [self initWithLogLineLength:RMLogFormatterDefaultLineLength options:options];
}

- (instancetype)initWithLogLineLength:(NSUInteger)logLineLength options:(RMLogFormatterOptions)options {
    if (self = [super init]) {
        _logOptions = options;
        
        NSUInteger lineLength = logLineLength;
        if ((lineLength < RMLogFormatterMinimumLineLength)) {
            lineLength = RMLogFormatterMinimumLineLength;
        }
        
        _stringWordWrapper = [[RMStringWordWrapper alloc] initWithWordWrapLength:lineLength];
        
        _logStatsFormatString = [self logStatFormatStringFromLogFormatterOptions:_logOptions];
        
        if (self.timestampEnabled) {
            if (_logOptions & RMLogFormatterOptionsTimestampShort) {
                _dateFormatTimeStyle = NSDateFormatterShortStyle;
            } else {
                _dateFormatTimeStyle = NSDateFormatterLongStyle;
            }
        } else {
            _dateFormatTimeStyle = NSDateFormatterNoStyle;
        }
    }
    
    return self;
}

#pragma mark - Public Property Accessors

- (RMLogFormatterOptions)options {
    return _logOptions;
}

- (NSUInteger)lineLength {
    return _stringWordWrapper.wordWrapLength;
}

- (BOOL)isTimestampEnabled {
    return !!(_logOptions & (RMLogFormatterOptionsTimestampShort | RMLogFormatterOptionsTimestampLong));
}

- (BOOL)isLogFlagEnabled {
    return !!(_logOptions & (RMLogFormatterOptionsLogFlagShort | RMLogFormatterOptionsLogFlagLong));
}

- (BOOL)isFileNameEnabled {
    return !!(_logOptions & RMLogFormatterOptionsFileName);
}

- (BOOL)isMethodNameEnabled {
    return !!(_logOptions & RMLogFormatterOptionsMethodName);
}

- (BOOL)isLineNumberEnabled {
    return !!(_logOptions & RMLogFormatterOptionsLineNumber);
}

- (BOOL)isThreadNameEnabled {
    return !!(_logOptions & RMLogFormatterOptionsThreadName);
}

- (BOOL)isThreadIDEnabled {
    return !!(_logOptions & RMLogFormatterOptionsThreadID);
}

#pragma mark - Private

- (NSString *)stringFromDate:(NSDate *)date {
    int32_t loggerCount = OSAtomicAdd32(0, &_atomicLoggerCount);
    
    if (loggerCount <= 1) {
        // Single-threaded mode.
        static NSDateFormatter *threadUnsafeDateFormatter;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            threadUnsafeDateFormatter = [NSDateFormatter new];
            threadUnsafeDateFormatter.formatterBehavior = NSDateFormatterBehavior10_4;
            threadUnsafeDateFormatter.dateStyle = NSDateFormatterNoStyle;
            threadUnsafeDateFormatter.timeStyle = _dateFormatTimeStyle;
        });
        
        return [threadUnsafeDateFormatter stringFromDate:date];
    } else {
        // Multi-threaded mode.
        // NSDateFormatter is NOT thread-safe.
        NSString *key = @"RMInfoFormatter_NSDateFormatter";
        
        NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
        NSDateFormatter *dateFormatter = [threadDictionary objectForKey:key];
        
        if (!dateFormatter) {
            dateFormatter = [NSDateFormatter new];
            [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            dateFormatter.dateStyle = NSDateFormatterNoStyle;
            dateFormatter.timeStyle = _dateFormatTimeStyle;
            
            threadDictionary[key] = dateFormatter;
        }
        
        return [dateFormatter stringFromDate:date];
    }
}

#pragma mark - Log Stat String Builders

- (NSString *)logStatFormatStringFromLogFormatterOptions:(RMLogFormatterOptions)options {
    NSMutableString *formatString = [NSMutableString string];
    
    BOOL timestampEnabled   = options & (RMLogFormatterOptionsTimestampShort | RMLogFormatterOptionsTimestampLong);
    BOOL logFlagEnabled     = options & (RMLogFormatterOptionsLogFlagShort | RMLogFormatterOptionsLogFlagLong);
    BOOL fileNameEnabled    = options & RMLogFormatterOptionsFileName;
    BOOL methodNameEnabled  = options & RMLogFormatterOptionsMethodName;
    BOOL lineNumberEnabled  = options & RMLogFormatterOptionsLineNumber;
    BOOL threadNameEnabled  = options & RMLogFormatterOptionsThreadName;
    BOOL threadIDEnabled    = options & RMLogFormatterOptionsThreadID;
    
    if (timestampEnabled) {
        [formatString appendString:@"%@"];
    }
    
    if (logFlagEnabled) {
        if (timestampEnabled) {
            [formatString appendString:@" | %@"];
        } else {
            [formatString appendString:@"%@"];
        }
    }
    
    if (fileNameEnabled) {
        if (timestampEnabled | logFlagEnabled) {
            [formatString appendString:@" | %@"];
        } else {
            [formatString appendString:@"%@"];
        }
    }
    
    if (methodNameEnabled) {
        if (fileNameEnabled) {
            [formatString appendString:@".%@"];
        } else if (timestampEnabled | logFlagEnabled) {
            [formatString appendString:@" | %@"];
        } else {
            [formatString appendString:@"%@"];
        }
    }
    
    if (lineNumberEnabled) {
        if (fileNameEnabled | methodNameEnabled) {
            [formatString appendString:@":%@"];
        } else if (timestampEnabled | logFlagEnabled) {
            [formatString appendString:@" | Line:%@"];
        } else {
            [formatString appendString:@"Line:%@"];
        }
    }
    
    if (threadNameEnabled) {
        if (fileNameEnabled | methodNameEnabled | lineNumberEnabled) {
            [formatString appendString:@" Thread:%@"];
        } else if (timestampEnabled | logFlagEnabled) {
            [formatString appendString:@" | Thread:%@"];
        } else {
            [formatString appendString:@"Thread:%@"];
        }
    }
    
    if (threadIDEnabled) {
        if (threadNameEnabled) {
            [formatString appendString:@"(%@)"];
        } else if (fileNameEnabled | methodNameEnabled | lineNumberEnabled) {
            [formatString appendString:@" (TID:%@)"];
        } else if (timestampEnabled | logFlagEnabled) {
            [formatString appendString:@" | (TID:%@)"];
        } else {
            [formatString appendString:@"(TID:%@)"];
        }
    }
    
    return [formatString copy];
}

- (NSString *)stringFromLogFlag:(DDLogFlag)logFlag {
    BOOL shortLogFlagFormat = (_logOptions & RMLogFormatterOptionsLogFlagShort) == RMLogFormatterOptionsLogFlagShort;
    
    NSString *logFlagString;
    
    switch (logFlag) {
        case DDLogFlagError:
            logFlagString = shortLogFlagFormat ? @"E" : @"  Error";
            break;
        case DDLogFlagWarning:
            logFlagString = shortLogFlagFormat ? @"W" : @"   Warn";
            break;
        case DDLogFlagInfo:
            logFlagString = shortLogFlagFormat ? @"I" : @"   Info";
            break;
        case DDLogFlagDebug:
            logFlagString = shortLogFlagFormat ? @"D" : @"  Debug";
            break;
        case DDLogFlagVerbose:
            logFlagString = shortLogFlagFormat ? @"V" : @"Verbose";
            break;
    }

    return logFlagString;
}

- (NSString *)logStatsStringFromComponents:(NSArray *)components {
    return [NSString stringWithFormat:_logStatsFormatString,    components.count>0 ? components[0] : nil,
                                                                components.count>1 ? components[1] : nil,
                                                                components.count>2 ? components[2] : nil,
                                                                components.count>3 ? components[3] : nil,
                                                                components.count>4 ? components[4] : nil,
                                                                components.count>5 ? components[5] : nil,
                                                                components.count>6 ? components[6] : nil];
}

#pragma mark - DDLogFormatter Protocol

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    if (_logOptions == RMLogFormatterOptionsNone) {
        return [NSString stringWithFormat:@"%@", logMessage.message];
    }
    
    NSMutableArray *logStatsComponents = [NSMutableArray array];
    
    if ([self isTimestampEnabled]) {
        [logStatsComponents addObject:[self stringFromDate:logMessage.timestamp]];
    }
    
    if ([self isLogFlagEnabled]) {
        [logStatsComponents addObject:[self stringFromLogFlag:logMessage.flag]];
    }
    
    if ([self isFileNameEnabled]) {
        [logStatsComponents addObject:logMessage.fileName];
    }
    
    if ([self isMethodNameEnabled]) {
        [logStatsComponents addObject:logMessage.function];
    }
    
    if ([self isLineNumberEnabled]) {
        [logStatsComponents addObject:[NSString stringWithFormat:@"%lu", (unsigned long)logMessage.line]];
    }
    
    if ([self isThreadNameEnabled]) {
        if (logMessage.threadName.length) {
            [logStatsComponents addObject:logMessage.threadName];
        } else {
            [logStatsComponents addObject:@"no_name"];
        }
    }
    
    if ([self isThreadIDEnabled]) {
        [logStatsComponents addObject:logMessage.threadID];
    }
    
    NSString *logStatsString = [self logStatsStringFromComponents:logStatsComponents];
    
    NSString *fullLogMessage = [NSString stringWithFormat:@"%@ : %@", logStatsString, logMessage.message];
    
    if (_logOptions & RMLogFormatterOptionsWordWrap) {
        // FIXME: If indentLength is longer than wordWrapLength word wrap over-indents.
        NSUInteger indentLength = logStatsString.length + 3;
        
        fullLogMessage = [_stringWordWrapper wrapString:fullLogMessage withIndentLength:indentLength];
    }
    
    return fullLogMessage;
}

- (void)didAddToLogger:(id <DDLogger>)logger {
    OSAtomicIncrement32(&_atomicLoggerCount);
}

- (void)willRemoveFromLogger:(id <DDLogger>)logger {
    OSAtomicDecrement32(&_atomicLoggerCount);
}
- (NSString *)description
{
    return [NSString stringWithFormat:@"RMLogFormatter description:\n%@ lineLength: %zd\noptions: %lu\ntimestampEnabled: %i\nlogFlagEnabled: %i\nfileNameEnabled: %i\nmethodNameEnabled: %i\nlineNumberEnabled: %i\nthreadNameEnabled: %i\nthreadIDEnabled: %i\n",[super description], self.lineLength, self.options, self.timestampEnabled, self.logFlagEnabled, self.fileNameEnabled, self.methodNameEnabled, self.lineNumberEnabled, self.threadNameEnabled, self.threadIDEnabled];
}

@end
