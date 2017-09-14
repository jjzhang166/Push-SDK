//
//  JKNReachability.m
//  PAPersonalDoctor
//
//  Created by Perry Xiong on 15/10/22.
//  Copyright © 2015年 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#import "JKNReachability.h"
#import "Reachability.h"

NSString *const JKNReachabilityChangedNotification = @"JKNReachabilityChangedNotification";

@interface JKNReachability ()

@property (strong, nonatomic) Reachability *reachability;

@end

@implementation JKNReachability

+ (JKNReachability *)reachability {
    static dispatch_once_t onceToken;
    static JKNReachability *_instance = nil;
    dispatch_once(&onceToken, ^{
        _instance = [[JKNReachability alloc] init];
    });
    
    return _instance;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        self.reachability = [Reachability reachabilityForInternetConnection];
        
        __weak typeof(self) wself = self;
        self.reachability.reachableBlock = ^(Reachability * reachability){
            [wself postNotification];
        };
        self.reachability.unreachableBlock = ^(Reachability * reachability){
            [wself postNotification];
        };
    }
    
    return self;
}


- (void)postNotification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:JKNReachabilityChangedNotification
                                                            object:self];
    });
}


- (void)startService {
    [_reachability startNotifier];
}

- (void)stopService {
    [_reachability stopNotifier];
}

-(BOOL)isReachable {
    return [_reachability isReachable];
}

-(BOOL)isReachableViaWWAN {
    return [_reachability isReachableViaWWAN];
}

-(BOOL)isReachableViaWiFi {
    return [_reachability isReachableViaWiFi];
}

@end
