//
//  UIImage+Color.m
//  PAPersonalDoctor
//
//  Created by wangweishun on 2/18/16.
//  Copyright © 2016 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#import "UIImage+Color.h"

@implementation UIImage (Color)

+ (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)imageVerticalGradientWithSize:(CGSize)size colors:(NSArray*)colors locations:(CGFloat[])locations
{
    UIGraphicsBeginImageContext(size);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    NSMutableArray *gradientColors = [NSMutableArray array];;
    for (UIColor *color in colors) {
        if ([color isKindOfClass:[UIColor class]]) {
            [gradientColors addObject:(id)color.CGColor];
        }
    }
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)gradientColors, locations);

    CGPoint beginPoint = CGPointMake(size.width / 2, 0);
    CGPoint endPoint = CGPointMake(size.width / 2, size.height);
    
    CGContextDrawLinearGradient(context, gradient, beginPoint, endPoint, 0);
    CGContextSaveGState(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    UIGraphicsEndImageContext();
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
    
    return image;
}

+ (UIImage *)imageHorizontalGradientWithSize:(CGSize)size colors:(NSArray *)colors locations:(CGFloat [])locations
{
    UIGraphicsBeginImageContext(size);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    NSMutableArray *gradientColors = [NSMutableArray array];;
    for (UIColor *color in colors) {
        if ([color isKindOfClass:[UIColor class]]) {
            [gradientColors addObject:(id)color.CGColor];
        }
    }
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)gradientColors, locations);

    CGPoint beginPoint = CGPointMake(0, size.height / 2);
    CGPoint endPoint = CGPointMake(size.width, size.height / 2);
    
    CGContextDrawLinearGradient(context, gradient, beginPoint, endPoint, 0);
    CGContextSaveGState(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
    
    return image;
}

+ (UIImage *)imageGradientWithSize:(CGSize)size colors:(NSArray *)colors gradientType:(PDGradientType)gradientType
{
    UIGraphicsBeginImageContext(size);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    NSMutableArray *ar = [NSMutableArray array];
    for(UIColor *color in colors) {
        if ([color isKindOfClass:[UIColor class]]) {
            [ar addObject:(id)color.CGColor];
        }
    }

    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)ar, NULL);
    CGPoint start;
    CGPoint end;
    switch (gradientType) {
        case PDGradientTopToBottom:
            start = CGPointMake(0.0, 0.0);
            end = CGPointMake(0.0, size.height);
            break;
        case PDGradientLeftToRight:
            start = CGPointMake(0.0, 0.0);
            end = CGPointMake(size.width, 0.0);
            break;
        case PDGradientUpleftToLowRight:
            start = CGPointMake(0.0, 0.0);
            end = CGPointMake(size.width, size.height);
            break;
        case PDGradientUprightToLowLeft:
            start = CGPointMake(size.width, 0.0);
            end = CGPointMake(0.0, size.height);
            break;
        default:
            break;
    }
    CGContextDrawLinearGradient(context, gradient, start, end, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    CGContextSaveGState(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);

    return image;
}

@end
