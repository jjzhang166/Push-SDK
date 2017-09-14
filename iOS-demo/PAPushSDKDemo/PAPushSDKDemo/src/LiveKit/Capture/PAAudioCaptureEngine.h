//
//  PAAudioCaptureEngine.h
//  anchor
//
//  Created by Derek Lix on 24/11/2016.
//  Copyright © 2016 PAJK. All rights reserved.
//

#import <Foundation/Foundation.h>



@protocol PAAudioCoderDelegate <NSObject>

-(void)beginningCode;
-(void)audioCoder:(char*)outputData length:(UInt32)length;

@end


@interface PAAudioCaptureEngine : NSObject

@property(nonatomic,weak)id<PAAudioCoderDelegate>  delegate;
@property(nonatomic,assign)BOOL      isRunning;

- (void) start;
- (void) stop;

-(void)setVolumeEngine:(NSInteger)volume;

@end
