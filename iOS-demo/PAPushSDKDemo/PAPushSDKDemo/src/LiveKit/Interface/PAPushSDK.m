//
//  PAPushSDK.m
//  anchor
//
//  Created by wangweishun on 8/6/16.
//  Copyright © 2016 PAJK. All rights reserved.
//

#import "PAPushSDK.h"
#import "IAMediaRtmpEngine.h"
#import "IAVideoCaptureEngine.h"
#import "IAAudioCaptureEngine.h"
#import "LiveSession.h"
#import "PAAudioCaptureEngine.h"
#import "IAUtility.h"

#define __USE_GPUIMAGE__
#define PA_SUPPORT_BLUETOOTH_AUDIOCAPTURE    @"PA_SUPPORT_BLUETOOTH_AUDIOCAPTURE"

@interface PAPushSDK () <IAMediaRtmpEngineDelegate, IAAudioCaptureEngineDelegate>

@property (nonatomic, strong) IAMediaRtmpEngine *rtmpEngine;
@property (nonatomic, strong) IAVideoCaptureEngine *videoCaptureEngine;
@property (nonatomic, strong) IAAudioCaptureEngine *audioCaptureEngine;
@property (nonatomic, strong) PAAudioCaptureEngine*  paAudioEngine;

@property (nonatomic, strong) LiveSession *liveSession;

@property (nonatomic, assign) PABitRate    bitRate;
@property (nonatomic, assign) PADefinition definition;
@property (nonatomic, assign) NSInteger    fps;
@property (nonatomic, assign) NSInteger    smapleRate;
@property (nonatomic, assign) NSInteger    channels;
@property (nonatomic, assign) NSInteger    sampleBit;

@property (nonatomic, copy) NSString *pushUrl;
@property (nonatomic, assign) BOOL isPushing;
@property (nonatomic, assign) BOOL reStartStream; //重新推流标志
@property (nonatomic, strong) UIView*  displayWindow;
@property (nonatomic, strong) PAPushSDKCallbackHandler  sdkCallbackHandler;
@property (nonatomic, assign) int reStartPushTimes; //重新推流次数
@property (nonatomic, assign) NSInteger currentVolume;
@property (nonatomic, strong) NSTimer*  discardFrameRateTimer;
@property (nonatomic, assign) NSInteger  discardcount;

@end

@implementation PAPushSDK

+ (NSString *)sdkVersion
{
    return @"1.1.0";
}

- (id)initPushSDK:(PAPushSDKCallbackHandler)callback {
    
    if (self = [super init]) {
        self.isPushing = NO;
        self.sdkCallbackHandler = callback;
        self.currentVolume = 10;
        [self registerNoitficationObserver];
    }
    self.reStartPushTimes = 0;
    return self;
}

- (void)setParam:(PADefinition)definition fps:(int)fps sampleRate:(int)sampleRate sampleBit:(int)sampleBit channels:(int)channels
         bitRate:(PABitRate)bitRate {
    
    self.definition = definition;
    self.bitRate = bitRate;
    self.fps = fps;
    self.smapleRate = sampleRate;
    self.channels = channels;
    self.sampleBit = sampleBit;
}

- (void)setWindow:(UIView *)window {
    self.displayWindow = window;
}

- (void)setPushUrl:(NSString *)url {
    assert(url);
    _pushUrl = url;
}

- (void)setVolume:(NSInteger)volume {
    self.currentVolume = volume;
    if (self.rtmpEngine) {
        [self.rtmpEngine setVolumeEngine:volume];
    }
#ifdef PA_SUPPORT_BLUETOOTH_AUDIOCAPTURE
    if (self.paAudioEngine) {
        [self.paAudioEngine setVolumeEngine:volume];
    }
#endif
}

- (void)setupDevice
{
#ifdef __USE_GPUIMAGE__
    [self startGPUSession];
#else
    [self startPreviewCamera];
#endif
}

- (void)startStreaming {
    _reStartStream = NO;
    [self startRtmp];
    [self startPushStreaming];
}

- (void)stopStreaming {
    [self stopPushStreaming];
}

-(void)setIsPushing:(BOOL)isPushing{
    
    _isPushing = isPushing;
    _liveSession.running = isPushing;  //video
    if (_paAudioEngine) {   //audio
        _paAudioEngine.isRunning = isPushing;
    }
}

