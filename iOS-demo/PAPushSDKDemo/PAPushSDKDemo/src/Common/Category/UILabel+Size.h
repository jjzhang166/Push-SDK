//
//  UILabel+Size.h
//  PAPersonalDoctor
//
//  Created by wangweishun on 9/2/15.
//  Copyright (c) 2015 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILabel (Size)

- (void)setLineSpace:(CGFloat)lineSpace;

- (CGFloat)sizeToFitNumberOfLines:(NSUInteger)lines;

- (CGFloat)sizetoWidthWithNumberOfLines:(NSInteger)line;

- (void)sizeToFitNumberOfLinesWithLineSpace:(CGFloat)lineSpace;

@end
