//
//  CommonFun.h
//  PAPersonalDoctor
//
//  Created by 桃子 on 16/4/12.
//  Copyright © 2016年 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CommonFunc : NSObject

/**
 *  判断手机号是否合法
 *  @return 返回true 合法
 */
+ (BOOL)checkPhoneNum:(NSString *)phoneNum perrorMsg:(NSString **)perrorMsg;

// 格式化手机号：如13344446789 ==> 133****6789 (hiddenRange:NSRange(3,4) hiddenFlag:'*')
+ (NSString *)formatPhoneNum:(NSString *)phoneNum hiddenRange:(NSRange)hiddenRange hiddenFlag:(char)hiddenFlag;


@end