- (CGFloat)getSendSpeed {
    
    [self checkRuntimeAVData];
    if (self.rtmpEngine) {
        return [self.rtmpEngine upLoadNetworkSpeed];
    }
    return 0;
}

-(void)checkRuntimeAVData{
    
    if (!self.rtmpEngine)
        return;

    if(!self.rtmpEngine.isPushing)
        return;

    int ErrorType = NONE_BLOCK;
    double sysTime = [[NSDate date] timeIntervalSince1970];


    if (0 == self.rtmpEngine.beforeAudioSendTimeInterval) {
        // AUDIO Send NOT even started.
        self.rtmpEngine.beforeAudioSendTimeInterval = sysTime;
        self.rtmpEngine.afterAudioSendedTimeInterval = sysTime;
    } else if(0 != self.rtmpEngine.beforeAudioSendTimeInterval && 0 == self.rtmpEngine.afterAudioSendedTimeInterval) {
        // AUDIO Send was stuck a few ms at the begin of push stream.
        self.rtmpEngine.afterAudioSendedTimeInterval = self.rtmpEngine.beforeAudioSendTimeInterval;
    }

    if (0 == self.rtmpEngine.beforeVideoSendTimeInterval){
        // VIDEO Send NOT even started.
        self.rtmpEngine.beforeVideoSendTimeInterval = sysTime;
        self.rtmpEngine.afterVideoSendedTimeInterval = sysTime;
    } else if (0 != self.rtmpEngine.beforeVideoSendTimeInterval && 0 == self.rtmpEngine.afterVideoSendedTimeInterval){
        // VIDEO Send was stuck a few ms at the begin of push stream.
        self.rtmpEngine.afterVideoSendedTimeInterval = self.rtmpEngine.beforeVideoSendTimeInterval;
    }

    if(sysTime - self.rtmpEngine.afterVideoSendedTimeInterval >= 60){ // Video.
        if(self.rtmpEngine.beforeVideoSendTimeInterval > (self.rtmpEngine.afterVideoSendedTimeInterval + 30))
            ErrorType = VIDEO_SEND_BLOCKED; // Video send blocked more than 30s.
        else if(self.rtmpEngine.beforeVideoEncodeTimeInterval > (self.rtmpEngine.afterVideoEncodedTimeInterval + 30))
            ErrorType = VIDEO_ENCODER_BLOCKED; // Video encoder blocked more than 30s.
        else if(sysTime > (self.rtmpEngine.beforeVideoEncodeTimeInterval + 30))
            ErrorType = VIDEO_CAPTURE_BLOCKED; // Video capture no callback more than 30s.
        else if(sysTime < (self.rtmpEngine.beforeVideoEncodeTimeInterval + 10))
            ErrorType = VIDEO_ENCODER_DROPPED; // Video encoded data dropped.
        else
            ErrorType = VIDEO_BLOCKED_UNKNOWN; // Unknown block.
        
        if (self.sdkCallbackHandler) {
            self.sdkCallbackHandler(ErrorType, PA_PUSH_EXCEPTION, 0);
        }
    }

    if(sysTime - self.rtmpEngine.afterAudioSendedTimeInterval >= 60){ // Audio.
        if(self.rtmpEngine.beforeAudioSendTimeInterval > (self.rtmpEngine.afterAudioSendedTimeInterval + 30))
            ErrorType = AUDIO_SEND_BLOCKED; // Audio send blocked more than 30s.
        else if(self.rtmpEngine.beforeAudioEncodeTimeInterval > (self.rtmpEngine.afterAudioEncodedTimeInterval + 30))
            ErrorType = AUDIO_ENCODER_BLOCKED; // Audio encoder blocked more than 30s.
        else if(sysTime > (self.rtmpEngine.beforeAudioEncodeTimeInterval + 30))
            ErrorType = AUDIO_CAPTURE_BLOCKED; // Audio capture no callback more than 30s.
        else if(sysTime < (self.rtmpEngine.beforeAudioEncodeTimeInterval + 10))
            ErrorType = AUDIO_ENCODER_DROPPED; // Audio encoded data dropped.
        else
            ErrorType = AUDIO_BLOCKED_UNKNOWN; // Unknown block.
        
        if (self.sdkCallbackHandler) {
            self.sdkCallbackHandler(ErrorType, PA_PUSH_EXCEPTION, 0);
        }
    }
}

