//
//  IAMediaRtmpEngine.m
//  MediaRecorder
//
//  Created by Derek Lix on 16/3/9.
//  Copyright © 2016年 Derek Lix. All rights reserved.
//



#import "IAMediaRtmpEngine.h"
#import "IAMediaDataModel.h"
#import "Reachability.h"
//#import "IAStreamingLogModel.h"
#import "IAUtility.h"
//#import "IAAliyunEngine.h"
#import "IAHuitiRtmp.h"
#import "PAThreadEngine.h"

#import "FileMuxer.h"

typedef NS_ENUM(NSInteger, IARtmpOperationState)
{
    IARtmpOperationState_Paused = -1,
    IARtmpOperationState_Ready = 1,
    IARtmpOperationState_Executing = 2,
    IARtmpOperationState_Finished = 3,
};

#pragma mark - IARtmpHelperOperation

typedef void(^IARtmpOperationHandler)(BOOL doesBeginSend,long long sendDataLen ,int rtmpSendResult,long long timeStamp);


@interface IARtmpHelperOperation: NSOperation

- (BOOL)isPaused;
- (void)resume;

@property (nonatomic, strong) IAMediaDataModel* mediaModel;
@property (nonatomic, assign) IARtmpOperationState state;
@property (nonatomic, strong) NSSet *runLoopModes;
@property (nonatomic, assign) BOOL  doesFinished;
@property (nonatomic, strong) IARtmpOperationHandler  operationHandler;


@end

@implementation IARtmpHelperOperation

-(id)initWithOperationHandler:(IARtmpOperationHandler)operationHandler{
    if (self = [super init]) {
        self.operationHandler = operationHandler;
    }
    return self;
}


+ (void)rtmpSendThreadEntryPoint
{
    
    @autoreleasepool
    {
        [[NSThread currentThread] setName: @"IARtmp"];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort: [NSMachPort port] forMode: NSDefaultRunLoopMode];
        [runLoop run];
    }
}


+ (NSThread *)rtmpSendThread
{
    static NSThread *_rtmpSendThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _rtmpSendThread = [[NSThread alloc] initWithTarget: self
                                                  selector: @selector(rtmpSendThreadEntryPoint)
                                                    object: nil];
        [_rtmpSendThread start];
    });
    
    return _rtmpSendThread;
}


- (BOOL)isPaused
{
    return self.state == IARtmpOperationState_Paused;
}

-(void)main{
    if (self.isCancelled)
    {
        [self performSelector: @selector(cancelConnection)
                     onThread: [[self class] rtmpSendThread]
                   withObject: nil
                waitUntilDone: NO];
    }
    else
    {
        [self performSelector: @selector(operationDidStart)
                     onThread: [[self class] rtmpSendThread]
                   withObject: nil
                waitUntilDone: NO];
    }
}


- (void)resume
{
    if (![self isPaused])
    {
        return;
    }
    
    
    self.state = IARtmpOperationState_Ready;
    
    [self start];
    
}

- (void)pause
{
    if ([self isPaused] || [self isFinished] || [self isCancelled])
    {
        return;
    }
    
    
    if ([self isExecuting])
    {
        [self performSelector: @selector(operationDidPause)
                     onThread: [[self class] rtmpSendThread]
                   withObject: nil
                waitUntilDone: NO
                        modes: [self.runLoopModes allObjects]];
    }
    
    self.state = IARtmpOperationState_Paused;
    
}

- (void)operationDidPause
{
    
}

- (void)operationDidStart
{
    //    if (![self isCancelled])
    //    {
    //        @autoreleasepool {
    //            //do something
    //            if (self.operationHandler) {
    //                self.operationHandler(YES,0,0,0);
    //            }
    //            int result ;
    //#ifdef IA_SendAudioThread_Key
    //            if (self.mediaModel.isVideo) {
    //                NSTimeInterval startTime = [[NSDate date] timeIntervalSinceReferenceDate];
    //                result =rtmpSend((uint8_t *)[self.mediaModel.data bytes], (int)self.mediaModel.data.length, 1, self.mediaModel.timestamp);
    //                NSTimeInterval endTime = [[NSDate date] timeIntervalSinceReferenceDate];
    //                NSLog(@"IALog_video_wasteTime: %f",endTime-startTime);
    //            }else{
    //                NSTimeInterval startTime = [[NSDate date] timeIntervalSinceReferenceDate];
    //                result =rtmpSend((uint8_t *)[self.mediaModel.data bytes], (int)self.mediaModel.data.length, 0, self.mediaModel.timestamp);
    //                NSTimeInterval endTime = [[NSDate date] timeIntervalSinceReferenceDate];
    //                NSLog(@"IALog_audio_wasteTime: %f",endTime-startTime);
    //            }
    //#else
    //            result =rtmpSend((uint8_t *)[self.mediaModel.data bytes], (int)self.mediaModel.data.length, 1, self.mediaModel.timestamp);
    //#endif
    //
    //            if (self.operationHandler) {
    //                self.operationHandler(NO,self.mediaModel.data.length,result,self.mediaModel.timestamp);
    //            }
    //        }
    //
    //    }
    
}

- (void)cancelConnection
{
    if (![self isFinished])
    {
        
    }
}

