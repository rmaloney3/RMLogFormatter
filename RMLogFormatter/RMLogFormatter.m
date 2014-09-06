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
    int atomicLoggerCount;
    NSDateFormatter *threadUnsafeDateFormatter;
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
    
    return fullLogMsg;
}

- (void)didAddToLogger:(id <DDLogger>)logger {
    OSAtomicIncrement32(&atomicLoggerCount);
}

- (void)willRemoveFromLogger:(id <DDLogger>)logger {
    OSAtomicDecrement32(&atomicLoggerCount);
}

@end