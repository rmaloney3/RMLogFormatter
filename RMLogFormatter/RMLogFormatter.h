//
//  RMLogFormatter.h
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

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

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

// TODO: Add customization flags to conditionally include addtional information
@interface RMLogFormatter : NSObject <DDLogFormatter>

@property (nonatomic, readonly) RMLogFormatterOptions options;
@property (nonatomic, readonly) NSUInteger lineLength;

- (instancetype)init;
- (instancetype)initWithLogLineLength:(NSUInteger)logLineLength;
- (instancetype)initWithOptions:(RMLogFormatterOptions)options;
- (instancetype)initWithLogLineLength:(NSUInteger)logLineLength options:(RMLogFormatterOptions)options;

@end
