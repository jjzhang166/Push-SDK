//
//  IAVideoCaptureEngine.h
//  MediaRecorder
//
//  Created by Derek Lix on 15/12/17.
//  Copyright © 2015年 Derek Lix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "LiveConfig.h"


typedef void(^IAVideoAuthorizationHandler)(BOOL authoried);


@interface IAVideoCaptureEngine : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate>

@property(nonatomic,strong)AVCaptureVideoDataOutput* outputDevice;
@property (nonatomic,weak) id outputSampleBufferDelegateObserver;

-(id)initWithSuperView:(UIView*)superView outputSampleBufferDelegateObserver:(id)delegateObserver   authorizationHandler:(IAVideoAuthorizationHandler)handler;

-(void)startVideoPreview;
-(void)restartVideoWith:(PADefinition)definition;
-(void)stopVideoCapture;
-(void)setVideoScaleAndCropFactor:(CGFloat)factor;
-(void)captureStillImageWith:(NSString*)destinationImageUrl;
-(void)setCaptureVideoOrientation:(AVCaptureVideoOrientation)orientation;

//默认是后置摄像头
- (void)switchCaptureDevicePosition;

@end
