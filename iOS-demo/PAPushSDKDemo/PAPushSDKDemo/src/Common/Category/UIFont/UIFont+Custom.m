//
//  UIFont+Custom.m
//  PAPersonalDoctor
//
//  Created by wangweishun on 1/19/15.
//  Copyright (c) 2015 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#import "UIFont+Custom.h"

@implementation UIFont (Custom)

+ (UIFont *)sysFontOfSize:(PAFontSize)fontSize
{
    return [UIFont systemFontOfSize:fontSize];
}

+ (UIFont *)sysBoldFontOfSize:(PAFontSize)fontSize
{
    return [UIFont boldSystemFontOfSize:fontSize];
}

+ (UIFont *)pingFangFont:(CGFloat)fontSize
{
    UIFont *font = [UIFont fontWithName:@"PingFang SC" size:fontSize];
    return (font == nil) ? [UIFont systemFontOfSize:fontSize] : font;
}

+ (UIFont *)pingFangSemiboldFont:(CGFloat)fontSize
{
    UIFont *font = [UIFont fontWithName:@"PingFangSC-Semibold" size:fontSize];
    return (font == nil) ? [UIFont systemFontOfSize:fontSize] : font;
}

+ (UIFont *)pingFangBoldFont:(CGFloat)fontSize
{
    UIFont *font = [UIFont fontWithName:@"PingFang-SC-Bold" size:fontSize];
    return (font == nil) ? [UIFont boldSystemFontOfSize:fontSize] : font;
}

+ (UIFont *)sfUIDisplayBold:(CGFloat)fontSize
{
    UIFont *font = [UIFont fontWithName:@"SF UI Display Bold" size:fontSize];
    return (font == nil) ? [UIFont systemFontOfSize:fontSize] : font;
}

+ (UIFont *)pingFangMedium:(CGFloat)fontSize
{
    UIFont *font = [UIFont fontWithName:@"PingFangSC-Medium" size:fontSize];
    return (font == nil) ? [UIFont systemFontOfSize:fontSize] : font;
}

+(UIFont *)pingFangHeavy:(CGFloat)fontSize
{
    UIFont *font = [UIFont fontWithName:@"PingFang-SC-Heavy" size:fontSize];
    return (font == nil) ? [UIFont systemFontOfSize:fontSize] : font;
}

+ (UIFont *)pingFangRegular:(CGFloat)fontSize
{
    UIFont *font = [UIFont fontWithName:@"PingFang-SC-Regular" size:fontSize];
    return (font == nil) ? [UIFont systemFontOfSize:fontSize] : font;
}
@end