- (PABitRate)getBitRate {
    return _bitRate;
}

- (NSInteger)getVideoDroppedFrameNum {
    return 0;
}

- (void)setCameraFront:(BOOL)cameraFront {
    self.liveSession.captureDevicePosition = cameraFront? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
}

- (void)setBeautyFace:(BOOL)beautyFace {
    self.liveSession.beautyFace = beautyFace;
}

- (void)setCameraBeautyFilterWithSmooth:(float)smooth white:(float)white pink:(float)pink {
    [self.liveSession setCameraBeautyFilterWithSmooth:smooth white:white pink:pink];
}

- (void)setFocusAtPoint:(CGPoint)point {
    [self.liveSession setFocusAtPoint:point];
}

- (void)destroy {
    LogInfo(@"[PushSDK] PAPush destroy");
    if (self.discardFrameRateTimer) {
        [self.discardFrameRateTimer invalidate];
        self.discardFrameRateTimer = nil;
    }
    [self unRegisterNoitficationObserver];
    [self stopPushStreaming];
    if (self.videoCaptureEngine) {
        [self.videoCaptureEngine stopVideoCapture];
        self.videoCaptureEngine = nil;
    }
    if (self.audioCaptureEngine) {
        [self.audioCaptureEngine close];
        self.audioCaptureEngine = nil;
    }
    [self stopGPUSession];
}

-(CGFloat)dropdownFrameRate{
    
    if (self.rtmpEngine) {
        return [self.rtmpEngine dropdownFrameRate];
    }
    return 1.f;
    
}

- (void)startGPUSession
{
    PALiveVideoConfiguration *videoConfiguration = [PALiveVideoConfiguration defaultConfiguration];
    videoConfiguration.videoFrameRate = self.fps;
    videoConfiguration.videoBitRate = self.bitRate;
    videoConfiguration.orientation = UIInterfaceOrientationPortrait;
    //videoConfiguration.sessionPreset = (self.definition== IA_540P? ECaptureSessionPreset540x960 : ECaptureSessionPreset720x1280);
    
    _liveSession = [[LiveSession alloc] initWithVideoConfiguration:videoConfiguration];
    _liveSession.preView = self.displayWindow;
    __weak typeof(self) weakSelf = self;
    
    _liveSession.videoOutputEvent = ^(CVImageBufferRef *pixelBuffer,id owner){
        
        if (weakSelf.isPushing&&weakSelf.rtmpEngine&&weakSelf.rtmpEngine.h264Encoder&&weakSelf.rtmpEngine.isPushing) {
            weakSelf.rtmpEngine.beforeVideoEncodeTimeInterval = [[NSDate date] timeIntervalSince1970];
            [weakSelf.rtmpEngine.h264Encoder encodeWithImageBuffer:pixelBuffer];
            weakSelf.rtmpEngine.afterVideoEncodedTimeInterval = [[NSDate date] timeIntervalSince1970];
        }
    };
    
    [_liveSession startLiveSession];
}

- (void)stopGPUSession {
    
    if (_liveSession) {
        [_liveSession stopLiveSession];
    }
}

#pragma mark - push
- (void)startRtmp
{
    if (self.rtmpEngine) {
        [self.rtmpEngine stopRtmp];
        self.rtmpEngine = nil;
    }
    self.rtmpEngine = [[IAMediaRtmpEngine alloc] initWithDelegate:self bitRate:self.bitRate definition:self.definition];
    if (self.currentVolume<5) {
        [self.rtmpEngine setVolumeEngine:self.currentVolume];
    }
    [self setAVCallback:self.rtmpEngine];
    if (self.videoCaptureEngine && self.audioCaptureEngine) {
        [self.rtmpEngine getInfoWith:self.videoCaptureEngine.outputDevice audioDataOuput:self.audioCaptureEngine.outputDevice];
    }
}

