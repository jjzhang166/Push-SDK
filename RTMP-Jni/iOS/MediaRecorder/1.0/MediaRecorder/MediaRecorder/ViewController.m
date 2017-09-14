//
//  ViewController.m
//  MediaRecorder
//
//  Created by 晖王 on 15/12/8.
//  Copyright © 2015年 晖王. All rights reserved.
//

#import "ViewController.h"
#import "HuitiRtmp.h"
#import <VideoToolbox/VideoToolbox.h>
#import "IAAudioCaptureEngine.h"
#import "IAMediaDataModel.h"

#define  VideoRawArray_Max          30
#define  VideoEncodedDataArray_Max  30

@interface ViewController ()<IAAudioCaptureEngineDelegate,UITextFieldDelegate>
{
    NSString *h264File;
    NSFileHandle *fileHandle;
    NSFileHandle *readHandle;
    NSFileHandle* audioFileHandle;
    IAAudioCaptureEngine*  audioEngine;
}
@property (nonatomic,strong)H264HwEncoderImpl *h264Encoder;
@property (nonatomic,strong)AVCaptureSession *captureSession;
@property (nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic,strong)AVCaptureConnection *connection;

@property (nonatomic, strong) AVSampleBufferDisplayLayer *videoLayer;
@property (nonatomic, assign) int spsSize;
@property (nonatomic, assign) int ppsSize;

@property (weak, nonatomic) IBOutlet UIButton *startRecordButton;
@property (weak, nonatomic) IBOutlet UIButton *stopRecordButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *definitionSWitch;

@property (strong, nonatomic)NSString* definition;
@property (strong, nonatomic)NSThread*        rtmpSendThread;

@property(nonatomic,strong)NSMutableArray* videoRawArray;
@property(nonatomic,strong)NSMutableArray* videoEncodedArray;
@property(nonatomic, assign)BOOL isRunning;
@property (weak, nonatomic) IBOutlet UITextField *rtmpUrl;
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;
@property (assign, nonatomic)BOOL    hasPPSSended;
@property (assign, nonatomic)NSTimeInterval   startVideoTimeInterval;
@property (assign, nonatomic)NSTimeInterval   startAudioTimeInterval;
@property (weak, nonatomic) IBOutlet UISegmentedControl *resolutionSwitch;
@property (strong, nonatomic)NSString* resolution;
@property (strong,nonatomic)NSData*    lastPPS;
@property (strong,nonatomic)NSData*    lastSPS;


@end


#define IA_RtmpField_UrlKey   @"IA_RtmpField_UrlKey"

//#define IA_DefaultRtmpUrl     @"rtmp://wsvideopush.smartcourt.cn/prod/7d12c1e4-dbb8-45a7-afda-86822e72ee7a"
#define IA_DefaultRtmpUrl     @"rtmp://wsvideopush.smartcourt.cn/prod/eoollo"


NSString * const naluTypesStrings[] =
{
    @"0: Unspecified (non-VCL)",
    @"1: Coded slice of a non-IDR picture (VCL)",    // P frame
    @"2: Coded slice data partition A (VCL)",
    @"3: Coded slice data partition B (VCL)",
    @"4: Coded slice data partition C (VCL)",
    @"5: Coded slice of an IDR picture (VCL)",      // I frame
    @"6: Supplemental enhancement information (SEI) (non-VCL)",
    @"7: Sequence parameter set (non-VCL)",         // SPS parameter
    @"8: Picture parameter set (non-VCL)",          // PPS parameter
    @"9: Access unit delimiter (non-VCL)",
    @"10: End of sequence (non-VCL)",
    @"11: End of stream (non-VCL)",
    @"12: Filler data (non-VCL)",
    @"13: Sequence parameter set extension (non-VCL)",
    @"14: Prefix NAL unit (non-VCL)",
    @"15: Subset sequence parameter set (non-VCL)",
    @"16: Reserved (non-VCL)",
    @"17: Reserved (non-VCL)",
    @"18: Reserved (non-VCL)",
    @"19: Coded slice of an auxiliary coded picture without partitioning (non-VCL)",
    @"20: Coded slice extension (non-VCL)",
    @"21: Coded slice extension for depth view components (non-VCL)",
    @"22: Reserved (non-VCL)",
    @"23: Reserved (non-VCL)",
    @"24: STAP-A Single-time aggregation packet (non-VCL)",
    @"25: STAP-B Single-time aggregation packet (non-VCL)",
    @"26: MTAP16 Multi-time aggregation packet (non-VCL)",
    @"27: MTAP24 Multi-time aggregation packet (non-VCL)",
    @"28: FU-A Fragmentation unit (non-VCL)",
    @"29: FU-B Fragmentation unit (non-VCL)",
    @"30: Unspecified (non-VCL)",
    @"31: Unspecified (non-VCL)",
};