- (void)cancel
{
    
    if (![self isFinished] && ![self isCancelled])
    {
        [super cancel];
        
        if ([self isExecuting])
        {
            [self performSelector:@selector(cancelConnection) onThread:[[self class] rtmpSendThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
        }
    }
    
}


@end


#import "IAMediaDataModel.h"
#import "Reachability.h"
//#import "UIView+ToastInfo.h"
//#import "IALogList.h"
//#import "IAAVWriteEngine.h"

#define IA_DefaultRtmpUrl    @"rtmp://wsvideopull.smartcourt.cn/prod/dai123"
//   rtmpUrl = @"rtmp://wsvideopull.smartcourt.cn/prod/dai123";

#define IA_VideoEncodedDataArray_Max  25
#define IA_AudioEncodedDataArray_Max  50

#define IA_CheckCurrentAudioTime_Interval   5000   //unit is second
//#define IA_AudioIncrease_Interval     22
#define IA_RestartStreamingCount_Max   3
#define IA_RtmpVideoSend_OverTime           300
#define IA_RtmpAudioSend_OverTime           100

static NSInteger IA_AudioIncrease_Interval = 22;


static NSString *const IAThreadName_rtmp = @"com.huiti.MediaRecorder.thread.rtmp";
static NSString *const IALockNameVideo_rtmp = @"com.huiti.MediaRecorder.videolock.rtmp";
static NSString *const IALockNameAudio_rtmp = @"com.huiti.MediaRecorder.audiolock.rtmp";

typedef NS_ENUM( NSInteger, RecordingStatus )
{
    RecordingStatusIdle = 0,
    RecordingStatusStartingRecording,
    RecordingStatusRecording,
    RecordingStatusStoppingRecording,
}; // internal state machine


@interface IAMediaRtmpEngine()<IAAudioCaptureEngineDelegate,H264HwEncoderImplDelegate>
{
    AudioConverterRef m_converter;
}

@property(nonatomic, strong)NSMutableArray*   audioEncodedArray;
@property(nonatomic, strong)NSMutableArray*   videoEncodedArray;
//@property(assign, nonatomic)NSTimeInterval    startVideoTimeInterval;
//@property(nonatomic,strong)H264HwEncoderImpl* h264Encoder;
@property(assign, nonatomic)BOOL    hasPPSSended;
@property (nonatomic, strong) NSRecursiveLock* videolock;
@property (nonatomic, strong) NSRecursiveLock* audiolock;
@property (nonatomic, strong) Reachability *reachability;
@property(nonatomic,assign)BOOL   isPushing;
@property(nonatomic,strong)NSCondition* condition;

@property(nonatomic,assign)long long       sendDataLen;
@property(nonatomic,assign)NSTimeInterval  startPushInterval;

@property(nonatomic,assign)long long       calcuateRate_SendDataLen;
@property(nonatomic,assign)NSTimeInterval  calcuateRate_StartPushInterval;

@property(nonatomic,assign)NSInteger       reconnectTimes;
@property(nonatomic,assign)PADefinition    definition;
@property(nonatomic,strong)NSTimer*        disappearGameEventTimer;

@property(nonatomic,strong)NSString*       pushUrl;
@property(nonatomic,assign)PABitRate       bitRate;
@property(nonatomic,assign)BOOL            hasFetchedPrePushData;
@property(nonatomic,assign)long long       prePushData;
@property(nonatomic,assign)long long       prePushTime;
@property (nonatomic, strong)NSSet*        runLoopModes;

@property (nonatomic, readwrite, strong) NSRecursiveLock* mediaModelLock;
@property (nonatomic, strong) NSOperationQueue*           mediaVideoRtmpOperationQueue;
@property (nonatomic, strong) NSOperationQueue*           mediaAudioRtmpOperationQueue;
@property (nonatomic, assign) long                    lastVideoFrameInterval;
@property (nonatomic, assign) long                    lastAudioFrameInterval;
@property (nonatomic, assign) double                    baseAudioTime;
@property (nonatomic, assign) double                    audioTimeStamp;
@property (nonatomic, strong) IAConnectRtmpHandler      rtmpConnectHandler;
@property (nonatomic, strong) NSMutableArray*           videoTimeStampArray;
@property (nonatomic, strong) NSMutableArray*           audioTimeStampArray;
@property (nonatomic, assign) long long                 preSendVideoTimeStamp;
@property (nonatomic, assign) long long                 preSendAudioTimeStamp;
@property (nonatomic, strong) NSRecursiveLock*          videoMediaStampModelLock;
@property (nonatomic, strong) NSRecursiveLock*          audioMediaStampModelLock;
@property (nonatomic, strong)IAMediaDataModel*          preSendedAudioDataModel;
@property (nonatomic, assign) BOOL                      continueGiveUpVideo;
@property (nonatomic, assign) BOOL                      isMediaArrayLocked;
@property (nonatomic, assign) long                      composeAudioSize;
@property (nonatomic, assign) BOOL                      shouldExitThread;
@property (nonatomic, assign) NSTimeInterval            preSendTime;
@property (nonatomic, assign) NSTimeInterval            preSendData;


//@property(nonatomic,  strong) IAAVWriteEngine*  avWriterEngine;
//@property (nonatomic, assign) RecordingStatus   recordingStatus;
//@property (nonatomic, strong) NSURL*            recordingURL;
@property(nonatomic,  strong) __attribute__((NSObject)) CMFormatDescriptionRef outputVideoFormatDescription;
@property(nonatomic,  strong) __attribute__((NSObject)) CMFormatDescriptionRef outputAudioFormatDescription;
@property (nonatomic, strong) NSDictionary *videoCompressionSettings;
@property (nonatomic, strong) NSDictionary *audioCompressionSettings;
@property (nonatomic, strong) IAMediaDataModel*  willSendVideoModel;
@property (nonatomic, strong) IAMediaDataModel*  willSendAudioModel;
@property (nonatomic, strong) IARtmpSender*      rtmpSender;
@property (nonatomic, strong) FileMuxer*      fileMuxer;
@property (nonatomic, strong) FileMuxer*      wnderfullClipMuxer;
@property (nonatomic, assign) BOOL     isWonderfullClipping;
@property (nonatomic, assign) unsigned long long preAPIFlow;

@property (nonatomic, assign) BOOL needMuted;
@property (nonatomic, assign) BOOL preSendSuccess;
@property (nonatomic, strong) PAThreadEngine*  paThreadEngine;

//caculate discard frame rate
@property(nonatomic,assign)unsigned long long         allSendedFrames;
@property(nonatomic,assign)NSTimeInterval             startSendFrameTimeInterval;
@property(nonatomic,assign)CGFloat                     discardFrameRate;

@property (nonatomic, assign) int muxedFrameCount;
#define AV_CODEC_ID_H264 28
#define AV_CODEC_ID_AAC 86018
#define WRITE_FRAME_COUNT 500
@end


@implementation IAMediaRtmpEngine

-(id)initWithDelegate:(id<IAMediaRtmpEngineDelegate>)delegate bitRate:(PABitRate)bitRate definition:(PADefinition)defintion
{
    if (self = [super init]) {
        self.isWonderfullClipping = NO;
        self.rtmpSender = [[IARtmpSender alloc] init];
        self.hasFetchedPrePushData = NO;
        self.prePushData = 0.0f;
        self.preAPIFlow = 0.0f;
        self.bitRate = bitRate;
        self.definition = defintion;
        self.isPushing = NO;
        self.discardFrameRate = 1.f;
        self.reconnectTimes = 0;
        self.delegate = delegate;
        _videolock = [[NSRecursiveLock alloc] init];
        _audiolock = [[NSRecursiveLock alloc] init];
        _condition = [[NSCondition alloc] init];
        _runLoopModes = [NSSet setWithObject: NSRunLoopCommonModes];
        _videoMediaStampModelLock = [[NSRecursiveLock alloc] init];
        _audioMediaStampModelLock = [[NSRecursiveLock alloc] init];
        self.videolock.name = IALockNameVideo_rtmp;
        self.audiolock.name = IALockNameAudio_rtmp;
        self.needMuted = NO;
        [self initLogTimeInterval];
        
        [self clostFileMuxer];
        if(0 > [self openFileMuxer:[[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"output.mp4"] UTF8String]])
            [self clostFileMuxer];
    }
    return self;
}

-(void)initLogTimeInterval{
    
    self.beforeVideoEncodeTimeInterval = 0;
    self.afterVideoEncodedTimeInterval = 0;
    self.beforeVideoSendTimeInterval = 0;
    self.afterVideoSendedTimeInterval = 0;
    
    self.beforeAudioEncodeTimeInterval = 0;
    self.afterAudioEncodedTimeInterval = 0;
    self.beforeAudioSendTimeInterval = 0;
    self.afterAudioSendedTimeInterval = 0;
}


-(void)addOneMediaModel:(IAMediaDataModel*)mediaModel{
    
    @autoreleasepool {
        __weak typeof(self) weakSelf = self;
        IARtmpHelperOperation *operation = [[IARtmpHelperOperation alloc] initWithOperationHandler:^(BOOL doesBeginSend, long long sendDataLen, int rtmpSendResult,long long timeStamp) {
            if (doesBeginSend) {
                if (weakSelf.startPushInterval==0) {
                    weakSelf.startPushInterval = [[NSDate date] timeIntervalSinceReferenceDate];
                    weakSelf.sendDataLen = 0;
                }
                if (weakSelf.calcuateRate_StartPushInterval==0) {
                    weakSelf.calcuateRate_StartPushInterval = [[NSDate date] timeIntervalSinceReferenceDate];
                    weakSelf.calcuateRate_SendDataLen = 0;
                }
            }else{
                weakSelf.sendDataLen+=mediaModel.data.length;
                weakSelf.calcuateRate_SendDataLen+=mediaModel.data.length;
                if ((rtmpSendResult==-1)||(rtmpSendResult==-5)||(rtmpSendResult==-7)) {
                    NSLog(@"........ result  :%d",rtmpSendResult);
                    NSString* sendErrorlog = [NSString stringWithFormat:@"sendErrorlog :%d",rtmpSendResult];
                    [IAUtility IALog:sendErrorlog];
                    NSInteger reStreamingCount = 0;//[IALogList reStreamingCount];
                    if (reStreamingCount<IA_RestartStreamingCount_Max) {
                        [self performSelectorOnMainThread:@selector(doRestartstreaming:) withObject:[NSNumber numberWithInteger:rtmpSendResult] waitUntilDone:NO];
                    }
                    
                }else{
                    //                    [IALogList setReStreamingCount:0];
                }
            }
        }];
        [operation setMediaModel:mediaModel];
        if (mediaModel.isVideo) {
            [self.mediaVideoRtmpOperationQueue addOperation: operation];
        }else{
            [self.mediaAudioRtmpOperationQueue addOperation: operation];
        }
        
    }
    
}


static long long  gNetworkSpeedIndex = 0;

-(unsigned long long)wastedFlowFormAPI{
    
    unsigned long long gPRSFlow_END = [IAUtility getGprsFlowBytes];
    unsigned long long wifiFlow_END = [IAUtility getWifiBytes];
    unsigned long long gPRSFlow_start = [IAUtility gPRSInitialData];
    unsigned long long wifiFlow_start = [IAUtility wifigPRSInitialData];
    unsigned long long gprsWastedFlow = gPRSFlow_END - gPRSFlow_start;
    unsigned long long wifiWastedFlow = wifiFlow_END - wifiFlow_start;
    unsigned long long totalWastedFlow = gprsWastedFlow+wifiWastedFlow;
    
    //reset
    unsigned long long gPRSFlow = [IAUtility getGprsFlowBytes];
    unsigned long long wifiFlow = [IAUtility getWifiBytes];
    
    [IAUtility setGPRSInitialData:gPRSFlow];
    [IAUtility setWifiInitialData:wifiFlow];
    
    return totalWastedFlow;
}

-(CGFloat)upLoadNetworkSpeed{
    
    if (!self.isPushing) {
        return 0.0f;
    }
    
    if (self.startPushInterval!=0) {
        NSTimeInterval currentTimeInterval = [[NSDate date] timeIntervalSinceReferenceDate];
        NSTimeInterval offsetTime = currentTimeInterval- self.calcuateRate_StartPushInterval;
        long long      offsetData = self.calcuateRate_SendDataLen;
        CGFloat speed = offsetData/offsetTime;
        speed=speed/1000;
        if (gNetworkSpeedIndex%5==0) {
            self.calcuateRate_SendDataLen = 0;
            self.calcuateRate_StartPushInterval = 0;
        }
        gNetworkSpeedIndex++;
        return speed;
    }
    return 0.0f;
}

-(long long)totalPushData{
    
    return self.sendDataLen;
}

-(NSTimeInterval)startPushTime{
    
    return self.startPushInterval;
}

-(void)caculateSpeed{
}


-(int)setRtmpUrl:(NSString*)url{
   // url = @"rtmp://livepush-cc.dev.pajk.cn/live/eoollo";
    //url = @"rtmp://livepush.test.pajk.cn/live/iOS_testrtmp";//@"rtmp://wsvideopush.smartcourt.cn/prod/ff231e4f7a86177c/20150914000000188";
    self.pushUrl = url;
    if (!url || ([url length]<=0)) {
        url = IA_DefaultRtmpUrl;
    }
    const char*  _url = [url UTF8String];
    
    assert(self.rtmpSender);
    [self.rtmpSender rtmpDisconnect];
    
    NSLog(@"pushurl :%@",url);
    
    NSTimeInterval beginConnect = [[NSDate date] timeIntervalSince1970];
    int result =[self.rtmpSender rtmpConnect:_url];
    NSTimeInterval endConnect = [[NSDate date] timeIntervalSince1970];
    float offset = endConnect-beginConnect;
    offset = offset*1000;
    NSLog(@"rtmp offset ;%f",offset);
    //    IAStreamingLogModel* logModel = [[IAStreamingLogModel alloc] init];
    //    logModel.usedTime = [NSNumber numberWithInt:offset];
    //    if (result==0) {
    //        logModel.connectResult = [NSNumber numberWithBool:YES];
    //    }else
    //    {
    //        logModel.connectResult = [NSNumber numberWithBool:NO];
    //    }
    //    NSDictionary* dic = [logModel streamingLogModelWithLogLevel:@"1" type:@"capt" subType:[NSNumber numberWithInt:308] resolution:nil streamSpeed:nil rate:nil traceId:self.gameId reason:nil];
    //    [IALogList addLogModel:dic];
    
    
    if (self.definition==IA_720P) {
        [self.rtmpSender rtmpSetVideoInfo:1280 height:720 fps:25];
    }else if (self.definition==IA_540P){
        [self.rtmpSender rtmpSetVideoInfo:960 height:540 fps:25];
        //  [self.rtmpSender rtmpSetVideoInfo:540 height:960 fps:25]; // Eoollo
    }else{
    }
    [self.rtmpSender rtmpSetAudioInfo:1 smapleRate:44100 sampleBit:16];
    
    return result;
}

-(void)startRtmpSend:(NSString*)url connectHandler:(IAConnectRtmpHandler)handler{
    [IAUtility IALog:@"startRtmpSend"];
    
    self.hasFetchedPrePushData = NO;
    self.preSendAudioTimeStamp = 0;
    self.preSendVideoTimeStamp = 0;
    self.isPushing = NO;
    self.continueGiveUpVideo = NO;
    self.sendDataLen = 0;
    self.rtmpConnectHandler = handler;
    self.isMediaArrayLocked = NO;
    self.composeAudioSize = 0;
    
    self.preSendSuccess = NO;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0) , ^{
        
        weakSelf.lastAudioFrameInterval = 0;
        weakSelf.lastVideoFrameInterval = 0;
        
        int result = [self setRtmpUrl:url];
        
        if (result==0) {
            
            //mark the startpushing data
            
            unsigned long long gPRSFlow = [IAUtility getGprsFlowBytes];
            unsigned long long wifiFlow = [IAUtility getWifiBytes];
            
            [IAUtility setGPRSInitialData:gPRSFlow];
            [IAUtility setWifiInitialData:wifiFlow];
            
            NSString* gprsFlowStr = [IAUtility bytesToAvaiUnit:gPRSFlow];
            NSString* wifiFlowStr = [IAUtility bytesToAvaiUnit:wifiFlow];
            NSString* networkflow = [NSString stringWithFormat:@"gprs:%@ wifi:%@",gprsFlowStr,wifiFlowStr];
            NSLog(@"rtmpConnect success:%@",networkflow);
            
            ////clear before data
            [weakSelf.videoEncodedArray removeAllObjects];
            [weakSelf.audioEncodedArray removeAllObjects];
            [weakSelf.videoTimeStampArray removeAllObjects];
            [weakSelf.audioTimeStampArray removeAllObjects];
            ////end
            [IAUtility setStartTimestampInterval:0];
            weakSelf.isPushing = YES;
            weakSelf.hasPPSSended = NO;
            weakSelf.allSendedFrames = 0;
            weakSelf.startPushInterval = 0;
            weakSelf.prePushData = 0.f;
            weakSelf.prePushTime = 0.f;
            weakSelf.preAPIFlow = 0.f;
            //            double lastPushTime = [IALogList totalPushTimeWithGameId:self.gameId];
            //            if (lastPushTime>0) {
            //                weakSelf.startPushInterval = [[NSDate date] timeIntervalSinceReferenceDate];
            //            }
            
            //            long long lastPushData = [IALogList pushNetworkFlowWithGameId:self.gameId];
            weakSelf.sendDataLen = 0;
            
            weakSelf.calcuateRate_SendDataLen = 0;
            weakSelf.calcuateRate_StartPushInterval = 0;
            weakSelf.mediaVideoRtmpOperationQueue = [[NSOperationQueue alloc] init];
            weakSelf.mediaVideoRtmpOperationQueue.maxConcurrentOperationCount = 1;
            
            
            weakSelf.mediaAudioRtmpOperationQueue = [[NSOperationQueue alloc] init];
            weakSelf.mediaAudioRtmpOperationQueue.maxConcurrentOperationCount = 1;
            [weakSelf createH264Encoder:self.bitRate finishedHanlder:^{
                NSLog(@"createH264Encoder success");
                
            }];
            [weakSelf startThread:YES];
            NSLog(@"callback to top");
            weakSelf.rtmpConnectHandler(YES,0);
            
        }else{
            weakSelf.rtmpConnectHandler(NO,-1);
        }
        
        
    });
    
}

