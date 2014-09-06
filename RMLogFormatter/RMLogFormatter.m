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

@interface RMLogFormatter ()

@end

@implementation RMLogFormatter {
    NSUInteger lineLength;
    int atomicLoggerCount;
    NSDateFormatter *threadUnsafeDateFormatter;
}

- (instancetype)initWithLogLineLength:(NSUInteger)logLineLength {
    if (self = [super init]) {
        lineLength = logLineLength;
    }
    
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        lineLength = 120;
    }
    
    return self;
}

- (NSString *)stringFromDate:(NSDate *)date {
    int32_t loggerCount = OSAtomicAdd32(0, &atomicLoggerCount);
    NSString *dateFormatString = @"yyyy/MM/dd HH:mm:ss:SSS";
    
    if (loggerCount <= 1) {
        // Single-threaded mode.
        
        if (threadUnsafeDateFormatter == nil) {
            threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
            [threadUnsafeDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            [threadUnsafeDateFormatter setDateFormat:dateFormatString];
        }
        
        return [threadUnsafeDateFormatter stringFromDate:date];
    } else {
        // Multi-threaded mode.
        // NSDateFormatter is NOT thread-safe.
        
        NSString *key = @"RMInfoFormatter_NSDateFormatter";
        
        NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
        NSDateFormatter *dateFormatter = [threadDictionary objectForKey:key];
        
        if (dateFormatter == nil) {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            [dateFormatter setDateFormat:dateFormatString];
            
            [threadDictionary setObject:dateFormatter forKey:key];
        }
        
        return [dateFormatter stringFromDate:date];
    }
}

- (NSString *)wrapString:(NSString *)sourceString withLineLength:(NSUInteger)length indentLength:(NSUInteger)indentLength {
    BOOL isMultiline = (sourceString.length > length);
    
    if (!isMultiline) {
        return sourceString;
    }
    
    NSUInteger firstLineLength = length;
    NSUInteger maxLineLength = firstLineLength;
    
    char spacesUtf8[indentLength + 1];
    memset(spacesUtf8, ' ', indentLength * sizeof(*spacesUtf8));
    spacesUtf8[indentLength] = '\0';
    NSString *indentString = [NSString stringWithFormat:@"\n%s", spacesUtf8];
    
    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSMutableString *currentLine = [[NSMutableString alloc] init];
    NSScanner *scanner = [NSScanner scannerWithString:sourceString];
    NSString *scannedString = nil;
    while ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString: &scannedString]) {
        if ([currentLine length] + [scannedString length] <= maxLineLength) {
            [currentLine appendFormat:@"%@ ", scannedString];
        }
        else if ([currentLine length] == 0) { // Newline but next word > currentLineLength
            [resultString appendFormat:@"%@%@", scannedString, [scanner isAtEnd] ? @"" : indentString];
            maxLineLength = length - indentLength;
        }
        else { // Need to break line and start new one
            [resultString appendFormat:@"%@%@", currentLine, [scanner isAtEnd] ? @"" : indentString];
            [currentLine setString:[NSString stringWithFormat:@"%@ ", scannedString]];
            maxLineLength = length - indentLength;
        }
        
        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
    }
    
    [resultString appendString:currentLine];
    
    return resultString;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSString *logLevel;
    switch (logMessage->logFlag) {
        case LOG_FLAG_ERROR:
            logLevel = @"E";
            break;
        case LOG_FLAG_WARN:
            logLevel = @"W";
            break;
        case LOG_FLAG_INFO:
            logLevel = @"I";
            break;
        case LOG_FLAG_DEBUG:
            logLevel = @"D";
            break;
        default:
            logLevel = @"V";
            break;
    }
    
    NSString *dateAndTime = [self stringFromDate:(logMessage->timestamp)];
    NSString *thread = [NSString stringWithFormat:@"TID:%d", logMessage->machThreadID];
    NSString *location = [NSString stringWithFormat:@"%@:%d",logMessage.fileName, logMessage->lineNumber];
    
    NSString *logStats = [NSString stringWithFormat:@"%@ | %@ | %@ | %@", logLevel, dateAndTime, thread, location];
    NSString *fullLogMsg = [NSString stringWithFormat:@"%@ | %@", logStats, logMessage->logMsg];
    
    NSUInteger statsLength = logStats.length;
    
    NSString *wordWrappedLogMessage = [self wrapString:fullLogMsg withLineLength:lineLength indentLength:statsLength + 3];
    
    return wordWrappedLogMessage;
}

- (void)didAddToLogger:(id <DDLogger>)logger {
    OSAtomicIncrement32(&atomicLoggerCount);
}

- (void)willRemoveFromLogger:(id <DDLogger>)logger {
    OSAtomicDecrement32(&atomicLoggerCount);
}

@end