@implementation ViewController
- (IBAction)startRecord:(id)sender {
    
    if (!self.isRunning) {
        [self startRecord];
    }else{
        UIAlertView* alert =[[UIAlertView alloc] initWithTitle:@"提示" message:@"先关闭录制" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    }
}
- (IBAction)closeRecord:(id)sender {
    [self stopRecord];
}

- (IBAction)resolutionSwitchSender:(id)sender {
    
    NSInteger index = ((UISegmentedControl*)sender).selectedSegmentIndex;
    switch (index) {
        case 0:
            self.resolution = @"480p";
            break;
        case 1:
            self.resolution = @"540p";
            break;
        case 2:
            self.resolution = @"720p";
            break;
        default:
            break;
    }
}
- (IBAction)definitionSwitch:(id)sender {
    NSInteger index = ((UISegmentedControl*)sender).selectedSegmentIndex;
    switch (index) {
        case 0:
            self.definition = @"512";
            break;
        case 1:
            self.definition = @"768";
            break;
        case 2:
            self.definition = @"1M";
            break;
        case 3:
            self.definition = @"1.5M";
            break;
        case 4:
            self.definition = @"2M";
            break;
        default:
            break;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startRecord];
}

-(void)startRecord{
    self.isRunning = YES;
    self.hasPPSSended = NO;
    
    [self startCamera];
    [self startMic];
    [self setRtmp];
    self.startVideoTimeInterval = 0;
    self.startAudioTimeInterval = 0;
    
    [self performSelector:@selector(zViewIndex:) withObject:nil afterDelay:1.f];
}

-(void)stopRecord{
    self.isRunning = NO;
    if (self.rtmpSendThread) {
        [self.rtmpSendThread cancel];
    }
    
    [self stopCamera];
    [self stopMic];
    [self closeRtmp];
    
}
-(void)closeRtmp{
    
    rtmpDisconnect();
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer*  tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doTapGesture:)];
    [self.view addGestureRecognizer:tapGesture];
    
    NSString* rtmpUrlStr = [[NSUserDefaults standardUserDefaults] objectForKey:IA_RtmpField_UrlKey];
    if (!rtmpUrlStr||([rtmpUrlStr length]<=0)) {
        [self.rtmpUrl setText:IA_DefaultRtmpUrl];
    }else
        [self.rtmpUrl setText:rtmpUrlStr];
    
    [[NSUserDefaults standardUserDefaults] setObject:rtmpUrlStr forKey:IA_RtmpField_UrlKey];
    [self startRtmpSendThread];
    
    [self.definitionSWitch removeAllSegments];
    [self.definitionSWitch insertSegmentWithTitle:@"512" atIndex:0 animated:NO];
    [self.definitionSWitch insertSegmentWithTitle:@"768" atIndex:1 animated:NO];
    [self.definitionSWitch insertSegmentWithTitle:@"1M" atIndex:2 animated:NO];
    [self.definitionSWitch insertSegmentWithTitle:@"1.5M" atIndex:3 animated:NO];
    [self.definitionSWitch insertSegmentWithTitle:@"2M" atIndex:4 animated:NO];
    [self.definitionSWitch setSelectedSegmentIndex:3];
    
    self.definition = @"1.5M";
    
    [self.resolutionSwitch removeAllSegments];
    [self.resolutionSwitch insertSegmentWithTitle:@"480p" atIndex:0 animated:NO];
    [self.resolutionSwitch insertSegmentWithTitle:@"540p" atIndex:1 animated:NO];
    [self.resolutionSwitch insertSegmentWithTitle:@"720p" atIndex:2 animated:NO];
    [self.resolutionSwitch setSelectedSegmentIndex:1];
    self.resolution = @"720p";
    
    
    [self.startRecordButton setBackgroundColor:[UIColor grayColor]];
    [self.stopRecordButton setBackgroundColor:[UIColor grayColor]];

