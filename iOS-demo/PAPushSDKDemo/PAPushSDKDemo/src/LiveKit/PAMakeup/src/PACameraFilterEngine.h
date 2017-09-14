//
//  PACameraFilterEngine.h
//  PAMakeupDemo
//
//  Created by Derek Lix on 9/20/16.
//  Copyright © 2016 Derek Lix. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "PALiveVideoConfiguration.h"
#import "GPUImage.h"


@protocol PAVideoCameraFilterDelegate <NSObject>

@optional

- (void)cameraOutputBuffer:(CVPixelBufferRef)pixelBuffer;

@end


@interface PACameraFilterEngine : NSObject

@property(nonatomic, readonly) float smoothLevel;
@property(nonatomic, readonly) float brightnessLevel;
@property(nonatomic, readonly) float toneLevel;
@property(nonatomic, weak)UIView*  preView;
@property (nonatomic,readonly) AVCaptureDevicePosition captureDevicePosition;
@property(nonatomic, weak) id<PAVideoCameraFilterDelegate> delegate;
@property(nonatomic,assign)BOOL  filterOn;
@property(nonatomic,assign)BOOL  bufferProcessing;


- (instancetype)initWithAVCaptureSessionPreset:(NSString *const)sessionPreset position:(AVCaptureDevicePosition)position config:(PALiveVideoConfiguration *)config;

/**
 // smooth (磨皮)，范围:0.0-1.0      default 0.0
 // brightness (美白)，范围 0.0-1.0  default 0.0
 // tone (粉嫩)，范围 0.0-1.0        default 0.0
 */

- (void)configMakeup:(float)smooth  brightness:(float)brightness tone:(float)tone;

- (void)setDisplayView:(UIView*)view;
- (void)startCameraCapture;
- (void)stopCameraCapture;
- (void)enableMakeupFilter;
- (void)disableMakeupFilter;
- (void)swapFrontAndBackCameras:(AVCaptureDevicePosition)devicePosition;
- (void)focusInPoint:(CGPoint)devicePoint;
//makeshift resolution for lockscreen crash
- (void)setAppOnScreen:(BOOL)onScreen;

@end