//-(void)startRecord{
//    assert(self.gameId);
//    self.isPushing = YES;
//    [IAUtility setStillCaptureImageData:nil];
//
//    [self createH264Encoder:self.bitRate];
//    [self startThread:NO];
//
//    @synchronized(self)
//    {
//        if(_recordingStatus != RecordingStatusIdle) {
//            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Already recording" userInfo:nil];
//            return;
//        }
//        [self transitionToRecordingStatus:RecordingStatusStartingRecording error:nil];
//    }
//
//
//    NSString* filename = @"myfile.txt";
//
//    NSString *applicationDocumentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
//
//    NSString *storePath = [applicationDocumentsDir stringByAppendingPathComponent:filename];
//    NSLog(@"storePath :%@",storePath);
////    self.recordingURL = [IAAliyunEngine constructVideoFileUrlWithGameId:self.gameId];
//    NSLog(@"self.recordingURL :%@",[self.recordingURL absoluteString]);
//    self.avWriterEngine = [[IAAVWriteEngine alloc] initWithURL:_recordingURL];
//    if(_outputAudioFormatDescription != nil){
//        [self.avWriterEngine addAudioTrackWithSourceFormatDescription:self.outputAudioFormatDescription settings:_audioCompressionSettings];
//    }
//
//    [self.avWriterEngine addVideoTrackWithSourceFormatDescription:self.outputVideoFormatDescription settings:_videoCompressionSettings];
//    dispatch_queue_t callbackQueue = dispatch_queue_create( "com.example.capturesession.writercallback", DISPATCH_QUEUE_SERIAL ); // guarantee ordering of callbacks with a serial queue
//    [self.avWriterEngine setDelegate:self callbackQueue:callbackQueue];
//    [self.avWriterEngine prepareToRecord]; // asynchronous, will call us back with recorderDidFinishPreparing: or recorder:didFailWithError: when done
//
//
//}

//-(NSURL*)currentRecordVideoLocalUrl{
//
//    if (self.isPushing) {
//        return self.recordingURL;
//    }
//    return nil;
//}

-(void)getInfoWith:(AVCaptureVideoDataOutput*)videoDataOutput audioDataOuput:(AVCaptureAudioDataOutput*)audioDataOuput
{
    _videoCompressionSettings = [videoDataOutput recommendedVideoSettingsForAssetWriterWithOutputFileType:AVFileTypeQuickTimeMovie];
    _audioCompressionSettings = [audioDataOuput recommendedAudioSettingsForAssetWriterWithOutputFileType:AVFileTypeQuickTimeMovie];
}

- (void)setCompressionSettings
{
    
}