//    // create our AVSampleBufferDisplayLayer and add it to the view
//    _videoLayer = [[AVSampleBufferDisplayLayer alloc] init];
//    _videoLayer.frame = self.view.frame;
//    _videoLayer.bounds = self.view.bounds;
//    _videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    
//    // set Timebase, you may need this if you need to display frames at specific times
//    // I didn't need it so I haven't verified that the timebase is working
//    CMTimebaseRef controlTimebase;
//    CMTimebaseCreateWithMasterClock(CFAllocatorGetDefault(), CMClockGetHostTimeClock(), &controlTimebase);
//    //videoLayer.controlTimebase = controlTimebase;
//    CMTimebaseSetTime(self.videoLayer.controlTimebase, kCMTimeZero);
//    CMTimebaseSetRate(self.videoLayer.controlTimebase, 1.0);
//    [[self.view layer] addSublayer:_videoLayer];
    
    

}

-(void)doTapGesture:(UIGestureRecognizer*)gesture{
    
    [self.rtmpUrl resignFirstResponder];
}

-(void)zViewIndex:(id)sender{
    
    [self.view bringSubviewToFront:self.urlLabel];
    [self.view bringSubviewToFront:self.rtmpUrl];
    [self.view bringSubviewToFront:self.definitionSWitch];
    [self.view bringSubviewToFront:self.resolutionSwitch];
    [self.view bringSubviewToFront:self.startRecordButton];
    [self.view bringSubviewToFront:self.stopRecordButton];
    
}


-(void)startRtmpSendThread{
    
    return;

    if (self.rtmpSendThread) {
        [self.rtmpSendThread cancel];
    }
    
    self.rtmpSendThread = [[NSThread alloc] initWithTarget:self selector:@selector(rtmpSendThreadMain:) object:nil];
    [self.rtmpSendThread start];
}

-(BOOL)recursionVideoFunction{
    IAMediaDataModel* mediaModel = [self videoEncodedDataModel];
    if (mediaModel) {
        const char bytes[] = "\x00\x00\x00\x01";
        size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
        NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
        NSMutableData* mutableData = [NSMutableData dataWithData:ByteHeader];
        [mutableData appendData:mediaModel.data];
        
        if (rtmpSend((uint8_t *)[mutableData bytes], (int)mutableData.length, 1, mediaModel.timestamp)==0) {
            [self removeEncodedData:mediaModel];
            return YES;
        }
    }
    
    return NO;
    
}

-(void)recursionAudioFunction{
    
    IAMediaDataModel* mediaModel = [audioEngine audioEncodedDataModel];
    if (mediaModel) {
        if (rtmpSend((uint8_t *)[mediaModel.data bytes], (int)mediaModel.data.length, 0, mediaModel.timestamp)==0) {
            [audioEngine removeEncodedData:mediaModel];
            
        }
    }
}

-(void)rtmpSendThreadMain:(id)sender{
    
    while (1) {
        @autoreleasepool {
            //send video
            [self recursionVideoFunction];
            
            //send audio
            [self recursionAudioFunction];
        }
    }
    
}

static NSInteger  timeStamp = 0;

