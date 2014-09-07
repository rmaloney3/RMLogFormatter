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

#import "RMLogFormatter.h"
#import <libkern/OSAtomic.h>

static const NSUInteger RMLF_DEFAULT_LINE_LENGTH = 120;
static const RMLogFormatterOptions RMLF_DEFAULT_OPTIONS =   RMLogFormatterOptionsNone |
                                                            RMLogFormatterOptionsWordWrap |
                                                            RMLogFormatterOptionsTimestampLong |
                                                            RMLogFormatterOptionsFileName |
                                                            RMLogFormatterOptionsLineNumber |
                                                            RMLogFormatterOptionsThreadID;

@interface RMLogFormatter ()

@end

@implementation RMLogFormatter {
    int _atomicLoggerCount;
    
    RMLogFormatterOptions _logOptions;
    NSUInteger _lineLength;
    
    NSString *_dateFormatString;
    NSDateFormatter *_threadUnsafeDateFormatter;
}

#pragma mark - Initializers

- (instancetype)init {
    return [self initWithLogLineLength:RMLF_DEFAULT_LINE_LENGTH options:RMLF_DEFAULT_OPTIONS];
}

- (instancetype)initWithLogLineLength:(NSUInteger)logLineLength {
    return [self initWithLogLineLength:logLineLength options:RMLF_DEFAULT_OPTIONS];
}

- (instancetype)initWithOptions:(RMLogFormatterOptions)options {
    return [self initWithLogLineLength:RMLF_DEFAULT_LINE_LENGTH options:options];
}

- (instancetype)initWithLogLineLength:(NSUInteger)logLineLength options:(RMLogFormatterOptions)options {
    if (self = [super init]) {
        _logOptions = options;
        
        // Ensure minimum line length boundary is not exceeded.
        _lineLength = (logLineLength < 80) ? 80 : logLineLength;
        
        if (_logOptions & (RMLogFormatterOptionsTimestampShort | RMLogFormatterOptionsTimestampLong)) {
            if (_logOptions & RMLogFormatterOptionsTimestampShort) {
                _dateFormatString = @"HH:mm:ss.SSS";
            } else {
                _dateFormatString = @"yyyy-MM-dd HH:mm:ss.SSS";
            }
        } else {
            _dateFormatString = nil;
        }
    }
    
    return self;
}

#pragma mark - Public Property Accessors

- (RMLogFormatterOptions)options {
    return _logOptions;
}

- (NSUInteger)lineLength {
    return _lineLength;
}

#pragma mark - Private

// TODO: Convert to NSString Category
- (NSString *)stringFromDate:(NSDate *)date {
    int32_t loggerCount = OSAtomicAdd32(0, &_atomicLoggerCount);
    
    if (loggerCount <= 1) {
        // Single-threaded mode.
        
        if (_threadUnsafeDateFormatter == nil) {
            _threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
            [_threadUnsafeDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            [_threadUnsafeDateFormatter setDateFormat:_dateFormatString];
        }
        
        return [_threadUnsafeDateFormatter stringFromDate:date];
    } else {
        // Multi-threaded mode.
        // NSDateFormatter is NOT thread-safe.
        
        NSString *key = @"RMInfoFormatter_NSDateFormatter";
        
        NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
        NSDateFormatter *dateFormatter = [threadDictionary objectForKey:key];
        
        if (dateFormatter == nil) {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            [dateFormatter setDateFormat:_dateFormatString];
            
            [threadDictionary setObject:dateFormatter forKey:key];
        }
        
        return [dateFormatter stringFromDate:date];
    }
}

// TODO: Convert to NSString Category
- (NSString *)stringByRepeatingCharacter:(char)character length:(NSUInteger)length {
    char stringUtf8[length + 1];
    memset(stringUtf8, character, length * sizeof(*stringUtf8));
    stringUtf8[length] = '\0';
    
    return [NSString stringWithUTF8String:stringUtf8];
}

- (NSString *)wrapString:(NSString *)sourceString withLineLength:(NSUInteger)length indentLength:(NSUInteger)indentLength {
    BOOL isMultiline = ((sourceString.length > length) || [sourceString containsString:@"\n"]);
    
    if (!isMultiline) {
        return sourceString;
    }
    
    NSUInteger maxLineLength = length;
    
    NSString *indentString = [NSString stringWithFormat:@"\n%@", [self stringByRepeatingCharacter:' ' length:indentLength]];
    
    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSMutableString *currentLine = [[NSMutableString alloc] init];
    NSScanner *scanner = [NSScanner scannerWithString:sourceString];
    scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@""];
    NSString *scannedString = nil;
    while ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString: &scannedString]) {
        if ([currentLine length] + [scannedString length] <= maxLineLength) {
            [currentLine appendString:scannedString];
        }
        else if ([currentLine length] == 0) { // Newline but next word > currentLineLength
            [resultString appendFormat:@"%@%@", scannedString, [scanner isAtEnd] ? @"" : indentString];
            maxLineLength = length - indentLength;
        }
        else { // Need to break line and start new one
            [resultString appendFormat:@"%@%@", currentLine, [scanner isAtEnd] ? @"" : indentString];
            [currentLine setString:[NSString stringWithString:scannedString]];
            maxLineLength = length - indentLength;
        }
        
        if ([scanner scanUpToCharactersFromSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet] intoString:&scannedString]) {
            [currentLine appendString:scannedString];
        }
        
        if ([scanner scanUpToCharactersFromSet:[[NSCharacterSet newlineCharacterSet] invertedSet] intoString:&scannedString]) {
            [resultString appendFormat:@"%@%@", currentLine, [scanner isAtEnd] ? @"" : indentString];
            [currentLine setString:@""];
            maxLineLength = length - indentLength;
        }
    }
    
    [resultString appendString:currentLine];
    
    return resultString;
}

