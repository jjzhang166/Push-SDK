//
//  PDTimer.h
//  PAPersonalDoctor
//
//  Created by qzp on 16/3/3.
//  Copyright © 2016年 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PDTimer : NSObject

@property (nonatomic,readonly) NSTimer *interTimer;

@property (readonly, getter=isValid) BOOL valid;

+ (PDTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti userInfo:(id)userInfo repeats:(BOOL)yesOrNo actionBlock:(void(^)(id userInfo))actionBlock;

// must be called when the holder is dealloc
- (void)invalidate;

- (void)pauseTimer;
- (void)resumeTimer;
- (void)resumeTimerAfterTimeInterval:(NSTimeInterval)interval;


@end
