//
//  PAThread.h
//  anchor
//
//  Created by Derek Lix on 9/21/16.
//  Copyright © 2016 PAJK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PAThreadEngine : NSObject

-(void)startThread;
-(void)stopThread;
-(NSThread*)paThread;

@end
