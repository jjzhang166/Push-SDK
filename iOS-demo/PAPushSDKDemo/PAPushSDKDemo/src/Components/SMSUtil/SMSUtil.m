//
//  SMSUtil.m
//  PAAccountFramework
//
//  Created by shen peng on 14-5-11.
//  Copyright (c) 2014年 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#import "SMSUtil.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

@implementation SMSUtil

+ (void)sendMessage:(NSString *)message recipients:(NSArray *)recipients vc:(UIViewController *)currentViewController composeDelegate:(id<MFMessageComposeViewControllerDelegate>)delegate
{
    if (message == nil ||
        recipients == nil ||
        message.length == 0 ||
        recipients.count == 0)
    {
        return;
    }

    Class messageClass = (NSClassFromString(@"MFMessageComposeViewController"));
    if ([messageClass canSendText])//校验设备是否支持发短信
    {
        //校验是否有SIM卡
        CTTelephonyNetworkInfo *networkInfo =  [[CTTelephonyNetworkInfo alloc] init];
        CTCarrier *carrier = networkInfo.subscriberCellularProvider;
        if (carrier.mobileCountryCode.length > 0)
        {
            MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
            picker.messageComposeDelegate = delegate;
            picker.body = message;
            picker.recipients = recipients;
            
            [currentViewController presentViewController:picker animated:YES completion:nil];
            [picker release];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"未安装SIM卡" message:nil delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
        [networkInfo release];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"设备没有短信功能" message:nil delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

@end
