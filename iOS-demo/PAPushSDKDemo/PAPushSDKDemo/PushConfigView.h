//
//  PushConfigView.h
//  PAPushSDKDemo
//
//  Created by Derek Lix on 21/06/2017.
//  Copyright © 2017 Derek Lix. All rights reserved.
//

#import <UIKit/UIKit.h>

#define  IA_DefaultRtmpUrl    @"rtmp://livepush.test.pajk.cn/live/pushdemo"

typedef void(^ConfigViewHandler)(BOOL restart, NSString* definition,NSString* resoultion, NSString* pushUrl);

@interface PushConfigView : UIView

- (instancetype)initWithFrame:(CGRect)frame configViewHandler:(ConfigViewHandler)configViewHandler;

@end
