//
//  UIImage+Color.h
//  PAPersonalDoctor
//
//  Created by wangweishun on 2/18/16.
//  Copyright © 2016 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM (NSInteger, PDGradientType) {
    PDGradientTopToBottom = 0,     //从上到小
    PDGradientLeftToRight = 1,     //从左到右
    PDGradientUpleftToLowRight = 2,   //左上到右下
    PDGradientUprightToLowLeft = 3,   //右上到左下
};

@interface UIImage (Color)

+ (UIImage *)imageWithColor:(UIColor *)color;

+ (UIImage *)imageVerticalGradientWithSize:(CGSize)size colors:(NSArray *)colors locations:(CGFloat[])locations;
+ (UIImage *)imageHorizontalGradientWithSize:(CGSize)size colors:(NSArray *)colors locations:(CGFloat [])locations;
+ (UIImage *)imageGradientWithSize:(CGSize)size colors:(NSArray *)colors gradientType:(PDGradientType)gradientType;

@end
