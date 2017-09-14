//
//  PAThread.m
//  anchor
//
//  Created by Derek Lix on 9/21/16.
//  Copyright © 2016 PAJK. All rights reserved.
//

#import "PAThreadEngine.h"

@interface PAThreadEngine ()

@property(nonatomic,strong)NSThread* currentThread;

@end

@implementation PAThreadEngine

-(void)startThread{
    if (self.currentThread) {
        [self.currentThread cancel];
        self.currentThread = nil;
    }
    self.currentThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMain:) object:nil];
    [self.currentThread start];
}

-(void)stopThread{
    if (self.currentThread) {
        [self.currentThread cancel];
        self.currentThread = nil;
    }
}

-(NSThread*)paThread{
    
    return self.currentThread;
}


-(void)threadMain:(id)sender{
    
    [[NSThread currentThread] setName: @"paRunThread"];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addPort: [NSMachPort port] forMode: NSDefaultRunLoopMode];
    [runLoop run];
}

@end
