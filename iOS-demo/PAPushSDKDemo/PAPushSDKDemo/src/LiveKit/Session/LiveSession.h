//
//  LiveSession.h
//  anchor
//
//  Created by wangweishun on 8/4/16.
//  Copyright © 2016 PAJK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PACameraFilterEngine.h"
#import "PALiveVideoConfiguration.h"

typedef void (^VideoOutputEvent)(CVImageBufferRef *pixelBuffer, id owner);

@interface LiveSession : NSObject

@property (nonatomic, strong) PALiveVideoConfiguration *videoConfiguration;

/** The running control start capture or stop capture*/
@property (nonatomic, assign) BOOL running;

/** The preView will show OpenGL ES view*/
@property (nonatomic, strong) UIView *preView;

/** The captureDevicePosition control camraPosition ,default front*/
@property (nonatomic, assign) AVCaptureDevicePosition captureDevicePosition;

/** The beautyFace control capture shader filter empty or beautiy */
@property (nonatomic, assign) BOOL beautyFace;

/** The muted control callbackAudioData,muted will memset 0.*/
@property (nonatomic,assign) BOOL muted;

@property (nonatomic, copy) VideoOutputEvent videoOutputEvent;

- (instancetype)initWithVideoConfiguration:(PALiveVideoConfiguration *)videoConfiguration;

/**
 *	聚焦到某个点
 */
- (void)setFocusAtPoint:(CGPoint)point;

- (void)setCameraBeautyFilterWithSmooth:(float)smooth white:(float)white pink:(float)pink;

-(void)startLiveSession;
-(void)stopLiveSession;
//makeshift resolution for lockscreen crash
- (void)setAppOnScreen:(BOOL)onScreen;

@end