- (void)startCamera {

    // 指定输入设备
    NSError *deviceError;
    AVCaptureDevice *cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 指定输出设备
    AVCaptureVideoDataOutput *outputDevice = [[AVCaptureVideoDataOutput alloc] init];
    
    NSString *key = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
    outputDevice.alwaysDiscardsLateVideoFrames=YES;
   // NSDictionary *videoSettings =[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:25],AVVideoExpectedSourceFrameRateKey,value,key, nil];
    NSDictionary *videoSettings =[NSDictionary dictionaryWithObject:value forKey:key];
    outputDevice.videoSettings = videoSettings;
    [outputDevice setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    outputDevice.minFrameDuration = CMTimeMake(1, 25);
    
    
//    NSError* error;
//    [cameraDevice lockForConfiguration:&error];
//    cameraDevice.activeVideoMinFrameDuration = CMTimeMake(1, 1);
//    cameraDevice.activeVideoMaxFrameDuration = CMTimeMake(1, 1);
//    [cameraDevice unlockForConfiguration];
    
   // [self configureCameraForHighestFrameRate:cameraDevice];
    
//    CMTime time = CMTimeMake(1, 25);
//    [self configureCamera:cameraDevice withFrameRate:25];
//    [self setFrameRateWithDuration:time OnCaptureDevice:cameraDevice];

    AVCaptureDeviceInput *inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevice error:&deviceError];
    
    
    //将设备输入输出添加到会话中
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession addInput:inputDevice];
    [self.captureSession addOutput:outputDevice];
    [self.captureSession beginConfiguration];
    
    if ([self.resolution isEqualToString:@"480p"]) {
        [self.captureSession setSessionPreset:[NSString stringWithString:AVCaptureSessionPreset640x480]];
    }else if ([self.resolution isEqualToString:@"540p"]){
        [self.captureSession setSessionPreset:[NSString stringWithString:AVCaptureSessionPresetiFrame960x540]];
    }else if ([self.resolution isEqualToString:@"720p"]){
        [self.captureSession setSessionPreset:[NSString stringWithString:AVCaptureSessionPreset1280x720]];
    }else{
        [self.captureSession setSessionPreset:[NSString stringWithString:AVCaptureSessionPreset1280x720]];
    }
    
    
    self.connection = [outputDevice connectionWithMediaType:AVMediaTypeVideo];
    [self setRelativeVideoOrientation];
    self.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;


    
    NSNotificationCenter *notify = [NSNotificationCenter defaultCenter];
  //  [notify addObserver:self selector:@selector(statusBarOrientationDidChange:) name:@"StatusBarOrientationDidChange" object:nil];
  //  [notify addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    [self.captureSession commitConfiguration];
    
    ////device orient

    //创建预览层
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    self.previewLayer.frame = self.view.bounds;
    self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    [self.view.layer addSublayer:self.previewLayer];
    
    [self createH264Encoder];
    //开始
    [self.captureSession startRunning];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    h264File = [documentsDirectory stringByAppendingPathComponent:@"test.h264"];
    [fileManager removeItemAtPath:h264File error:nil];
    [fileManager createFileAtPath:h264File contents:nil attributes:nil];
    
    // Open the file using POSIX as this is anyway a test application
    //fd = open([h264File UTF8String], O_RDWR);
    fileHandle = [NSFileHandle fileHandleForWritingAtPath:h264File];
    
}

- (void)configureCameraForHighestFrameRate:(AVCaptureDevice *)device
{
    AVCaptureDeviceFormat *bestFormat = nil;
    AVFrameRateRange *bestFrameRateRange = nil;
    for ( AVCaptureDeviceFormat *format in [device formats] ) {
        for ( AVFrameRateRange *range in format.videoSupportedFrameRateRanges ) {
            if ( range.maxFrameRate > bestFrameRateRange.maxFrameRate ) {
                bestFormat = format;
                bestFrameRateRange = range;
            }
        }
    }
    if ( bestFormat ) {
        if ( [device lockForConfiguration:NULL] == YES ) {
            device.activeFormat = bestFormat;
            device.activeVideoMinFrameDuration = bestFrameRateRange.minFrameDuration;
            device.activeVideoMaxFrameDuration = bestFrameRateRange.minFrameDuration;
            [device unlockForConfiguration];
        }
    }
}

