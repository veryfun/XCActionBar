//
//  XCSortSelectionAction.m
//  PGXcodeActionBrowser
//
//  Created by Pedro Gomes on 16/03/2015.
//  Copyright (c) 2015 Pedro Gomes. All rights reserved.
//

#import "XCSortSelectionAction.h"

#import "XCIDEContext.h"
#import "XCIDEHelper.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface XCSortSelectionAction ()

@property (nonatomic, assign) NSComparisonResult sortOrder;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *hint;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation XCSortSelectionAction

@synthesize title, subtitle, hint;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithSortOrder:(NSComparisonResult)sortOrder
{
    if((self = [super init])) {
        self.sortOrder = sortOrder;
        self.subtitle  = @"Sorts the selected text";
        self.title     = [NSString stringWithFormat:@"Sort selection (%@)", sortOrder == NSOrderedDescending ? @"descending" : @"ascending"];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)executeWithContext:(id<XCIDEContext>)context
{
    NSTextView *textView = context.sourceCodeTextView;

    NSRange rangeForSelectedText  = [context retrieveTextSelectionRange];
    NSRange lineRangeForSelection = [textView.string lineRangeForRange:rangeForSelectedText];
    
    NSArray *lineComponents = [[textView.string substringWithRange:lineRangeForSelection] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    if(lineComponents.count < 2) return NO; // nothing to sort

    NSComparator compareFunction  = (self.sortOrder == NSOrderedAscending ?
                                     ^(NSString *str1, NSString *str2) {
                                         NSString *trimmedStr1 = [str1 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                         NSString *trimmedStr2 = [str2 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                         return [trimmedStr1 compare:trimmedStr2 options:NSNumericSearch];
                                     } :
                                     ^(NSString *str1, NSString *str2) {
                                         NSString *trimmedStr1 = [str1 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                         NSString *trimmedStr2 = [str2 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                                         NSComparisonResult result = [trimmedStr1 compare:trimmedStr2 options:NSNumericSearch];
                                         switch(result) {
                                             case NSOrderedAscending:   return NSOrderedDescending;
                                             case NSOrderedDescending:  return NSOrderedAscending;
                                             case NSOrderedSame:        return NSOrderedSame;
                                         }
                                     });
    
    NSArray *sortedLineComponents = [lineComponents sortedArrayUsingComparator:compareFunction];
    NSString *sortedChunk         = [sortedLineComponents componentsJoinedByString:@"\n"];
    
    [textView.textStorage beginEditing];

    [textView insertText:sortedChunk replacementRange:lineRangeForSelection];

    [textView.textStorage endEditing];

    return YES;
}

@end
