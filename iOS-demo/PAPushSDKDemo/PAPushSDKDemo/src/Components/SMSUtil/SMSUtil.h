//
//  SMSUtil.h
//  PAAccountFramework
//
//  Created by shen peng on 14-5-11.
//  Copyright (c) 2014年 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

@interface SMSUtil : NSObject

/**
 *  发送短信
 *
 *  @param message               短信内容
 *  @param recipients            短信接收者s
 *  @param currentViewController 当前页面VC
 *  @param delegate              代理
 */
+ (void)sendMessage:(NSString *)message
         recipients:(NSArray *)recipients
                 vc:(UIViewController *)currentViewController
    composeDelegate:(id<MFMessageComposeViewControllerDelegate>)delegate;
@end
