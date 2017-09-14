//
//  PushViewController.h
//  PAPushSDKDemo
//
//  Created by Derek Lix on 21/06/2017.
//  Copyright © 2017 Derek Lix. All rights reserved.
//

#import <UIKit/UIKit.h>

//推流状态
typedef NS_ENUM(NSUInteger, LivePushStatus) {
    LivePushStatusNone = 0,
    LivePushStatusStart,
    LivePushStatusRuning,
    LivePushStatusFailed,
    LivePushStatusEnd
};

@interface PushViewController : UIViewController

@property (nonatomic, assign) LivePushStatus pushStatus;

@end
