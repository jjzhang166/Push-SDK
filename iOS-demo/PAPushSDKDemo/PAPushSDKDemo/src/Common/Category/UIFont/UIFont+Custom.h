//
//  UIFont+Custom.h
//  PAPersonalDoctor
//
//  Created by wangweishun on 1/19/15.
//  Copyright (c) 2015 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PAFontSize) {
    PAFontSizeHugeLarge = 17,   //特大字体（导航栏等）
    PAFontSizeLarge = 15,       //大字体（姓名、标题类型等）
    PAFontSizeMiddle = 13,      //中字体（描述类型等）
    PAFontSizeSmall = 12        //小字体
};

@interface UIFont (Custom)

+ (UIFont *)sysFontOfSize:(PAFontSize)fontSize;

+ (UIFont *)sysBoldFontOfSize:(PAFontSize)fontSize;

+ (UIFont *)pingFangFont:(CGFloat)fontSize;

+ (UIFont *)pingFangSemiboldFont:(CGFloat)fontSize;

+ (UIFont *)pingFangBoldFont:(CGFloat)fontSize;

+ (UIFont *)sfUIDisplayBold:(CGFloat)fontSize;

+ (UIFont *)pingFangMedium:(CGFloat)fontSize;

+ (UIFont *)pingFangHeavy:(CGFloat)fontSize;

+ (UIFont *)pingFangRegular:(CGFloat)fontSize;

@end