- (void)startPreviewCamera
{
    if (self.videoCaptureEngine) {
        [self.videoCaptureEngine stopVideoCapture];
        self.videoCaptureEngine = nil;
    }
    self.videoCaptureEngine = [[IAVideoCaptureEngine alloc] initWithSuperView:self.displayWindow outputSampleBufferDelegateObserver:self.rtmpEngine authorizationHandler:^(BOOL authoried) {
        if (!authoried) {
            LogError(@"[PushSDK]没开启相机");
        }
    }];
    
#ifndef __USE_GPUIMAGE__
    [self startRtmp];
#endif //__USE_GPUIMAGE__
    
    [self.videoCaptureEngine startVideoPreview];
    [self.videoCaptureEngine switchCaptureDevicePosition]; //切换成前置摄像头
    
    if (self.rtmpEngine) {
        [self.rtmpEngine getInfoWith:self.videoCaptureEngine.outputDevice audioDataOuput:self.audioCaptureEngine.outputDevice];
    }
}

- (void)startPushStreaming
{
    if (self.liveSession) {
        [self.liveSession setAppOnScreen:YES];
    }
    [self startMic];
    __weak typeof(self) weakSelf = self;
    [self.rtmpEngine startRtmpSend:self.pushUrl connectHandler:^(BOOL isScuccess, NSInteger errorCode) {
        if (isScuccess) {
            weakSelf.isPushing = YES;
            [weakSelf performSelectorOnMainThread:@selector(startDiscardFrameCalcuTimer) withObject:nil waitUntilDone:NO];
        }
        if (weakSelf.sdkCallbackHandler && !weakSelf.reStartStream) { //rtmp连接成功, 只需回调一次
            weakSelf.sdkCallbackHandler(errorCode,PA_START,0);
        }
        //[weakSelf performSelectorOnMainThread:@selector(changeTopLabelVale:) withObject:[NSNumber numberWithBool:isScuccess] waitUntilDone:NO];
    }];
}



-(void)startDiscardFrameCalcuTimer{
    
    self.discardcount = 0;
    
    if (self.discardFrameRateTimer) {
        [self.discardFrameRateTimer invalidate];
        self.discardFrameRateTimer = nil;
    }
    self.discardFrameRateTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(doCalcuDiscardFramesRate:) userInfo:nil repeats:YES];
}

-(void)doCalcuDiscardFramesRate:(id)sender{
    
    if (self.discardcount <= 5 || (self.discardcount > 5 && (self.discardcount % 3 == 0))){
    if (self.rtmpEngine) {
        [self.rtmpEngine calculateDropFrameRte:(self.discardcount <= 5 ? 1 : 3)];
    }
    }
    self.discardcount ++;
}

- (void)restartPushStreaming
{
    _reStartStream = YES;
    if (self.isPushing) {
        [self stopPushStreaming];
    }
    [self startRtmp];
    [self startPushStreaming];
}

-(void)setAVCallback:(id)callback{
    LogDebug(@"setAVCallback  11:%@ isPushing:%d",_liveSession,self.rtmpEngine.isPushing);

#ifndef __USE_GPUIMAGE__
    if(self.videoCaptureEngine){
        self.videoCaptureEngine.outputSampleBufferDelegateObserver = callback;
        self.videoCaptureEngine.delegate = callback;
    }
#endif // __USE_GPUIMAGE__
    
    if (self.paAudioEngine) {
        if (callback==nil) {
            [self.paAudioEngine stop];
            if (self.paAudioEngine.delegate) {
                self.paAudioEngine.delegate = nil;
                
            }
        }else{
            [self.paAudioEngine start];
            self.paAudioEngine.delegate = callback; //make sure the audio callback when the rtmpEngine reinitial
        }
        
    }
    
    if (self.audioCaptureEngine) {
        self.audioCaptureEngine.outputSampleBufferDelegate = callback;
        if (callback==nil) {
            [self.audioCaptureEngine close];
        }else{
            [self.audioCaptureEngine open];
        }
        
        NSLog(@"setAVCallback :%@ callback:%@",self.audioCaptureEngine,callback);
    }
}

- (void)stopPushStreaming
{
    if (self.liveSession) {
        [self.liveSession setAppOnScreen:NO];
    }
    self.isPushing = NO;
    [self setAVCallback:nil];
    
    if (self.paAudioEngine) {
        [self.paAudioEngine stop];
        self.paAudioEngine = nil;
    }
    
    if (self.rtmpEngine) {
        [self.rtmpEngine stopRtmp];
        self.rtmpEngine = nil;
    }
}