#pragma mark - DDLogFormatter Protocol

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    if (_logOptions == RMLogFormatterOptionsNone) {
        return [NSString stringWithFormat:@"%@", logMessage->logMsg];
    }
    
    NSMutableString *logStats = [NSMutableString string];
    
    BOOL timestampEnabled = (_logOptions & (RMLogFormatterOptionsTimestampShort | RMLogFormatterOptionsTimestampLong));
    BOOL logFlagEnabled = (_logOptions & (RMLogFormatterOptionsLogFlagShort | RMLogFormatterOptionsLogFlagLong));
    BOOL fileNameEnabled = (_logOptions & RMLogFormatterOptionsFileName);
    BOOL methodNameEnabled = (_logOptions & RMLogFormatterOptionsMethodName);
    BOOL lineNumbersEnabled = (_logOptions & RMLogFormatterOptionsLineNumber);
    BOOL threadNameEnabled = (_logOptions & RMLogFormatterOptionsThreadName) && logMessage->threadName.length;
    BOOL threadIDEnabled = (_logOptions & RMLogFormatterOptionsThreadID);
    
    if (timestampEnabled) {
        [logStats appendString:[self stringFromDate:logMessage->timestamp]];
    }
    
    if (logFlagEnabled) {
        NSString *logFlag = @"";
        switch (logMessage->logFlag) {
            case LOG_FLAG_ERROR:
                logFlag = (_logOptions & RMLogFormatterOptionsLogFlagShort) ? @"E" : @"  Error";
                break;
            case LOG_FLAG_WARN:
                logFlag = (_logOptions & RMLogFormatterOptionsLogFlagShort) ? @"W" : @"   Warn";
                break;
            case LOG_FLAG_INFO:
                logFlag = (_logOptions & RMLogFormatterOptionsLogFlagShort) ? @"I" : @"   Info";
                break;
            case LOG_FLAG_DEBUG:
                logFlag = (_logOptions & RMLogFormatterOptionsLogFlagShort) ? @"D" : @"  Debug";
                break;
            case LOG_FLAG_VERBOSE:
                logFlag = (_logOptions & RMLogFormatterOptionsLogFlagShort) ? @"V" : @"Verbose";
                break;
        }
        
        if (timestampEnabled) {
            [logStats appendFormat:@" | %@", logFlag];
        } else {
            [logStats appendString:logFlag];
        }
    }
    
    if (fileNameEnabled && !methodNameEnabled) {
        if (timestampEnabled | logFlagEnabled) {
            [logStats appendFormat:@" | %@", logMessage.fileName];
        } else {
            [logStats appendString:logMessage.fileName];
        }
    }
    
    if (methodNameEnabled) {
        if (timestampEnabled | logFlagEnabled | fileNameEnabled) {
            [logStats appendFormat:@" | %@", logMessage.methodName];
        } else {
            [logStats appendString:logMessage.methodName];
        }
    }
    
    if (lineNumbersEnabled) {
        if (fileNameEnabled | methodNameEnabled) {
            [logStats appendFormat:@":%d", logMessage->lineNumber];
        } else if (timestampEnabled | logFlagEnabled) {
            [logStats appendFormat:@" | Line:%d", logMessage->lineNumber];
        } else {
            [logStats appendFormat:@"Line:%d", logMessage->lineNumber];
        }
    }
    
    if (threadNameEnabled) {
        if (fileNameEnabled | methodNameEnabled | lineNumbersEnabled) {
            [logStats appendFormat:@" Thread:%@", logMessage->threadName];
        } else if (timestampEnabled | logFlagEnabled) {
            [logStats appendFormat:@" | Thread:%@", logMessage->threadName];
        } else {
            [logStats appendFormat:@"Thread:%@", logMessage->threadName];
        }
    }
    
    if (threadIDEnabled) {
        if (threadNameEnabled) {
            [logStats appendFormat:@"(%@)", logMessage.threadID];
        } else if (fileNameEnabled | methodNameEnabled | lineNumbersEnabled) {
            [logStats appendFormat:@" (TID:%@)", logMessage.threadID];
        } else if (timestampEnabled | logFlagEnabled) {
            [logStats appendFormat:@" | (TID:%@)", logMessage.threadID];
        } else {
            [logStats appendFormat:@"(TID:%@)", logMessage.threadID];
        }
    }
    
    NSString *fullLogMessage = [NSString stringWithFormat:@"%@ : %@", logStats, logMessage->logMsg];
    
    if (_logOptions & RMLogFormatterOptionsWordWrap) {
        // FIXME: If indentLength is longer than _lineLength word wrap over-indents.
        NSUInteger indentLength = logStats.length + 3;
        
        fullLogMessage = [self wrapString:fullLogMessage withLineLength:_lineLength indentLength:indentLength];
    }
    
    return fullLogMessage;
}

- (void)didAddToLogger:(id <DDLogger>)logger {
    OSAtomicIncrement32(&_atomicLoggerCount);
}

- (void)willRemoveFromLogger:(id <DDLogger>)logger {
    OSAtomicDecrement32(&_atomicLoggerCount);
}

@end
