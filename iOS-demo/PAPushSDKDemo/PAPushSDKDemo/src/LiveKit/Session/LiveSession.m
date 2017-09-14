//
//  LiveSession.m
//  anchor
//
//  Created by wangweishun on 8/4/16.
//  Copyright © 2016 PAJK. All rights reserved.
//

#import "LiveSession.h"
#import "IAMediaRtmpEngine.h"
#import "IAAudioCaptureEngine.h"
#import "IAUtility.h"


@interface LiveSession() <PAVideoCameraFilterDelegate>

@property (nonatomic, strong) PACameraFilterEngine* cameraFilterEngine;



@end


@implementation LiveSession

- (instancetype)initWithVideoConfiguration:(PALiveVideoConfiguration *)videoConfiguration {
    if(!videoConfiguration){
                @throw [NSException exceptionWithName:@"LFLiveSession init error" reason:@"audioConfiguration or videoConfiguration is nil " userInfo:nil];
    }

    if (self = [super init]) {
        NSLog(@"liveSession initial");
        _videoConfiguration = videoConfiguration;
//        if ([IAUtility isIphone7]) {
//            _cameraFilterEngine = [[PACameraFilterEngine alloc] initWithAVCaptureSessionPreset:AVCaptureSessionPresetiFrame960x540  position:AVCaptureDevicePositionFront config:_videoConfiguration];
//        }else if ([IAUtility moreThanIphone6]){
//            _cameraFilterEngine = [[PACameraFilterEngine alloc] initWithAVCaptureSessionPreset:AVCaptureSessionPresetiFrame960x540  position:AVCaptureDevicePositionFront config:_videoConfiguration];
//        }else{
//            _cameraFilterEngine = [[PACameraFilterEngine alloc] initWithAVCaptureSessionPreset:AVCaptureSessionPreset640x480  position:AVCaptureDevicePositionFront config:_videoConfiguration];
//        }
        self.running = NO;
        _cameraFilterEngine = [[PACameraFilterEngine alloc] initWithAVCaptureSessionPreset:AVCaptureSessionPresetiFrame960x540  position:AVCaptureDevicePositionFront config:_videoConfiguration];
        _cameraFilterEngine.delegate = self;
    }
    return self;
}

//PACameraPreview *displayView = [[PACameraPreview alloc] initWithFrame:self.view.bounds];
//[self.view addSubview:displayView];
//self.cameraFilterEngine = [[PACameraFilterEngine alloc] initWithAVCaptureSessionPreset:AVCaptureSessionPreset640x480 position:AVCaptureDevicePositionFront];
//self.cameraFilterEngine.delegate = self;
//[self.cameraFilterEngine setDisplayView:displayView];
//[self.cameraFilterEngine startCameraCapture];


-(void)startLiveSession{
 
    if (self.cameraFilterEngine) {
        [self.cameraFilterEngine startCameraCapture];
    }
}

-(void)stopLiveSession{

    if (self.cameraFilterEngine) {
        [self.cameraFilterEngine stopCameraCapture];
    }
}


- (void)setPreView:(UIView *)preView{
    [self.cameraFilterEngine setDisplayView:preView];
}

- (UIView*)preView{
    return self.cameraFilterEngine.preView;
}

- (void)setCaptureDevicePosition:(AVCaptureDevicePosition)captureDevicePosition{
    [self.cameraFilterEngine swapFrontAndBackCameras:captureDevicePosition];
}

- (AVCaptureDevicePosition)captureDevicePosition{
    return self.cameraFilterEngine.captureDevicePosition;
}

- (void)setBeautyFace:(BOOL)beautyFace{
    if (beautyFace) {
        [self.cameraFilterEngine enableMakeupFilter];
    }else{
        [self.cameraFilterEngine disableMakeupFilter];
    }
}

- (BOOL)beautyFace {
    return self.cameraFilterEngine.filterOn;
}

- (void)setMuted:(BOOL)muted{
    //[self.audioCaptureSource setMuted:muted];
}

- (BOOL)muted{
    return NO;//self.audioCaptureSource.muted;
}

/**
 *	聚焦到某个点
 */
- (void)setFocusAtPoint:(CGPoint)point {
    [self.cameraFilterEngine focusInPoint:point];
}

- (void)setCameraBeautyFilterWithSmooth:(float)smooth white:(float)white pink:(float)pink {
    [self.cameraFilterEngine configMakeup:smooth brightness:white tone:pink];
}

//makeshift resolution for lockscreen crash
- (void)setAppOnScreen:(BOOL)onScreen{
    if (self.cameraFilterEngine) {
        [self.cameraFilterEngine setAppOnScreen:onScreen];
    }
}

#pragma mark - PAVideoCaptureDelegate
- (void)cameraOutputBuffer:(CVPixelBufferRef)pixelBuffer{
    
    if (_videoOutputEvent&&self.running) {
        _videoOutputEvent(&pixelBuffer,self);
    }
}
//- (void)captureOutput:(nullable PAVideoCaptureEngine *)capture pixelBuffer:(nullable CVImageBufferRef)pixelBuffer {
//    if (_videoOutputEvent) {
//        _videoOutputEvent(&pixelBuffer);
//    }
//}

@end