-(void)stopRtmp{
    NSLog(@"stoprtmppppp11");
    
    [self releaseResource];
    
    self.shouldExitThread = YES;
    [self.videoEncodedArray removeAllObjects];
    [self.audioEncodedArray removeAllObjects];
    
    
    [IAUtility setStartTimestampInterval:0];
    
    [self.videoTimeStampArray removeAllObjects];
    [self.audioTimeStampArray removeAllObjects];
    
    if (self.disappearGameEventTimer) {
        [self.disappearGameEventTimer invalidate];
        self.disappearGameEventTimer = nil;
    }
    
    if (self.mediaVideoRtmpOperationQueue) {
        [self.mediaVideoRtmpOperationQueue cancelAllOperations];
        self.mediaVideoRtmpOperationQueue = nil;
    }
    
    if (self.mediaAudioRtmpOperationQueue) {
        [self.mediaAudioRtmpOperationQueue cancelAllOperations];
        self.mediaAudioRtmpOperationQueue = nil;
    }
    
    
    [NSObject  cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendStreamingData) object:nil];
    
    [self.rtmpSender rtmpDisconnect];
    
    [self clostFileMuxer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

-(void)releaseResource{
    
    self.isPushing = NO;
    if (self.h264Encoder) {
        [self.h264Encoder End];
        self.h264Encoder = nil;
    }
    
    if (self.paThreadEngine) {
        [self.paThreadEngine stopThread];
        self.paThreadEngine = nil;
    }
    NSLog(@"releaseResource end");
}

- (void)createH264Encoder:(PABitRate)bitRate finishedHanlder:(IAInitialFinishedHandler)finishedHanlder {
    
    self.h264Encoder = [[H264HwEncoderImpl alloc] initWithFirstFrameEncodedHandler:^{
        if (finishedHanlder) {
            finishedHanlder();
        }
    } compoundFinishedHandler:^{
    }];
    self.h264Encoder.bitRate = bitRate;  //need configuration
    [self.h264Encoder initWithConfiguration];
    
    [self.h264Encoder initEncode:540 height:960];
    
    self.h264Encoder.delegate = self;
    
}
-(void)startThread:(BOOL)isStreaming{
    
    if (self.paThreadEngine) {
        [self.paThreadEngine stopThread];
        self.paThreadEngine = nil;
    }
    self.paThreadEngine = [[PAThreadEngine alloc] init];
    [self.paThreadEngine startThread];
    self.shouldExitThread = NO;

    
    if (!isStreaming) {
        return;
    }
    
#ifdef IA_CoustomRtmpThread_Key
    
    [NSObject  cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendStreamingData) object:nil];
    [self performSelector:@selector(sendStreamingData) onThread:[self.paThreadEngine paThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
#else
#endif
    
}

-(BOOL)doesThreadExecuting
{
    if ([self.paThreadEngine paThread]) {
        if ([self.paThreadEngine paThread].isCancelled) {
            return NO;
        }
        if ([self.paThreadEngine paThread].isFinished) {
            return NO;
        }
        if ([self.paThreadEngine paThread].isExecuting) {
            return YES;
        }
    }
    return NO;
}

-(void)threadMain:(id)sender{
    
    [[NSThread currentThread] setName: @"panelThread"];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addPort: [NSMachPort port] forMode: NSDefaultRunLoopMode];
    [runLoop run];
}

-(void)doRestartstreaming:(id)sender{
    
    if (self.delegate&&[self.delegate respondsToSelector:@selector(needRestartStreaming:errorCode:)]) {
        [self.delegate needRestartStreaming:self errorCode:[sender integerValue]];
    }
}

-(void)dealloc{
}


#pragma  doVideoAudio send

-(void)sendStreamingData{
    
    if ([self.paThreadEngine paThread].cancelled) {
        return;
    }
    if (!self.isPushing) {
        return;
    }
    //    //send audio
    //    NSInteger audioResult =  [self recursionAudioFunction];
    //    NSInteger videoResult = [self recursionVideoFunction];
    
    NSInteger videoResult;
    NSInteger audioResult = [self doSendRtmp];
    videoResult = audioResult;
    
    if ((audioResult==-1)||(audioResult==-5)||(audioResult==-7)||(audioResult == -3)
        ||(videoResult==-1)||(videoResult==-5)||(videoResult==-7)||(videoResult == -3)) {
        self.preSendSuccess = NO;
        NSInteger breakCount = [IAUtility flowBreakCount];
        [IAUtility setFlowBreakCount:breakCount+1];
        
        //        NSInteger reStreamingCount = [IALogList reStreamingCount];
        NSLog(@"resultttt audio:%ld  video:%ld",(long)audioResult,(long)videoResult);
        NSString* logStr = [NSString stringWithFormat:@"rtmpsendError audioResult:%ld videoResult:%ld",(long)audioResult,(long)videoResult];
        [IAUtility IALog:logStr];
        
         [self performSelectorOnMainThread:@selector(doRestartstreaming:) withObject:[NSNumber numberWithInteger:audioResult] waitUntilDone:NO];
        
        
        return;
    }else{
        if (!self.preSendSuccess) {
            if (self.delegate&&[self.delegate respondsToSelector:@selector(pushFailure:errorCode:)]) {
                [self.delegate pushFailure:self errorCode:0];
            }
        }
        self.preSendSuccess = YES;
    }
    
    NSInteger videoEncodedDataCount = [self.videoEncodedArray count];
    NSInteger audioEncodedDataCount = [self.audioEncodedArray count];
    if ((videoEncodedDataCount==0)&&(audioEncodedDataCount==0)) {
        self.isMediaArrayLocked = NO;
        usleep(5000);
    }
    
    [self performSelector:@selector(sendStreamingData) onThread:[self.paThreadEngine paThread] withObject:nil waitUntilDone:NO];
}


//-(void)addOneRtmpSendErrorLog:(int)usedTime mediaType:(NSString*)type meidaSize:(int)mediaSize{
//
//    IAStreamingLogModel* logModel = [[IAStreamingLogModel alloc] init];
//    logModel.usedTime = [NSNumber numberWithInt:usedTime];
//    logModel.mediaType = type;
//    logModel.mediaSize = [NSNumber numberWithInt:mediaSize];
//    NSDictionary* dic = [logModel streamingLogModelWithLogLevel:@"1" type:@"expt" subType:[NSNumber numberWithInt:410] resolution:nil streamSpeed:nil rate:nil traceId:self.gameId reason:nil];
////    [IALogList addLogModel:dic];
//}

-(NSInteger)doSendRtmp{
    @autoreleasepool {
        if ([self.paThreadEngine paThread].cancelled) {
            return 0;
        }

        [self.audiolock lock];
        IAMediaDataModel* audioMediaModel = [self audioEncodedDataModel];
        IAMediaDataModel* lastAudioModel = [self lastAudioEncodedDataModel];
        self.willSendVideoModel = [self videoEncodedDataModel];
        self.willSendAudioModel = [self audioEncodedDataModel];
        IAMediaDataModel* lastVideoModel = [self lastVideoEncodedDataModel];
        
        NSInteger  timeOffset = 5000000;
        BOOL  overMaxTime = NO;
        if (audioMediaModel&&lastAudioModel) {
            long long audioOffset = lastAudioModel.timestamp - audioMediaModel.timestamp;
            if (audioOffset>timeOffset) {
                NSString* string = [NSString stringWithFormat:@"audioLock Offset:%llu",audioOffset];
                [IAUtility IALog:string];
                overMaxTime = YES;
            }
        }
        if (self.willSendVideoModel&&lastVideoModel) {
            long long videoOffset = self.willSendVideoModel.timestamp - lastVideoModel.timestamp;
            if (videoOffset>timeOffset) {
                NSString* string = [NSString stringWithFormat:@"videoLock Offset:%llu",videoOffset];
                [IAUtility IALog:string];
                overMaxTime = YES;
            }
        }
        
        if (overMaxTime) {
            self.isMediaArrayLocked = YES;
        }
        
        if (self.startPushInterval==0) {
            self.startPushInterval = [[NSDate date] timeIntervalSinceReferenceDate];
            self.sendDataLen = 0;
        }
        if (self.calcuateRate_StartPushInterval==0) {
            self.calcuateRate_StartPushInterval = [[NSDate date] timeIntervalSinceReferenceDate];
            self.calcuateRate_SendDataLen = 0;
        }
        //send little timestamp media
        NSInteger result = -1000;

        if(YES == self.continueGiveUpVideo && (nil != self.willSendAudioModel || (nil != self. willSendVideoModel && NO == self.willSendVideoModel.isKeyFrame))) {
            
            [self removeVideoEncodedData:[self videoEncodedDataModel]]; // Drop video frames until I frame comes
            [self removeAudioEncodedData:[self audioEncodedDataModel]];
            [self.audiolock unlock];
            return result;
        }
        self.continueGiveUpVideo = NO;

        if(YES == self.isMediaArrayLocked){ // Discard ALL A/V encoded frames.
            
            self.continueGiveUpVideo = YES;
            while ([self.videoEncodedArray count]>0) { //discard all video encoded frames.
                    [self removeVideoEncodedData:[self videoEncodedDataModel]];
            }

            while ([self.audioEncodedArray count]>0) { //discard all audio encoded frames.
                [self removeAudioEncodedData:[self audioEncodedDataModel]];
            }
            self.preSendedAudioDataModel = nil;
        }else if (!audioMediaModel&&self.willSendVideoModel) {
            if (self.preSendedAudioDataModel&&(self.preSendedAudioDataModel.timestamp<self.willSendVideoModel.timestamp)) {
                
                usleep(10000);
            }else{
                NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
                [IAUtility setLastVideoFrameSendTime:startTime];
                [IAUtility setLastVideoFrameSize:self.willSendVideoModel.data.length];
                self.beforeVideoSendTimeInterval = [[NSDate date] timeIntervalSince1970];
                
                if(YES != self.willSendVideoModel.isMetadata
                   && NULL != self.fileMuxer&& WRITE_FRAME_COUNT >= self.muxedFrameCount ++){
                    [self.fileMuxer FileMuxerInputVideoSample:(uint8_t *)[self.willSendVideoModel.data bytes]
                                                         size:(int)self.willSendVideoModel.data.length
                                                          pts:self.willSendVideoModel.timestamp dts:self.willSendVideoModel.timestamp
                                                     keyframe:self.willSendVideoModel.isKeyFrame];
                    if ((NULL != self.wnderfullClipMuxer)&&self.isWonderfullClipping) {
                        [self.wnderfullClipMuxer FileMuxerInputVideoSample:(uint8_t *)[self.willSendVideoModel.data bytes]
                                                             size:(int)self.willSendVideoModel.data.length
                                                              pts:self.willSendVideoModel.timestamp dts:self.willSendVideoModel.timestamp
                                                         keyframe:self.willSendVideoModel.isKeyFrame];
                    }
                }
                else if (WRITE_FRAME_COUNT <= self.muxedFrameCount)
                    [self clostFileMuxer];
                
                result = [self.rtmpSender rtmpSend:(uint8_t *)[self.willSendVideoModel.data bytes] bufLen:(int)self.willSendVideoModel.data.length type:1 timestamp:self.willSendVideoModel.timestamp];
                
                
                self.afterVideoSendedTimeInterval = [[NSDate date] timeIntervalSince1970];
                self.allSendedFrames++;
                NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
                float offset = endTime-startTime;
                offset = offset*1000;
              //  NSLog(@"############### offffset vvv :%f timestamp:%lld",offset,self.willSendVideoModel.timestamp);
                self.sendDataLen+=self.willSendVideoModel.data.length;
                self.calcuateRate_SendDataLen+=self.willSendVideoModel.data.length;
                [self removeVideoEncodedData:self.willSendVideoModel];
            }
        }else if (audioMediaModel && self.willSendVideoModel&&(audioMediaModel.timestamp>self.willSendVideoModel.timestamp)){
            
            //discard the outTime videoFrame
            
            if (self.preSendedAudioDataModel) {
                
                if ( self.continueGiveUpVideo || (self.preSendedAudioDataModel.timestamp>(self.willSendVideoModel.timestamp+5*1000*1000))) {
                    self.continueGiveUpVideo = YES;
                    
                    while ([self.videoEncodedArray count]>0) { //discard all the p frame before I frame
                        
                        if (((self.willSendVideoModel.timestamp>self.preSendedAudioDataModel.timestamp)|| (llabs(self.preSendedAudioDataModel.timestamp-self.willSendVideoModel.timestamp)<1000*1000))&&self.willSendVideoModel.isKeyFrame){
                            self.continueGiveUpVideo = NO;
                            
                            [IAUtility IALog:@"discard videoFrame finished"];
                            break;
                        }else{
                            //discard
                            NSString* logInfo = [NSString stringWithFormat:@"iderek discard videoFrame :preSendedAudioDataModel:%lld willsendvideoModel:%lld  iskeyframe:%d,willsendvideoModel:%@ willsendvideoModel.size:%lu videoCount:%lu aduioCount:%lu self.isMediaArrayLocked:%d",self.preSendedAudioDataModel.timestamp,self.willSendVideoModel.timestamp,self.willSendVideoModel.isKeyFrame,self.willSendVideoModel,(unsigned long)[self.willSendVideoModel.data length],(unsigned long)[self.videoEncodedArray count],(unsigned long)[self.audioEncodedArray count],self.isMediaArrayLocked];
                            NSLog(logInfo,nil);
                            [IAUtility IALog:logInfo];
                            self.willSendVideoModel = [self videoEncodedDataModel]; //update the next willsendVideoModel
                            [self removeVideoEncodedData:self.willSendVideoModel];
                        }
                    }
                }
            }
            
            if (self.continueGiveUpVideo==NO) {
                IAMediaDataModel*  currentVideoModel = [self videoEncodedDataModel];
                if (currentVideoModel) {
                    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
                    
                    [IAUtility setLastVideoFrameSendTime:startTime];
                    [IAUtility setLastVideoFrameSize:currentVideoModel.data.length];
                    self.beforeVideoSendTimeInterval = [[NSDate date] timeIntervalSince1970];
                    
                    if(YES != self.willSendVideoModel.isMetadata
                       && NULL != self.fileMuxer && WRITE_FRAME_COUNT >= self.muxedFrameCount ++){
                        [self.fileMuxer FileMuxerInputVideoSample:(uint8_t *)[self.willSendVideoModel.data bytes]
                                                             size:(int)self.willSendVideoModel.data.length
                                                              pts:self.willSendVideoModel.timestamp dts:self.willSendVideoModel.timestamp
                                                         keyframe:self.willSendVideoModel.isKeyFrame];
                        if ((NULL != self.wnderfullClipMuxer)&&self.isWonderfullClipping) {
                            [self.wnderfullClipMuxer FileMuxerInputVideoSample:(uint8_t *)[self.willSendVideoModel.data bytes]
                                                                          size:(int)self.willSendVideoModel.data.length
                                                                           pts:self.willSendVideoModel.timestamp dts:self.willSendVideoModel.timestamp
                                                                      keyframe:self.willSendVideoModel.isKeyFrame];
                        }
                    }else if (WRITE_FRAME_COUNT <= self.muxedFrameCount)
                        [self clostFileMuxer];
                    
                    result = [self.rtmpSender rtmpSend:(uint8_t *)[currentVideoModel.data bytes] bufLen:(int)currentVideoModel.data.length type:1 timestamp:currentVideoModel.timestamp];
                    self.afterVideoSendedTimeInterval = [[NSDate date] timeIntervalSince1970];
                     self.allSendedFrames++;
                    NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
                    float offset = endTime-startTime;
                    offset = offset*1000;
                    //   NSLog(@"############### offffset vvv :%f timestamp:%lld",offset,currentVideoModel.timestamp);
                    
                    //                    if (offset>IA_RtmpVideoSend_OverTime) {
                    //                        [self addOneRtmpSendErrorLog:(int)offset mediaType:@"video" meidaSize:(int)currentVideoModel.data.length];
                    //                    }
                    
                    self.sendDataLen+=currentVideoModel.data.length;
                    self.calcuateRate_SendDataLen+=currentVideoModel.data.length;
                    [self removeVideoEncodedData:currentVideoModel];
                }
            } else {
                usleep(10000);
            }
        }else{
            if (audioMediaModel) {
                
                NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
                [IAUtility setLastAudioFrameSendTime:startTime];
                [IAUtility setLastAudioFrameSize:audioMediaModel.data.length];
                // result = rtmpSend((uint8_t *)[audioMediaModel.data bytes], (int)audioMediaModel.data.length, 0, audioMediaModel.timestamp);
                //     NSLog(@"beee*************send a");
                
                self.beforeAudioSendTimeInterval = [[NSDate date] timeIntervalSince1970];
                result = [self.rtmpSender rtmpSend:(uint8_t *)[audioMediaModel.data bytes] bufLen:(int)audioMediaModel.data.length type:0 timestamp: audioMediaModel.timestamp];
                
                if(NULL != self.fileMuxer && WRITE_FRAME_COUNT >= self.muxedFrameCount ++)
//                    NSLog(@"################### Mux Audio");
                    [self.fileMuxer FileMuxerInputAudioSample:(uint8_t *)[audioMediaModel.data bytes]
                                                        size:(int)audioMediaModel.data.length
//                                                          pts:audioMediaModel.timestamp dts:0];
                                                        pts:audioMediaModel.timestamp dts:audioMediaModel.timestamp];
                if ((NULL != self.wnderfullClipMuxer)&&self.isWonderfullClipping) {
                    [self.wnderfullClipMuxer FileMuxerInputAudioSample:(uint8_t *)[audioMediaModel.data bytes]
                                                         size:(int)audioMediaModel.data.length
                     //                                                          pts:audioMediaModel.timestamp dts:0];
                                                          pts:audioMediaModel.timestamp dts:audioMediaModel.timestamp];
                }
                else if (WRITE_FRAME_COUNT <= self.muxedFrameCount)
                    [self clostFileMuxer];
            
                self.afterAudioSendedTimeInterval = [[NSDate date] timeIntervalSince1970];
                
                NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
                float offset = endTime-startTime;
                offset = offset*1000;
                //   NSLog(@"############### offffset aaa :%f timestamp:%lld",offset,audioMediaModel.timestamp);
                //                if (offset>IA_RtmpAudioSend_OverTime) {
                //                    [self addOneRtmpSendErrorLog:(int)offset mediaType:@"audio" meidaSize:(int)audioMediaModel.data.length];
                //                }
                
                
                self.sendDataLen+=audioMediaModel.data.length;
                self.calcuateRate_SendDataLen+=audioMediaModel.data.length;
                self.preSendedAudioDataModel = audioMediaModel;
                [self removeAudioEncodedData:audioMediaModel];
            } else {
                usleep(10000);
            }
        }

        [self.audiolock unlock];
        return result;
    }
}

-(void)calculateDropFrameRte:(NSInteger)count{

    
    //should be invoked 5s everytime
//    if (self.startSendFrameTimeInterval==0) {
//        self.startSendFrameTimeInterval = [[NSDate date] timeIntervalSince1970];
//    }
//    
//    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
//    unsigned long long offset =currentTime-self.startSendFrameTimeInterval;
    
    NSInteger configFPS = 25*count;
    long long frameOffset = configFPS-self.allSendedFrames;
    self.discardFrameRate = (CGFloat)frameOffset/configFPS;
    self.discardFrameRate = self.discardFrameRate>0?self.discardFrameRate:0;
    self.discardFrameRate = self.discardFrameRate>1?1:self.discardFrameRate;
    self.allSendedFrames = 0;

}

-(CGFloat)dropdownFrameRate{
    
    return self.discardFrameRate;
}



-(void)setIsMediaArrayLocked:(BOOL)isMediaArrayLocked{
    
    _isMediaArrayLocked = isMediaArrayLocked;
    if (self.h264Encoder) {
        self.h264Encoder.shouldDiscardframe = _isMediaArrayLocked;
    }
}

-(NSInteger)recursionVideoFunction{
    
    @autoreleasepool {
        if (![self.paThreadEngine paThread] || [self.paThreadEngine paThread].cancelled) {
            return 0;
        }
        
        [self.videolock lock];
        IAMediaDataModel* mediaModel = [self videoEncodedDataModel];
        NSInteger result= -2000;
        if (mediaModel) {
            
            if (self.startPushInterval==0) {
                self.startPushInterval = [[NSDate date] timeIntervalSinceReferenceDate];
                self.sendDataLen = 0;
            }
            if (self.calcuateRate_StartPushInterval==0) {
                self.calcuateRate_StartPushInterval = [[NSDate date] timeIntervalSinceReferenceDate];
                self.calcuateRate_SendDataLen = 0;
            }
            
            
            //result =rtmpSend((uint8_t *)[mediaModel.data bytes], (int)mediaModel.data.length, 1, mediaModel.timestamp);
            
            
            result = [self.rtmpSender rtmpSend:(uint8_t *)[mediaModel.data bytes] bufLen:(int)mediaModel.data.length type:1 timestamp:mediaModel.timestamp];
            
            
            self.sendDataLen+=mediaModel.data.length;
            self.calcuateRate_SendDataLen+=mediaModel.data.length;
            
            [self removeVideoEncodedData:mediaModel];
        }
        [self.videolock unlock];
        return result;
        
    }
}

-(NSInteger)recursionAudioFunction{
    
    @autoreleasepool {
        if ([self.paThreadEngine paThread].cancelled) {
            return 0;
        }
        
        [self.audiolock lock];
        IAMediaDataModel* mediaModel = [self audioEncodedDataModel];
        NSInteger result = -1000;
        if (mediaModel) {
            
            if (self.startPushInterval==0) {
                self.startPushInterval = [[NSDate date] timeIntervalSinceReferenceDate];
                self.sendDataLen = 0;
            }
            if (self.calcuateRate_StartPushInterval==0) {
                self.calcuateRate_StartPushInterval = [[NSDate date] timeIntervalSinceReferenceDate];
                self.calcuateRate_SendDataLen = 0;
            }
            
            //discard the outTime videoFrame
            
            IAMediaDataModel*  willSendVideoModel = [self videoEncodedDataModel];
            
            if (self.preSendedAudioDataModel&&willSendVideoModel) {
                
                if ( self.continueGiveUpVideo || (self.preSendedAudioDataModel.timestamp>(willSendVideoModel.timestamp+5*1000*1000))) {
                    self.continueGiveUpVideo = YES;
                    while ([self.videoEncodedArray count]>0) { //discard all the p frame before I frame
                        IAMediaDataModel*  currentVideoModel = [self videoEncodedDataModel];
                        
                        if ((llabs(self.preSendedAudioDataModel.timestamp-currentVideoModel.timestamp)<1000*1000)&&currentVideoModel.isKeyFrame) {
                            self.continueGiveUpVideo = NO;
                            break;
                        }else{
                            //discard
                            NSLog(@"discard videoFrame****");
                            [self removeVideoEncodedData:currentVideoModel];
                        }
                        
                    }
                }
            }
            
            //      result = rtmpSend((uint8_t *)[mediaModel.data bytes], (int)mediaModel.data.length, 0, mediaModel.timestamp);
            
            result = [self.rtmpSender rtmpSend:(uint8_t *)[mediaModel.data bytes] bufLen: (int)mediaModel.data.length type:0 timestamp:mediaModel.timestamp];
            self.sendDataLen+=mediaModel.data.length;
            self.calcuateRate_SendDataLen+=mediaModel.data.length;
            self.preSendedAudioDataModel = mediaModel;
            [self removeAudioEncodedData:mediaModel];
        }
        [self.audiolock unlock];
        
        return result;
    }
    
}



#pragma mark - IAAudioCaptureEngineDelegate

- (void)gotAudioEncodedData:(NSData*)aData len:(long long)len timeDuration:(long long)duration{
    
    
}


#pragma mark - IAVideoCaptureEngineDelegate

- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps object:(H264HwEncoderImpl*)object{
    
    //   if ([self.liveType isEqualToString:IA_Record_Key]) {
    //        return;
    //    }
    
    if (self.hasPPSSended) {
        return;
    }else{
        self.hasPPSSended = YES;
    }
    NSLog(@"spspps");
    
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    
    NSMutableData* mutableSPSData = [NSMutableData dataWithData:ByteHeader];
    [mutableSPSData appendData:sps];
    
    NSMutableData* mutablePPSData = [NSMutableData dataWithData:ByteHeader];
    [mutablePPSData appendData:pps];
    
    
    if (self.startPushInterval==0) {
        self.startPushInterval = [[NSDate date] timeIntervalSinceReferenceDate];
        self.sendDataLen = 0;
    }
    
    if (self.calcuateRate_StartPushInterval==0) {
        self.calcuateRate_StartPushInterval = [[NSDate date] timeIntervalSinceReferenceDate];
        self.calcuateRate_SendDataLen = 0;
    }
    
    if (NULL != self.fileMuxer) {
        [self.fileMuxer FileMuxerSetSPSPPSWith:(uint8_t *)[mutableSPSData bytes] pps:(uint8_t *)[mutablePPSData bytes]
                                    spsLen:(int)mutableSPSData.length ppsLen:(int)mutablePPSData.length];
    }
    if ((NULL != self.wnderfullClipMuxer)&&self.isWonderfullClipping) {
        [self.wnderfullClipMuxer FileMuxerSetSPSPPSWith:(uint8_t *)[mutableSPSData bytes] pps:(uint8_t *)[mutablePPSData bytes]
                                        spsLen:(int)mutableSPSData.length ppsLen:(int)mutablePPSData.length];
    }
    
#ifdef IA_CoustomRtmpThread_Key
    
    IAMediaDataModel* spsEncodedAudioModel = [[IAMediaDataModel alloc] init];
    spsEncodedAudioModel.data = mutableSPSData;
    spsEncodedAudioModel.size = [mutableSPSData length];
    spsEncodedAudioModel.timestamp = 0;
    spsEncodedAudioModel.isVideo = YES;
    spsEncodedAudioModel.isKeyFrame = NO;
    spsEncodedAudioModel.isMetadata = YES;
    
    IAMediaDataModel* ppsEncodedAudioModel = [[IAMediaDataModel alloc] init];
    ppsEncodedAudioModel.data = mutablePPSData;
    ppsEncodedAudioModel.size = [mutablePPSData length];
    ppsEncodedAudioModel.timestamp = 0;
    ppsEncodedAudioModel.isVideo = YES;
    ppsEncodedAudioModel.isKeyFrame = NO;
    spsEncodedAudioModel.isMetadata = YES;
    
    [self.videolock lock];
    [self.videoEncodedArray addObject:spsEncodedAudioModel];
    [self.videoEncodedArray addObject:ppsEncodedAudioModel];
    [self.videolock unlock];
    
#else
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0) , ^{
        rtmpSend((uint8_t *)[mutableSPSData bytes], (int)mutableSPSData.length, 1, 0);
        rtmpSend((uint8_t *)[mutablePPSData bytes], (int)mutablePPSData.length, 1, 0);
        
        weakSelf.sendDataLen+=mutableSPSData.length;
        weakSelf.sendDataLen+=mutablePPSData.length;
        weakSelf.calcuateRate_SendDataLen+=mutablePPSData.length;
        weakSelf.calcuateRate_SendDataLen+=mutableSPSData.length;
        
    });
    