- (void)orientationChanged:(id)notification
{
    [self setRelativeVideoOrientation];
}


-(void)startMic{
    
    
 //   self.microphone = [EZMicrophone microphoneWithDelegate:self];
    
    
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    h264File = [documentsDirectory stringByAppendingPathComponent:@"testaudio.aac"];
    [fileManager removeItemAtPath:h264File error:nil];
    [fileManager createFileAtPath:h264File contents:nil attributes:nil];
    audioFileHandle = [NSFileHandle fileHandleForWritingAtPath:h264File];

    
    
    audioEngine = [[IAAudioCaptureEngine alloc] init];
    audioEngine.delegate = self;
    [audioEngine open];
    
}

-(void)stopMic{
    
    [audioEngine close];
    [audioFileHandle synchronizeFile];
}



- (void)setRtmp {
    
    NSString* rtmpUrl = self.rtmpUrl.text;
    if ([rtmpUrl length]<=0) {
     //   rtmpUrl = @"rtmp://wsvideopull.smartcourt.cn/prod/dai123";
        rtmpUrl = IA_DefaultRtmpUrl;
    }
    const char*  url = [rtmpUrl UTF8String];
    NSLog(@"urllll :%s",url);
    rtmpConnect(url);
    rtmpSetVideoInfo(1280, 720, 25);
    rtmpSetAudioInfo(1, 44100, 16);
    
}

- (void)stopCamera {
    [self.captureSession stopRunning];
    [self.previewLayer removeFromSuperlayer];
    [self.h264Encoder End];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)createH264Encoder {
    
    self.h264Encoder = [H264HwEncoderImpl alloc];
    self.h264Encoder.bitRate = self.definition;
    [self.h264Encoder initWithConfiguration];
    [self.h264Encoder initEncode:1280 height:720];
    self.h264Encoder.delegate = self;

}

- (void)statusBarOrientationDidChange:(NSNotification *)notification {
    [self setRelativeVideoOrientation];
}

//
- (void)setRelativeVideoOrientation {

    return;
    switch ([[UIDevice currentDevice] orientation]) {
        case UIInterfaceOrientationPortrait:
#if defined(__IPHONE_8_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
        case UIInterfaceOrientationUnknown:
#endif
            self.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            self.connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            self.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            self.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        default:
            break;
    }
}

static bool isFirst  = YES;
static NSTimeInterval  startTime;
static NSInteger   frameCount = 0;

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    frameCount++;
    if (isFirst) {
        startTime = [NSDate timeIntervalSinceReferenceDate];
        isFirst = NO;
    }else{
        NSTimeInterval currentInterval = [NSDate timeIntervalSinceReferenceDate];
        if (((currentInterval-startTime-1)>0)&&((currentInterval-startTime-1)<0.05)) {
            NSLog(@"isFirsttt  :%d",frameCount);
        }
    }
    
    [self.h264Encoder encode:sampleBuffer];
    
    return;

    if ([self.videoRawArray count]>=VideoRawArray_Max) {
        [self.videoRawArray removeAllObjects];
    }
    [self.videoRawArray addObject:(__bridge id _Nonnull)(sampleBuffer)];
    
    //if the _audioEncodedArray is full stop to encode
    if ([self.videoEncodedArray count]<VideoEncodedDataArray_Max) {
        
        //encode the raw data
        NSInteger  sampleIndex = [self.videoRawArray count]-1;
        CMSampleBufferRef cachedSample = (__bridge CMSampleBufferRef)([self.videoRawArray objectAtIndex:sampleIndex]);
        //encode
        [self.h264Encoder encode:cachedSample];
    }else{
        NSLog(@"fuuuull :%lu",(unsigned long)[self.videoEncodedArray count]);
        NSLog(@"rawwwww :%lu",(unsigned long)[self.videoRawArray count]);
    }
    
}

static long long  timeDuration = 0;

#pragma mark - H264Delegate

