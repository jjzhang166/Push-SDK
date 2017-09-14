//
//  PDTimer.m
//  PAPersonalDoctor
//
//  Created by qzp on 16/3/3.
//  Copyright © 2016年 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#import "PDTimer.h"
#import "NSTimer+Addition.h"


@interface PDTimer ()

@property (nonatomic,readwrite) NSTimer *interTimer;
@property (nonatomic ,copy) void(^actionBlock)(id userInfo);

@end

@implementation PDTimer

+ (PDTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti userInfo:(id)userInfo repeats:(BOOL)yesOrNo actionBlock:(void(^)(id userInfo))actionBlock
{
    PDTimer *timer = [[PDTimer alloc] init];
    timer.actionBlock = actionBlock;
    timer.interTimer = [NSTimer scheduledTimerWithTimeInterval:ti target:timer selector:@selector(onTimerFierd:) userInfo:userInfo repeats:yesOrNo];
    return timer;
}

- (void)onTimerFierd:(NSTimer *)timer
{
    if (self.actionBlock) {
        self.actionBlock(timer.userInfo);
    }
}


- (void)invalidate
{
    [self.interTimer invalidate];
    self.interTimer = nil;
    self.actionBlock = nil;
}

- (void)pauseTimer
{
    [self.interTimer pauseTimer];
}

- (void)resumeTimer
{
    [self.interTimer resumeTimer];
}

- (void)resumeTimerAfterTimeInterval:(NSTimeInterval)interval
{
    [self.interTimer resumeTimerAfterTimeInterval:interval];
}

- (BOOL)isValid
{
    return [self.interTimer isValid];
}

- (void)dealloc
{
    PADebug(@"dealloc:%@",self);
}

@end