#endif
    
}


- (void)gotEncodedData:(NSData*)aData isKeyFrame:(BOOL)isKeyFrame timeDuration:(long long)duration object:(H264HwEncoderImpl*)object{
    
    
    //    if ([self.liveType isEqualToString:IA_Record_Key]) {
    //        return;
    //    }
    
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    
    NSMutableData* mutableData = [NSMutableData dataWithData:ByteHeader];
    [mutableData appendData:aData];
    const char*  buffer = [mutableData bytes];
    
    if (6 == (int)(buffer[4] & 0x1F)) {
        return;
    }
    
    [self.videoMediaStampModelLock lock];
    NSInteger timeStampArrayCount = [self.videoTimeStampArray count];
    if (timeStampArrayCount>0) {
        
        long  tempOffset = [[self.videoTimeStampArray objectAtIndex:0] longValue];
        if (self.preSendVideoTimeStamp>=tempOffset) {
            self.preSendVideoTimeStamp+=30000;
        }else{
            self.preSendVideoTimeStamp = tempOffset;
        }
        
        [self.videoTimeStampArray removeObjectAtIndex:0];
    }else{
        self.preSendVideoTimeStamp+=30000;
    }
    
    [self.videoMediaStampModelLock unlock];
    
    //    NSLog(@"durationnnnn :%llu  self.preSendVideoTimeStamp:%llu",duration,self.preSendVideoTimeStamp);
#ifdef IA_CoustomRtmpThread_Key
    
    IAMediaDataModel* encodedAudioModel = [[IAMediaDataModel alloc] init];
    encodedAudioModel.data = mutableData;
    encodedAudioModel.size = [mutableData length];
    //encodedAudioModel.timestamp = self.preSendVideoTimeStamp;
    encodedAudioModel.timestamp = duration;
    encodedAudioModel.isVideo = YES;
    encodedAudioModel.isKeyFrame = isKeyFrame;
    [self.videolock lock];
    [self.videoEncodedArray addObject:encodedAudioModel];
    [self.videolock unlock];
    
    //    NSString* videoTimeStamp = [NSString stringWithFormat:@"videoTimeStamp :%lld count:%ld :array:%@",self.preSendVideoTimeStamp,(long)timeStampArrayCount,self.videoTimeStampArray];
    //    [IAUtility IALog:videoTimeStamp];
    //    NSLog(videoTimeStamp);
    
    //   NSLog(@"IALog_video_outputdatasize: %ld timestamp :%lld isPushing :%d",[mutableData length],self.preSendVideoTimeStamp,(int)(buffer[4] & 0x1F));
#else
    
    IAMediaDataModel* encodedAudioModel = [[IAMediaDataModel alloc] init];
    encodedAudioModel.data = mutableData;
    encodedAudioModel.size = [mutableData length];
    encodedAudioModel.timestamp = self.preSendVideoTimeStamp;
    encodedAudioModel.isVideo = YES;
    encodedAudioModel.isKeyFrame = isKeyFrame;
    [self addOneMediaModel:encodedAudioModel];
#endif
    
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (self.isMediaArrayLocked) {
        NSString* lockStr = [NSString stringWithFormat:@"######locked captureOutput....### :audioCount:%lu videoCount:%lu",(unsigned long)[self.audioEncodedArray count],(unsigned long)[self.videoEncodedArray count]];
        [IAUtility IALog:lockStr];
        NSLog(lockStr,nil);
        return;
    }
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    if ([captureOutput isKindOfClass:[AVCaptureVideoDataOutput class]]) {
        
        self.outputVideoFormatDescription = formatDescription;
        
        if (!self.isPushing) {
            return;
        }else{
        }
        
        [self doVideoOutputSampleBuffer:sampleBuffer];
        //        if ([self.liveType isEqualToString:IA_Record_Key]) {
        //            @synchronized(self) {
        //                if(_recordingStatus == RecordingStatusRecording){
        //
        //                    [self.avWriterEngine appendVideoSampleBuffer:sampleBuffer];
        //                }
        //            }
        //
        //        }else if ([self.liveType isEqualToString:IA_Streaming_Key]){
        //        }else{
        //        }
        
    }else if ([captureOutput isKindOfClass:[AVCaptureAudioDataOutput class]]){
        
        self.outputAudioFormatDescription = formatDescription;
        if (!self.isPushing) {
            return;
        }else{
        }
        
        [self doAudioOutputSampleBuffer:sampleBuffer];
        
        //        if ([self.liveType isEqualToString:IA_Record_Key]) {
        //
        //            @synchronized( self ) {
        //                if(_recordingStatus == RecordingStatusRecording){
        //                    [self.avWriterEngine appendAudioSampleBuffer:sampleBuffer];
        //                }
        //            }
        //
        //        }else if ([self.liveType isEqualToString:IA_Streaming_Key]){
        //        }else{
        //        }
    }else{
    }
    
}