- (void)gotSpsPps:(NSData *)sps pps:(NSData *)pps {

    if (self.hasPPSSended) {
        self.lastPPS = pps;
        self.lastSPS = sps;
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
    
    rtmpSend((uint8_t *)[mutableSPSData bytes], (int)mutableSPSData.length, 1, 0);
    rtmpSend((uint8_t *)[mutablePPSData bytes], (int)mutablePPSData.length, 1, 0);
    
    
    
    NSString* fileName = [ViewController stringFromDate:[NSDate date] formatter:@"yyyy-MM-dd HH:mm:ss"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    h264File = [documentsDirectory stringByAppendingPathComponent:@"pps"];
    [fileManager removeItemAtPath:h264File error:nil];
    [fileManager createFileAtPath:h264File contents:nil attributes:nil];
    fileHandle = [NSFileHandle fileHandleForWritingAtPath:h264File];
    
    if (fileHandle != NULL)
    {
        [fileHandle writeData:ByteHeader];
         [fileHandle writeData:pps];
        [fileHandle writeData:sps];
        
    }
    
    return;
    
    [fileHandle writeData:ByteHeader];
    [fileHandle writeData:sps];
    [fileHandle writeData:ByteHeader];
    [fileHandle writeData:pps];
    
}

//rtmpSend(uint8_t *pBuffer, int bufLen, int type, int64_t timestamp);

static NSInteger fileIndex = 0;

+(NSString*)stringFromDate:(NSDate *)date formatter:(NSString*)formatter{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:formatter];
    NSString *destDateString = [dateFormatter stringFromDate:date];
    return destDateString;
    
}

- (void)gotEncodedData:(NSData*)aData isKeyFrame:(BOOL)isKeyFrame timeDuration:(long long)duration
{
    
//    const char bytes[] = "\x00\x00\x00\x01";
//    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
//    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
//    
//    NSMutableData* mutableData = [NSMutableData dataWithData:ByteHeader];
//    [mutableData appendData:aData];
//    
//    IAMediaDataModel* encodedAudioModel = [[IAMediaDataModel alloc] init];
//    encodedAudioModel.data = mutableData;
//    encodedAudioModel.size = [aData length];
//    encodedAudioModel.timestamp = duration;
//    [self.videoEncodedArray addObject:encodedAudioModel];
//    
//    NSLog(@"gotEncodedData arrryCount :%lu",(unsigned long)[self.videoEncodedArray count]);
    
    
    NSLog(@"isKeyyyframee  :%d",isKeyFrame);
    
    if (self.startVideoTimeInterval==0) {
        self.startVideoTimeInterval =[NSDate timeIntervalSinceReferenceDate];
    }
    NSTimeInterval currentTimeInterval = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval offsetInterval = currentTimeInterval-self.startVideoTimeInterval;
    offsetInterval=offsetInterval*1000*1000;
    
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    NSMutableData* mutableData = [NSMutableData dataWithData:ByteHeader];
    [mutableData appendData:aData];
    
//    NSMutableData* mutableData = nil;
//    if (self.lastSPS&&([self.lastSPS length]>0)) {
//        mutableData = [NSMutableData dataWithData:self.lastSPS];
//    }
//    if (self.lastPPS&&([self.lastPPS length]>0)) {
//        if (mutableData) {
//            [mutableData appendData:self.lastPPS];
//        }else{
//            mutableData = [NSMutableData dataWithData:self.lastPPS];
//        }
//    }
//    
//    if (mutableData) {
//        [mutableData appendData:ByteHeader];
//        [mutableData appendData:aData];
//    }else
//    {
//        mutableData = [NSMutableData dataWithData:ByteHeader];
//        [mutableData appendData:aData];
//    }
//    
//    self.lastPPS = nil;
//    self.lastSPS = nil;
    
    rtmpSend((uint8_t *)[mutableData bytes], (int)mutableData.length, 1,offsetInterval);

    
    return;
  

}

#pragma 

- (void)gotAudioEncodedData:(NSData*)aData len:(long long)len timeDuration:(long long)duration{
    
    IAMediaDataModel*  audioModel = [[IAMediaDataModel alloc] init];
    audioModel.data = aData;
    audioModel.size = len;
    audioModel.timestamp = duration;
    
    rtmpSend((uint8_t *)[aData bytes], (int)aData.length, 0, duration);
    
    
    if (audioFileHandle != NULL)
    {
        [audioFileHandle writeData:aData];
    }
    
}

- (void)configureCamera:(AVCaptureDevice *)device withFrameRate:(int)desiredFrameRate
{
    AVCaptureDeviceFormat *desiredFormat = nil;
    for ( AVCaptureDeviceFormat *format in [device formats] ) {
        for ( AVFrameRateRange *range in format.videoSupportedFrameRateRanges ) {
            if ( range.maxFrameRate >= desiredFrameRate && range.minFrameRate <= desiredFrameRate ) {
                desiredFormat = format;
                goto desiredFormatFound;
            }
        }
    }
    
desiredFormatFound:
    if ( desiredFormat ) {
        if ( [device lockForConfiguration:NULL] == YES ) {
            device.activeFormat = desiredFormat ;
            device.activeVideoMinFrameDuration = CMTimeMake ( 1, desiredFrameRate );
            device.activeVideoMaxFrameDuration = CMTimeMake ( 1, desiredFrameRate );
            [device unlockForConfiguration];
        }
    }
}



- (void)setFrameRateWithDuration:(CMTime)frameDuration OnCaptureDevice:(AVCaptureDevice *)device
{
    NSError *error;
    NSArray *supportedFrameRateRanges = [device.activeFormat videoSupportedFrameRateRanges];
    BOOL frameRateSupported = NO;
    for(AVFrameRateRange *range in supportedFrameRateRanges){
        if(CMTIME_COMPARE_INLINE(frameDuration, >=, range.minFrameDuration) && CMTIME_COMPARE_INLINE(frameDuration, <=, range.maxFrameDuration)){
            frameRateSupported = YES;
        }
    }
    
    if(frameRateSupported && [device lockForConfiguration:&error]){
        [device setActiveVideoMaxFrameDuration:frameDuration];
        [device setActiveVideoMinFrameDuration:frameDuration];
        [device unlockForConfiguration];
    }
}

- (BOOL)supportsVideoFrameRate:(NSInteger)videoFrameRate
{
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        NSArray *formats = [videoDevice formats];
        for (AVCaptureDeviceFormat *format in formats) {
            NSArray *videoSupportedFrameRateRanges = [format videoSupportedFrameRateRanges];
            for (AVFrameRateRange *frameRateRange in videoSupportedFrameRateRanges) {
                if ( (frameRateRange.minFrameRate <= videoFrameRate) && (videoFrameRate <= frameRateRange.maxFrameRate) ) {
                    return YES;
                }
            }
        }
        
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return NO;
//        AVCaptureConnection *connection = [_currentOutput connectionWithMediaType:AVMediaTypeVideo];
//        return (connection.isVideoMaxFrameDurationSupported && connection.isVideoMinFrameDurationSupported);
#pragma clang diagnostic pop
    }
    
    return NO;
}

//cache data

-(void)cacheEncodedAudioData:(IAMediaDataModel*)model{
    
}


-(IAMediaDataModel*)videoEncodedDataModel{
    
    NSInteger arrayCount = [self.videoEncodedArray count];
    
    if (arrayCount>0) {
        IAMediaDataModel* encodedDataModel = [self.videoEncodedArray objectAtIndex:(arrayCount-1)];
        return encodedDataModel;
    }
    return nil;
}

-(void)removeEncodedData:(IAMediaDataModel*)encodedModel{
    
    if ([self.videoEncodedArray containsObject:encodedModel]) {
        [self.videoEncodedArray removeObject:encodedModel];
    }
}



-(NSMutableArray*)videoRawArray{
    if (!_videoRawArray) {
        _videoRawArray = [[NSMutableArray alloc] init];
    }
    return _videoRawArray;
}

-(NSMutableArray*)videoEncodedArray{
    
    if (!_videoEncodedArray) {
        _videoEncodedArray = [[NSMutableArray alloc] init];
    }
    return _videoEncodedArray;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
