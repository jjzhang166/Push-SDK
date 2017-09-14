//
//  UIColor+JKNAdditions.m
//  PAPersonalDoctor
//
//  Created by Chunlin on 14-6-19.
//  Copyright (c) 2014年 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#import "UIColor+JKNAdditions.h"

@implementation UIColor (JKNAdditions)

+ (UIColor *)jkn_colorWithHex:(int)hex {
    return [self jkn_colorWithHex:hex alpha:1];
}

+ (UIColor *)jkn_colorWithHex:(int)hex alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16)) / 255.0 green:((float)((hex & 0xFF00) >> 8)) / 255.0 blue:((float)(hex & 0xFF)) / 255.0 alpha:alpha];
}

+ (UIColor *)jkn_colorWithHexString:(NSString *)hexString {
    unsigned hexValue = 0;
    if ([hexString hasPrefix:@"#"]) {
        hexString = [hexString substringFromIndex:1];
    }

    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner scanHexInt:&hexValue];
    return [self jkn_colorWithHex:hexValue];
}

@end
