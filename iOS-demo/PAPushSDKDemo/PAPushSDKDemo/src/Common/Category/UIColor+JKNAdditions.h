//
//  UIColor+JKNAdditions.h
//  PAPersonalDoctor
//
//  Created by Chunlin on 14-6-19.
//  Copyright (c) 2014年 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


#define JKNColorWithHex(hex) [UIColor jkn_colorWithHex:hex]


@interface UIColor (JKNAdditions)

+ (UIColor *)jkn_colorWithHex:(int)hex;
+ (UIColor *)jkn_colorWithHex:(int)hex alpha:(CGFloat)alpha;
+ (UIColor *)jkn_colorWithHexString:(NSString *)hexString;

@end
