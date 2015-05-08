//
//  RMStringWordWrapper.m
//  Pods
//
//  Created by Ryan Maloney on 3/11/15.
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

#import "RMStringWordWrapper.h"

static const NSUInteger RMStringWordWrapperDefaultWordWrapLength = 80;

@interface RMStringWordWrapper ()

@property (nonatomic, readwrite) NSUInteger wordWrapLength;

@end

@implementation RMStringWordWrapper

- (instancetype)init {
    return [self initWithWordWrapLength:RMStringWordWrapperDefaultWordWrapLength];
}

- (instancetype)initWithWordWrapLength:(NSUInteger)length {
    if ([super init]) {
        _wordWrapLength = length;
    }
    
    return self;
}

#pragma mark - Public Methods

- (NSString *)wrapString:(NSString *)string {
    return [self wrapString:string withIndentLength:0];
}

- (NSString *)wrapString:(NSString *)string withIndentLength:(NSUInteger)indentLength {
    if (![self shouldString:string wrapAtLength:self.wordWrapLength]) {
        return string;
    }
    
    NSString *indentString = [self wordWrapIndentStringWithLength:indentLength];
    
    NSMutableString *resultString = [NSMutableString new];
    NSMutableString *currentLineString = [NSMutableString new];
    NSScanner *scanner = [self stringScannerForWordWrappingWithString:string];
    
    NSUInteger remainingLength = self.wordWrapLength;
    NSString *scannedString = nil;
    while ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString: &scannedString]) {
        if (currentLineString.length + scannedString.length <= remainingLength) {
            [currentLineString appendString:scannedString];
        }
        else if (currentLineString.length == 0) { // Newline but next word > currentLineLength
            [resultString appendFormat:@"%@%@", scannedString, [scanner isAtEnd] ? @"" : indentString];
            remainingLength = self.wordWrapLength - indentLength;
        }
        else { // Need to break line and start new one
            [resultString appendFormat:@"%@%@", currentLineString, [scanner isAtEnd] ? @"" : indentString];
            [currentLineString setString:[NSString stringWithString:scannedString]];
            remainingLength = self.wordWrapLength - indentLength;
        }
        
        if ([scanner scanUpToCharactersFromSet:[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet] intoString:&scannedString]) {
            if ([scannedString rangeOfString:@"\n"].location != NSNotFound) {
                [currentLineString appendString:[scannedString stringByReplacingOccurrencesOfString:@"\n" withString:indentString]];
                [resultString appendString:currentLineString];
                [currentLineString setString:@""];
                remainingLength = self.wordWrapLength - indentLength;
            } else {
                [currentLineString appendString:scannedString];
            }
        }
    }
    
    [resultString appendString:currentLineString];
    
    return resultString;
}

#pragma mark - Private Methods

- (BOOL)shouldString:(NSString *)string wrapAtLength:(NSUInteger)length {
    return ((string.length > length) || [string rangeOfString:@"\n"].location != NSNotFound);
}

- (NSString *)stringByRepeatingCharacter:(char)character length:(NSUInteger)length {
    char stringUtf8[length + 1];
    memset(stringUtf8, character, length * sizeof(*stringUtf8));
    stringUtf8[length] = '\0';
    
    return [NSString stringWithUTF8String:stringUtf8];
}

- (NSString *)wordWrapIndentStringWithLength:(NSUInteger)length {
    return [NSString stringWithFormat:@"\n%@", [self stringByRepeatingCharacter:' ' length:length]];
}

- (NSScanner *)stringScannerForWordWrappingWithString:(NSString *)string {
    NSScanner *scanner = [NSScanner scannerWithString:string];
    scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@""];
    
    return scanner;
}

@end
