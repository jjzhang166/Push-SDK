//
//  CommonFun.m
//  PAPersonalDoctor
//
//  Created by 桃子 on 16/4/12.
//  Copyright © 2016年 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#import "CommonFunc.h"
#import <AdSupport/AdSupport.h>
#import <sys/utsname.h>

@implementation CommonFunc

+ (BOOL)checkPhoneNum:(NSString *)phoneNum perrorMsg:(NSString **)perrorMsg
{
    if (phoneNum == nil || phoneNum.length == 0) {
        *perrorMsg = @"手机号不能为空";
        return NO;
    }
    if ([[phoneNum substringToIndex:1] isEqualToString:@"1"] == NO) {
        *perrorMsg = @"手机号错误，请重新输入";//@"手机号必须以1开头";
        return NO;
    }
#if 0
    NSString *MOBILE = @"^1(3[0-9]|4[57]|5[0-35-9]|8[0-9]|7[06-8])\\d{8}$";
//    NSString * MOBILE = @"[0-9]{11}";
    NSPredicate *regextestmobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
    if ([regextestmobile evaluateWithObject:phoneNum] == NO) {
        *perrorMsg = @"手机号错误，请重新输入";//@"手机号要以1开头的11位数字";
        return NO;
    }
#else
    if (phoneNum.length != 11) {
        *perrorMsg = @"手机号错误，请重新输入";
        return NO;
    }
#endif
    return YES;
}

// 格式化手机号：如13344446789 ==> 133****6789 (hiddenRange:NSRange(3,4) hiddenFlag:'*')
+ (NSString *)formatPhoneNum:(NSString *)phoneNum hiddenRange:(NSRange)hiddenRange hiddenFlag:(char)hiddenFlag {
    NSString *hiddenString = @"";
    NSString *resultString = nil;
    if (hiddenRange.location < phoneNum.length) {
        if (([phoneNum length]-hiddenRange.location) < hiddenRange.length) {
            for (NSInteger i = 0; i < [phoneNum length]-hiddenRange.location; i ++){
                hiddenString = [hiddenString stringByAppendingFormat:@"%c", hiddenFlag];
            }
            resultString = [phoneNum stringByReplacingCharactersInRange:NSMakeRange(hiddenRange.location, [phoneNum length]-hiddenRange.location) withString:hiddenString];
        } else {
            for (NSInteger i = 0; i < hiddenRange.length; i ++){
                hiddenString = [hiddenString stringByAppendingFormat:@"%c", hiddenFlag];
            }
            resultString = [phoneNum stringByReplacingCharactersInRange:hiddenRange withString:hiddenString];
        }
    } else {
        resultString = phoneNum;
    }
    
    return resultString;
}

@end