static bool isFirst  = YES;
static NSTimeInterval  startTime;
static NSInteger   frameCount = 0;

-(void)doVideoOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    
#ifdef IA_CoustomRtmpThread_Key
    
    //videoEncodedData full
    
    //        if ([self.videoEncodedArray count]>IA_VideoEncodedDataArray_Max) {
    //            return;
    //        }
    
#else
    
#ifdef IA_SendAudioThread_Key
    if ([self.mediaVideoRtmpOperationQueue operationCount]>50) {
        return;
    }
#else
#endif
#endif
    
    frameCount++;
    if (isFirst) {
        startTime = [[NSDate date] timeIntervalSinceReferenceDate];
        isFirst = NO;
    }else{
        NSTimeInterval currentInterval = [[NSDate date] timeIntervalSinceReferenceDate];
        if (((currentInterval-startTime-1)>0)&&((currentInterval-startTime-1)<0.05)) {
            NSLog(@"isFirsttt  :%ld",(long)frameCount);
        }
    }
    
    //add timesample
    
    
    //  NSLog(@"IALog_video_captureSource: %ld",tempOffset);
    //add end
    
    
    [self.h264Encoder encode:sampleBuffer];
    //    if ([self.OP count]<IA_VideoEncodedDataArray_Max) {
    //        //encode
    //        [self.h264Encoder encode:sampleBuffer];
    //    }
    
}

#pragma PAAudioCoderDelegate
-(void)beginningCode{
    
    self.beforeAudioEncodeTimeInterval = [[NSDate date] timeIntervalSince1970];
    [self markAudioTimeStamp];
    
}

-(void)audioCoder:(char*)outputData length:(UInt32)length{
    
    self.afterAudioEncodedTimeInterval = [[NSDate date] timeIntervalSince1970];
    char*  beginData = " f";
    if (strcmp(outputData, beginData)!=0) {
        
        
        [self.audioMediaStampModelLock lock];
        
        NSInteger timeStampArrayCount = [self.audioTimeStampArray count];
        if (timeStampArrayCount>0) {
            
            long  tempOffset = [[self.audioTimeStampArray objectAtIndex:0] longValue];
            if (self.preSendAudioTimeStamp>tempOffset) {
                self.preSendAudioTimeStamp+=23000;
            }else{
                self.preSendAudioTimeStamp = tempOffset;
            }
            
            [self.audioTimeStampArray removeObjectAtIndex:0];
        }else{
            self.preSendAudioTimeStamp+=2000;
        }
        
        [self.audioMediaStampModelLock unlock];
        
        IAMediaDataModel* encodedAudioModel = [[IAMediaDataModel alloc] init];
        encodedAudioModel.data = [NSData dataWithBytes:outputData length:length];
        encodedAudioModel.size = length;
        encodedAudioModel.timestamp = self.preSendAudioTimeStamp;
        encodedAudioModel.isVideo = NO;
        [self.audiolock lock];
        [self.audioEncodedArray addObject:encodedAudioModel];
        [self.audiolock unlock];
        
   
    }
}


-(void)doAudioOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    
    NSLog(@"doAudioOutputSampleBuffer");
    
#ifdef IA_CoustomRtmpThread_Key
    
    // if the _audioEncodedArray is full stop to encode
    
    //    if ([self.audioEncodedArray count]>IA_AudioEncodedDataArray_Max) {
    //        return;
    //    }
    
    
#else
    
#ifdef IA_SendAudioThread_Key
    if ([self.mediaAudioRtmpOperationQueue operationCount]>25) {
        return;
    }
#else
#endif
    
#endif
    
    
    if (self.audioEncodedArray) {
        char szBuf[4096];
        int  nSize = sizeof(szBuf);
        char*  beginData = " f";
#ifdef SUPPORT_AAC_ENCODER
        if ([self encoderAAC:sampleBuffer aacData:szBuf aacLen:&nSize] == YES)
        {
            if (strcmp(szBuf, beginData)!=0) {
                
               
                [self.audioMediaStampModelLock lock];
                
                NSInteger timeStampArrayCount = [self.audioTimeStampArray count];
                if (timeStampArrayCount>0) {
                    
                    long  tempOffset = [[self.audioTimeStampArray objectAtIndex:0] longValue];
                    if (self.preSendAudioTimeStamp>tempOffset) {
                        self.preSendAudioTimeStamp+=23000;
                    }else{
                        self.preSendAudioTimeStamp = tempOffset;
                    }
                    
                    [self.audioTimeStampArray removeObjectAtIndex:0];
                }else{
                    self.preSendAudioTimeStamp+=2000;
                }
                
                [self.audioMediaStampModelLock unlock];
                
#ifdef IA_CoustomRtmpThread_Key
                
                IAMediaDataModel* encodedAudioModel = [[IAMediaDataModel alloc] init];
                encodedAudioModel.data = [NSData dataWithBytes:szBuf length:nSize];
                encodedAudioModel.size = nSize;
                encodedAudioModel.timestamp = self.preSendAudioTimeStamp;
                encodedAudioModel.isVideo = NO;
                [self.audiolock lock];
                [self.audioEncodedArray addObject:encodedAudioModel];
                [self.audiolock unlock];
                
#else
                
#ifdef IA_SendAudioThread_Key
                
                IAMediaDataModel* encodedAudioModel = [[IAMediaDataModel alloc] init];
                encodedAudioModel.data = [NSData dataWithBytes:szBuf length:nSize];
                encodedAudioModel.size = nSize;
                encodedAudioModel.timestamp = self.preSendAudioTimeStamp;
                encodedAudioModel.isVideo = NO;
                [self addOneMediaModel:encodedAudioModel];
#else
                
                if (self.startPushInterval==0) {
                    self.startPushInterval = [[NSDate date] timeIntervalSinceReferenceDate];
                    self.sendDataLen = 0;
                }
                if (self.calcuateRate_StartPushInterval==0) {
                    self.calcuateRate_StartPushInterval = [[NSDate date] timeIntervalSinceReferenceDate];
                    self.calcuateRate_SendDataLen = 0;
                }
                int rtmpSendResult = rtmpSend((uint8_t *)[[NSData dataWithBytes:szBuf length:nSize] bytes], (int)nSize, 0, self.preSendAudioTimeStamp);
                
                if ((rtmpSendResult==-1)||(rtmpSendResult==-5)||(rtmpSendResult==-7)) {
                    NSInteger reStreamingCount = [IALogList reStreamingCount];
                    if (reStreamingCount<IA_RestartStreamingCount_Max) {
                        [self performSelectorOnMainThread:@selector(doRestartstreaming:) withObject:nil waitUntilDone:NO];
                    }
                    [IALogList setReStreamingCount:reStreamingCount+1];
                }else{
                    [IALogList setReStreamingCount:0];
                }
                
                self.sendDataLen+=nSize;
                self.calcuateRate_SendDataLen+=nSize;
#endif
                
#endif
                
            }
            
        }
#else //#if SUPPORT_AAC_ENCODER
        AudioStreamBasicDescription outputFormat = *(CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(sampleBuffer)));
        nSize = CMSampleBufferGetTotalSampleSize(sampleBuffer);
        CMBlockBufferRef databuf = CMSampleBufferGetDataBuffer(sampleBuffer);
        if (CMBlockBufferCopyDataBytes(databuf, 0, nSize, szBuf) == kCMBlockBufferNoErr)
        {
            if (strcmp(szBuf, beginData)!=0) {
                
                
                if (self.startPushInterval==0) {
                    self.startPushInterval = [[NSDate date] timeIntervalSinceReferenceDate];
                    self.sendDataLen = 0;
                }
                if (self.calcuateRate_StartPushInterval==0) {
                    self.calcuateRate_StartPushInterval = [[NSDate date] timeIntervalSinceReferenceDate];
                    self.calcuateRate_SendDataLen = 0;
                }
                BOOL result = rtmpSend((uint8_t *)[[NSData dataWithBytes:szBuf length:nSize] bytes], (int)nSize, 0, offsetInterval);
                self.sendDataLen+=nSize;
                self.calcuateRate_SendDataLen+=nSize;
                
                //rtmpSend((uint8_t *)[[NSData dataWithBytes:szBuf length:nSize] bytes], (int)nSize, 0, offsetInterval);
                
                //                IAMediaDataModel* encodedAudioModel = [[IAMediaDataModel alloc] init];
                //                encodedAudioModel.data = [NSData dataWithBytes:szBuf length:nSize];
                //                encodedAudioModel.size = nSize;
                //                encodedAudioModel.timestamp = offsetInterval;
                //                [self.audiolock lock];
                //                [self.audioEncodedArray addObject:encodedAudioModel];
                //                [self.audiolock unlock];
            }
        }