- (void)startMic  //for hotswitch, should invoke in startpush
{
#ifdef PA_SUPPORT_BLUETOOTH_AUDIOCAPTURE
    
    if (self.paAudioEngine) {
        [self.paAudioEngine stop];
        self.paAudioEngine = nil;
    }
    self.paAudioEngine = [[PAAudioCaptureEngine alloc] init];
    if (self.currentVolume<5) {
        [self.paAudioEngine setVolumeEngine:self.currentVolume];
    }
    
    self.paAudioEngine.delegate = self.rtmpEngine;
    [self.paAudioEngine start];
    
#else
    
    if (self.audioCaptureEngine) {
        [self.audioCaptureEngine close];
        self.audioCaptureEngine = nil;
    }
    self.audioCaptureEngine = [[IAAudioCaptureEngine alloc] initWithAudioDataOutputSampleBufferDelegate:self.rtmpEngine authorizationHandler:^(BOOL authoried) {
        if (!authoried) {
            //[weakSelf doBackButtonPressed:nil];
            LogError(@"[PushSDK]没开启麦克风");
        }
    }];
    self.audioCaptureEngine.delegate = self;
    [self.audioCaptureEngine open];
    
#endif

}

- (void)setActive:(BOOL)active
{
    if (active) {
        [self restartPushStreaming];
    } else {
        [self stopPushStreaming];
    }
}

#pragma mark - IAMediaRtmpEngineDelegate

-(void)needRestartStreaming:(IAMediaRtmpEngine*)rtmpEngine errorCode:(NSInteger)errorCode
{
#if 0
    LogInfo(@"[PushSDK] NeedRestartStreaming 重新推流 %d",self.reStartPushTimes);
    self.reStartPushTimes ++;
    if (self.sdkCallbackHandler && 3 < self.reStartPushTimes) {
        self.sdkCallbackHandler(errorCode,PA_PUSH_STREAM,0);
        [self stopStreaming];
        self.reStartPushTimes = 0;
        return;
    }
    //should have max restreaming;
    //    NSString* title = [NSString stringWithFormat:@"%@失败",self.recordOrStreamingContext];
    //    [self.view showInfo:title autoHidden:NO];
    usleep(500000);
    [self restartPushStreaming];
#else
    [self stopStreaming];
    if (self.sdkCallbackHandler) {
        self.sdkCallbackHandler(errorCode,PA_PUSH_STREAM,0);
    }
    return;
#endif
}

-(void)pushFailure:(IAMediaRtmpEngine*)rtmpEngine errorCode:(NSInteger)errorCode
{
    
    //tip
    //    [self appActive:nil];
    if (errorCode<0) {
         [self stopPushStreaming];
        if (self.sdkCallbackHandler) {
            self.sdkCallbackHandler(errorCode,PA_STOP,0);
        }
    }else{
        self.reStartPushTimes = 0;
        if (self.sdkCallbackHandler) {
            self.sdkCallbackHandler(errorCode,PA_PUSH_STREAM,0);
        }
    }


}

#pragma mark - IAAudioCaptureEngineDelegate
- (void)gotAudioEncodedData:(NSData *)aData len:(long long)len timeDuration:(long long)duration
{
    LogDebug(@"audio data: %@, len: %@, duration: %@", aData, @(len), @(duration));
}

- (void)dealloc
{
    LogInfo(@"[PushSDK] PAPushSDK dealloc");
}

#pragma observer

- (void)registerNoitficationObserver{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadVideoHardwareError:) name:PA_VIDEOHARDWARE_LOADERROR object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadAudioHardwareError:) name:PA_AUDIOHARDWARE_LOADERROR object:nil];
}
-(void)unRegisterNoitficationObserver{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)loadVideoHardwareError:(NSNotification*)notification{

    if (self.sdkCallbackHandler) {
        self.sdkCallbackHandler(VIDEODEVICE_LOAD_FAIL, PA_PUSH_EXCEPTION, 0);
    }
}

-(void)loadAudioHardwareError:(NSNotification*)notification{
    
    if (self.sdkCallbackHandler) {
        self.sdkCallbackHandler(AUDIODEVICE_LOAD_FAIL, PA_PUSH_EXCEPTION, 0);
    }
    
}

@end
