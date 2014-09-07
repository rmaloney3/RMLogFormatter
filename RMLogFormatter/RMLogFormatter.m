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
        if (logLineLength < 80) {
            lineLength = 80;
        } else {
            lineLength = logLineLength;
        }
    }
    
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        lineLength = 120;
    }
    
    return self;
}

// TODO: Convert to NSString Category
- (NSString *)stringFromDate:(NSDate *)date {
    int32_t loggerCount = OSAtomicAdd32(0, &atomicLoggerCount);
    NSString *dateFormatString = @"yyyy-MM-dd HH:mm:ss.SSS";
    
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

// TODO: Convert to NSString Category
- (NSString *)stringByRepeatingCharacter:(char)character length:(NSUInteger)length {
    char stringUtf8[length + 1];
    memset(stringUtf8, character, length * sizeof(*stringUtf8));
    stringUtf8[length] = '\0';
    
    return [NSString stringWithUTF8String:stringUtf8];
}

- (NSString *)wrapString:(NSString *)sourceString withLineLength:(NSUInteger)length firstIndentLength:(NSUInteger)firstIndentLength secondIndentLength:(NSUInteger)secondIndentLength {
    BOOL isMultiline = ((sourceString.length > length) || [sourceString containsString:@"\n"]);
    
    if (!isMultiline) {
        return sourceString;
    }
    
    NSUInteger maxLineLength = length;
    
    NSString *indentString = [NSString stringWithFormat:@"\n%@", [self stringByRepeatingCharacter:' ' length:firstIndentLength]];
    
    NSMutableString *resultString = [[NSMutableString alloc] initWithFormat:@"%@%@", [sourceString substringToIndex:secondIndentLength], indentString];
    NSMutableString *currentLine = [[NSMutableString alloc] init];
    NSScanner *scanner = [NSScanner scannerWithString:[sourceString substringFromIndex:secondIndentLength]];
    scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@""];
    NSString *scannedString = nil;
    while ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString: &scannedString]) {
        if ([currentLine length] + [scannedString length] <= maxLineLength) {
            [currentLine appendString:scannedString];
        }
        else if ([currentLine length] == 0) { // Newline but next word > currentLineLength
            [resultString appendFormat:@"%@%@", scannedString, [scanner isAtEnd] ? @"" : indentString];
            maxLineLength = length - firstIndentLength;
        }
        else { // Need to break line and start new one
            [resultString appendFormat:@"%@%@", currentLine, [scanner isAtEnd] ? @"" : indentString];
            [currentLine setString:[NSString stringWithString:scannedString]];
            maxLineLength = length - firstIndentLength;
        }
        
        if ([scanner scanUpToCharactersFromSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet] intoString:&scannedString]) {
            [currentLine appendString:scannedString];
        }
        
        if ([scanner scanUpToCharactersFromSet:[[NSCharacterSet newlineCharacterSet] invertedSet] intoString:&scannedString]) {
            [resultString appendFormat:@"%@%@", currentLine, [scanner isAtEnd] ? @"" : indentString];
            [currentLine setString:@""];
            maxLineLength = length - firstIndentLength;
        }
    }
    
    [resultString appendString:currentLine];
    
    return resultString;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    //    NSString *logLevel;
    //    switch (logMessage->logFlag) {
    //        case LOG_FLAG_ERROR:
    //            logLevel = @"E";
    //            break;
    //        case LOG_FLAG_WARN:
    //            logLevel = @"W";
    //            break;
    //        case LOG_FLAG_INFO:
    //            logLevel = @"I";
    //            break;
    //        case LOG_FLAG_DEBUG:
    //            logLevel = @"D";
    //            break;
    //        default:
    //            logLevel = @"V";
    //            break;
    //    }
    
    NSString *dateAndTime = [self stringFromDate:(logMessage->timestamp)];
    NSString *location = [NSString stringWithFormat:@"%@:%d (TID:%@)",logMessage.fileName, logMessage->lineNumber, logMessage.threadID];
    
    NSString *logStats1 = [NSString stringWithFormat:@"%@ | ", dateAndTime];
    NSString *logStats2 = [NSString stringWithFormat:@"%@ ", location];
    NSString *fullLogMsg = [NSString stringWithFormat:@"%@%@: %@", logStats1, logStats2, logMessage->logMsg];
    
    NSUInteger indentLength1 = logStats1.length + 1;
    NSUInteger indentLength2 = logStats1.length + logStats2.length + 2;
    
    NSString *wordWrappedLogMessage = [self wrapString:fullLogMsg withLineLength:lineLength firstIndentLength:indentLength1 secondIndentLength:indentLength2];
    
    return wordWrappedLogMessage;
}

- (void)didAddToLogger:(id <DDLogger>)logger {
    OSAtomicIncrement32(&atomicLoggerCount);
}

- (void)willRemoveFromLogger:(id <DDLogger>)logger {
    OSAtomicDecrement32(&atomicLoggerCount);
}

@end