#endif
    }
}

#ifdef SUPPORT_AAC_ENCODER
-(BOOL)createAudioConvert:(CMSampleBufferRef)sampleBuffer { //根据输入样本初始化一个编码转换器
    if (m_converter != nil)
    {
        return TRUE;
    }
    
    AudioStreamBasicDescription inputFormat = *(CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(sampleBuffer))); // 输入音频格式
    AudioStreamBasicDescription outputFormat; // 这里开始是输出音频格式
    memset(&outputFormat, 0, sizeof(outputFormat));
    outputFormat.mSampleRate       = inputFormat.mSampleRate; // 采样率保持一致
    outputFormat.mFormatID         = kAudioFormatMPEG4AAC;    // AAC编码
    outputFormat.mChannelsPerFrame = inputFormat.mChannelsPerFrame;
    outputFormat.mFramesPerPacket  = 1024;                    // AAC一帧是1024个字节
    
    outputFormat.mFormatFlags = kMPEG4Object_AAC_LC;
    outputFormat.mReserved = 0;
    
    AudioClassDescription *desc = [self getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC fromManufacturer:kAppleSoftwareAudioCodecManufacturer];
    if (AudioConverterNewSpecific(&inputFormat, &outputFormat, 1, desc, &m_converter) != noErr)
    {
        NSLog(@"AudioConverterNewSpecific failed");
        [IAUtility IALog:@"AudioConverterNewSpecific failed"];
        return NO;
    }
    
    return YES;
}

char * audioInData = NULL;
int remainSize = 0;

-(void)markAudioTimeStamp{
#ifdef IA_SmoothTime_Key
    if (self.startVideoTimeInterval==0) {
        self.startVideoTimeInterval =[[NSDate date] timeIntervalSinceReferenceDate];
        self.baseAudioTime = 0;
        self.audioTimeStamp = 0;
    }else{
        
        CGFloat baseOffset = self.audioTimeStamp-self.baseAudioTime;
        CGFloat checkCurrentTimeOffset = baseOffset-IA_CheckCurrentAudioTime_Interval;
        
        if ((checkCurrentTimeOffset>=0)&&(checkCurrentTimeOffset<IA_AudioIncrease_Interval)) {
            NSTimeInterval currentInterval = [[NSDate date] timeIntervalSinceReferenceDate];
            CGFloat temp = currentInterval-self.startVideoTimeInterval;
            temp = temp*1000;
            if (temp>self.audioTimeStamp) {
                self.audioTimeStamp = temp;
            }else{
                self.audioTimeStamp+=IA_AudioIncrease_Interval;
            }
            self.baseAudioTime = self.audioTimeStamp;
        }else{
            self.audioTimeStamp+=IA_AudioIncrease_Interval;
        }
    }
    
    long tempOffset = self.audioTimeStamp;
    int checkInt =  0x1;
    if ((tempOffset&checkInt)==0) {
        tempOffset+=1;
    }
    if (self.lastAudioFrameInterval!=0) {
        if (tempOffset<self.lastAudioFrameInterval) {
            tempOffset = self.lastAudioFrameInterval+2;
        }else if (labs(self.lastAudioFrameInterval-tempOffset)<2) {
            tempOffset=self.lastAudioFrameInterval+2;
        }
    }
    self.lastAudioFrameInterval = tempOffset;
    tempOffset = tempOffset*1000;
    
    [self.audioMediaStampModelLock lock];
    [self.audioTimeStampArray addObject:[NSNumber numberWithLong:tempOffset]];
    [self.audioMediaStampModelLock unlock];
    
#else
    
    NSTimeInterval startTimeInterval = [IAUtility startTimestampInterval];
    
    if (startTimeInterval==0) {
        startTimeInterval = [[NSDate date] timeIntervalSinceReferenceDate];
        [IAUtility setStartTimestampInterval:startTimeInterval];
    }
    NSTimeInterval currentInterval = [[NSDate date] timeIntervalSinceReferenceDate];
    CGFloat offsetInterval = currentInterval-startTimeInterval;
    offsetInterval=offsetInterval*1000;
    long tempOffset = offsetInterval;
    int checkInt =  0x1;
    if ((tempOffset&checkInt)==0) {
        tempOffset+=1;
    }
    if (self.lastAudioFrameInterval!=0) {
        if (tempOffset<self.lastAudioFrameInterval) {
            tempOffset = self.lastAudioFrameInterval+2;
        }else if (labs(self.lastAudioFrameInterval-tempOffset)<2) {
            tempOffset=self.lastAudioFrameInterval+2;
        }
    }
    
    self.lastAudioFrameInterval = tempOffset;
    tempOffset = tempOffset*1000;
    
    [self.audioMediaStampModelLock lock];
    [self.audioTimeStampArray addObject:[NSNumber numberWithLong:tempOffset]];
    [self.audioMediaStampModelLock unlock];
    
    
#endif
}

-(BOOL)encoderAAC:(CMSampleBufferRef)sampleBuffer aacData:(char*)aacData aacLen:(int*)aacLen { // 编码PCM成AAC
    if ([self createAudioConvert:sampleBuffer] != YES)
    {
        return NO;
    }
    
    CMBlockBufferRef blockBuffer = nil;
    AudioBufferList  inBufferList;
    if (CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &inBufferList, sizeof(inBufferList), NULL, NULL, 0, &blockBuffer) != noErr)
    {
        NSLog(@"CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer failed");
        [IAUtility IALog:@"CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer failed"];
        return NO;
    }
    
    //////////////////////
    if(self.needMuted){
        memset(inBufferList.mBuffers[0].mData, 0, inBufferList.mBuffers[0].mDataByteSize);
    }
    
    uint8_t * data_pos = NULL;
    int remain = 0;
    uint8_t * ori_p = inBufferList.mBuffers[0].mData;
    int ori_s = inBufferList.mBuffers[0].mDataByteSize;
    // NSLog(@"IALog_audio_inputDataSize: %d",ori_s);
    
    //    if (self.composeAudioSize>2048) {
    //
    //        [self.audioMediaStampModelLock lock];
    //        [self.audioTimeStampArray removeObjectAtIndex:0];
    //        [self.audioMediaStampModelLock unlock];
    //        NSLog(@"discard audiotimestamp");
    //        self.composeAudioSize = self.composeAudioSize - 2048;
    //    }else{
    //        self.composeAudioSize+=(2048-ori_s);
    //    }
    
    if(NULL == audioInData){
        audioInData = malloc((2048 + 1)* sizeof(uint8_t));
    }
    
    if(inBufferList.mBuffers[0].mDataByteSize < 2048){
        
        if(0 == remainSize) {
            memcpy(audioInData, inBufferList.mBuffers[0].mData, inBufferList.mBuffers[0].mDataByteSize);
            remainSize = inBufferList.mBuffers[0].mDataByteSize;
            CFRelease(blockBuffer);
            return NO;
        } else {
            int data_size = remainSize + inBufferList.mBuffers[0].mDataByteSize;
            if(data_size > 2048) {
                memcpy(audioInData + remainSize, inBufferList.mBuffers[0].mData, 2048 - remainSize);
                data_pos = inBufferList.mBuffers[0].mData + 2048 - remainSize;
                remain = inBufferList.mBuffers[0].mDataByteSize - (2048 - remainSize);
            } else {
                memcpy(audioInData + remainSize, inBufferList.mBuffers[0].mData, inBufferList.mBuffers[0].mDataByteSize);
                if(data_size < 2048) {
                    remainSize += inBufferList.mBuffers[0].mDataByteSize;
                    CFRelease(blockBuffer);
                    return NO;
                }
                remainSize = 0;
            }
        }
        inBufferList.mBuffers[0].mData = audioInData;
        inBufferList.mBuffers[0].mDataByteSize = 2048;
    }
    
    ////////////////////
    [self markAudioTimeStamp];
    
    
    // 初始化一个输出缓冲列表
    AudioBufferList outBufferList;
    outBufferList.mNumberBuffers              = 1;
    outBufferList.mBuffers[0].mNumberChannels = inBufferList.mBuffers[0].mNumberChannels;
    outBufferList.mBuffers[0].mDataByteSize   = *aacLen; // 设置缓冲区大小
    outBufferList.mBuffers[0].mData           = aacData; // 设置AAC缓冲区
    UInt32 outputDataPacketSize               = 1;
    if (AudioConverterFillComplexBuffer(m_converter, inputDataProc, &inBufferList, &outputDataPacketSize, &outBufferList, NULL) != noErr)
    {
        CFRelease(blockBuffer);
        NSLog(@"AudioConverterFillComplexBuffer failed");
        [IAUtility IALog:@"AudioConverterFillComplexBuffer failed"];
        
        return NO;
    }
    
    ///////////////////////
    
    inBufferList.mBuffers[0].mDataByteSize = ori_s;
    inBufferList.mBuffers[0].mData = ori_p;
    memset(audioInData, 0, sizeof(uint8_t) * (2048 + 1));
    if(NULL != data_pos && remain > 0) {
        memcpy(audioInData, data_pos, remain);
        remainSize = remain;
    }
    
    //////////////////////
    
    *aacLen = outBufferList.mBuffers[0].mDataByteSize; //设置编码后的AAC大小
    CFRelease(blockBuffer);
    return YES;
}
-(AudioClassDescription*)getAudioClassDescriptionWithType:(UInt32)type fromManufacturer:(UInt32)manufacturer { // 获得相应的编码器
    static AudioClassDescription audioDesc;
    
    UInt32 encoderSpecifier = type, size = 0;
    OSStatus status;
    
    memset(&audioDesc, 0, sizeof(audioDesc));
    status = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size);
    if (status)
    {
        return nil;
    }
    
    uint32_t count = size / sizeof(AudioClassDescription);
    AudioClassDescription descs[count];
    status = AudioFormatGetProperty(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size, descs);
    for (uint32_t i = 0; i < count; i++)
    {
        if ((type == descs[i].mSubType) && (manufacturer == descs[i].mManufacturer))
        {
            memcpy(&audioDesc, &descs[i], sizeof(audioDesc));
            break;
        }
    }
    return &audioDesc;
}
OSStatus inputDataProc(AudioConverterRef inConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData,AudioStreamPacketDescription **outDataPacketDescription, void *inUserData) { //<span style="font-family: Arial, Helvetica, sans-serif;">AudioConverterFillComplexBuffer 编码过程中，会要求这个函数来填充输入数据，也就是原始PCM数据</span>
    AudioBufferList bufferList = *(AudioBufferList*)inUserData;
    ioData->mBuffers[0].mNumberChannels = 1;
    ioData->mBuffers[0].mData           = bufferList.mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize   = bufferList.mBuffers[0].mDataByteSize;
    return noErr;
}
#endif

