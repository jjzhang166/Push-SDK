//
//  UILabel+Size.m
//  PAPersonalDoctor
//
//  Created by wangweishun on 9/2/15.
//  Copyright (c) 2015 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#import "UILabel+Size.h"

@implementation UILabel (Size)

- (void)setLineSpace:(CGFloat)lineSpace
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = lineSpace;
    NSDictionary *ats = @{
                          NSFontAttributeName : self.font,
                          NSForegroundColorAttributeName : self.textColor,
                          NSParagraphStyleAttributeName : paragraphStyle
                          };
    self.attributedText = [[NSAttributedString alloc] initWithString:self.text attributes:ats];
}

- (CGFloat)sizeToFitNumberOfLines:(NSUInteger)lines
{
    CGSize size = [self textRectForBounds:CGRectMake(0, 0, self.width, FLT_MAX) limitedToNumberOfLines:lines].size;
    return size.height;
}

- (CGFloat)sizetoWidthWithNumberOfLines:(NSInteger)line
{
    CGSize size = [self textRectForBounds:CGRectMake(0, 0, FLT_MAX, self.width) limitedToNumberOfLines:line].size;
    return size.width;
}

- (void)sizeToFitNumberOfLinesWithLineSpace:(CGFloat)lineSpace
{
    CGRect textRect = [self textRectForBounds:CGRectMake(0, 0, self.width, FLT_MAX) limitedToNumberOfLines:self.numberOfLines];
    self.height = textRect.size.height + lineSpace * (self.numberOfLines > 1? self.numberOfLines - 1 : 0); // do not change width here (may cause problem within an animation block)
}

@end