//
//#pragma mark - IAAVWriteEngineDelegate methods
//
//- (void)writerCoordinatorDidFinishPreparing:(IAAVWriteEngine *)coordinator
//{
//    @synchronized(self)
//    {
//        if(_recordingStatus != RecordingStatusStartingRecording){
//            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Expected to be in StartingRecording state" userInfo:nil];
//            return;
//        }
//        [self transitionToRecordingStatus:RecordingStatusRecording error:nil];
//    }
//}
//
//- (void)writerCoordinator:(IAAVWriteEngine *)recorder didFailWithError:(NSError *)error
//{
//    @synchronized( self ) {
//        self.avWriterEngine = nil;
//        [self transitionToRecordingStatus:RecordingStatusIdle error:error];
//    }
//}
//
//- (void)writerCoordinatorDidFinishRecording:(IAAVWriteEngine *)coordinator
//{
//    @synchronized( self )
//    {
//        if ( _recordingStatus != RecordingStatusStoppingRecording ) {
//            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Expected to be in StoppingRecording state" userInfo:nil];
//            return;
//        }
//        // No state transition, we are still in the process of stopping.
//        // We will be stopped once we save to the assets library.
//    }
//
//    self.avWriterEngine = nil;
//
//    @synchronized( self ) {
//        [self transitionToRecordingStatus:RecordingStatusIdle error:nil];
//    }
//}


#pragma mark - Recording State Machine

// call under @synchonized( self )
//- (void)transitionToRecordingStatus:(RecordingStatus)newStatus error:(NSError *)error
//{
//    RecordingStatus oldStatus = _recordingStatus;
//    _recordingStatus = newStatus;
//
//    if (newStatus != oldStatus){
//        if (error && (newStatus == RecordingStatusIdle)){
//            dispatch_async( dispatch_get_main_queue(), ^{
//                @autoreleasepool
//                {
//                    [self.delegate coordinator:self didFinishRecordingToOutputFileURL:_recordingURL error:nil];
//                }
//            });
//        } else {
//            error = nil; // only the above delegate method takes an error
//            if (oldStatus == RecordingStatusStartingRecording && newStatus == RecordingStatusRecording){
//                dispatch_async( dispatch_get_main_queue(), ^{
//                    @autoreleasepool
//                    {
//                        [self.delegate coordinatorDidBeginRecording:self];
//                    }
//                });
//            } else if (oldStatus == RecordingStatusStoppingRecording && newStatus == RecordingStatusIdle) {
//                dispatch_async( dispatch_get_main_queue(), ^{
//                    @autoreleasepool
//                    {
//                        [self.delegate coordinator:self didFinishRecordingToOutputFileURL:_recordingURL error:nil];
//                    }
//                });
//            }
//        }
//    }
//}

#pragma videoEncodedDataModel

-(IAMediaDataModel*)videoEncodedDataModel{
    
    [self.videolock lock];
    NSInteger arrayCount = [self.videoEncodedArray count];
    if (arrayCount>0) {
        IAMediaDataModel* encodedDataModel = [self.videoEncodedArray objectAtIndex:0];
        [self.videolock unlock];
        return encodedDataModel;
    }
    [self.videolock unlock];
    return nil;
}

-(IAMediaDataModel*)lastVideoEncodedDataModel{
    
    [self.videolock lock];
    NSInteger arrayCount = [self.videoEncodedArray count];
    if (arrayCount>0) {
        IAMediaDataModel* encodedDataModel = [self.videoEncodedArray objectAtIndex:(arrayCount-1)];
        [self.videolock unlock];
        return encodedDataModel;
    }
    [self.videolock unlock];
    return nil;
}


-(void)removeVideoEncodedData:(IAMediaDataModel*)encodedModel{
    
    [self.videolock lock];
    
    if ([self.videoEncodedArray containsObject:encodedModel]) {
        [self.videoEncodedArray removeObject:encodedModel];
    }
    
    [self.videolock unlock];
}

#pragma audioData

-(IAMediaDataModel*)audioEncodedDataModel{
    
    [self.audiolock lock];
    NSInteger arrayCount = [self.audioEncodedArray count];
    if (arrayCount>0) {
        IAMediaDataModel* encodedDataModel = [self.audioEncodedArray objectAtIndex:0];
        [self.audiolock unlock];
        return encodedDataModel;
    }
    [self.audiolock unlock];
    return nil;
}

-(IAMediaDataModel*)lastAudioEncodedDataModel{
    
    [self.audiolock lock];
    NSInteger arrayCount = [self.audioEncodedArray count];
    if (arrayCount>0) {
        IAMediaDataModel* encodedDataModel = [self.audioEncodedArray objectAtIndex:(arrayCount-1)];
        [self.audiolock unlock];
        return encodedDataModel;
    }
    [self.audiolock unlock];
    return nil;
}

-(void)removeAudioEncodedData:(IAMediaDataModel*)encodedModel{
    [self.audiolock lock];
    if ([self.audioEncodedArray containsObject:encodedModel]) {
        [self.audioEncodedArray removeObject:encodedModel];
    }
    [self.audiolock unlock];
}

-(void)setVolumeEngine:(NSInteger)volume{
    if(volume > 0)
        self.needMuted = NO;
    else
        self.needMuted = YES;
}

#pragma Lazy_loading



-(NSMutableArray*)audioEncodedArray{
    if (!_audioEncodedArray) {
        _audioEncodedArray = [[NSMutableArray alloc] init];
    }
    return _audioEncodedArray;
}

-(NSMutableArray*)videoEncodedArray{
    
    if (!_videoEncodedArray) {
        _videoEncodedArray = [[NSMutableArray alloc] init];
    }
    return _videoEncodedArray;
}


-(NSMutableArray*)videoTimeStampArray{
    if (!_videoTimeStampArray) {
        _videoTimeStampArray = [[NSMutableArray alloc] init];
    }
    return _videoTimeStampArray;
}

-(NSMutableArray*)audioTimeStampArray{
    if (!_audioTimeStampArray) {
        _audioTimeStampArray = [[NSMutableArray alloc] init];
    }
    return _audioTimeStampArray;
}



-(int) openFileMuxer:(const char*)output{
    
//    if (!self.needfullcourtRecord) return -1;
    
    int nRC = 0;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithUTF8String:output]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithUTF8String:output] error:nil];
    }
    
    self.fileMuxer = [[FileMuxer alloc] initFileMuxer];
    if (NULL == self.fileMuxer) return -1;
        
    nRC = [self.fileMuxer FileMuxerSetAudioParameter:AV_CODEC_ID_AAC birtate:61440 samplerate:44100 samplebit:16 channels:1];
    if(0 > nRC)return nRC;
    
    int width = 540, height = 960;
    if(IA_720P == self.definition){
        width = 720;
        height = 1280;
    }
    nRC = [self.fileMuxer FileMuxerSetVideoParameter:AV_CODEC_ID_H264 birtate:512000 width:width height:height fps:25.0 gopsize:50];
    nRC = [self.fileMuxer FileMuxerOpenFilePath:output];
    if(0 > nRC)return nRC;
    
    return nRC;
}

-(void)clostFileMuxer{
    if(NULL != self.fileMuxer) {
        [self.fileMuxer FileMuxerClose];
        self.fileMuxer = NULL;
    }
}

- (NSInteger)startWonderfullClip:(NSString*)filePath{
    
    if (self.isWonderfullClipping) return  -1;
    int nRC = 0;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    
    self.wnderfullClipMuxer = [[FileMuxer alloc] initFileMuxer];
    if (NULL == self.wnderfullClipMuxer) return -1;
    
    nRC = [self.wnderfullClipMuxer FileMuxerSetAudioParameter:AV_CODEC_ID_AAC birtate:61440 samplerate:44100 samplebit:16 channels:1];
    if(0 > nRC)return nRC;
    
    int width = 540, height = 960;
    if(IA_720P == self.definition){
        width = 720;
        height = 1280;
    }
    nRC = [self.wnderfullClipMuxer FileMuxerSetVideoParameter:AV_CODEC_ID_H264 birtate:512000 width:width height:height fps:25.0 gopsize:50];
    nRC = [self.wnderfullClipMuxer FileMuxerOpenFilePath:[filePath UTF8String]];
    if(0 > nRC){
        if(NULL != self.wnderfullClipMuxer) {
            [self.wnderfullClipMuxer FileMuxerClose];
            self.wnderfullClipMuxer = NULL;
        }
        return nRC;
    }
    self.isWonderfullClipping = YES;
    return nRC;
}

- (void)endWonderfullClip{
    self.isWonderfullClipping = NO;
    if(NULL != self.wnderfullClipMuxer) {
        [self.wnderfullClipMuxer FileMuxerClose];
        self.wnderfullClipMuxer = NULL;
    }
}

@end

