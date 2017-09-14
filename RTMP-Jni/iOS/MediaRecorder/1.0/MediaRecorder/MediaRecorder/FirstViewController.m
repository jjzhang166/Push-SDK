//
//  FirstViewController.m
//  MediaRecorder
//
//  Created by world on 16/1/6.
//  Copyright © 2016年 Derek Lix. All rights reserved.
//

#import "FirstViewController.h"
#import "HuitiRtmp.h"
#import <VideoToolbox/VideoToolbox.h>
#import "IAAudioCaptureEngine.h"
#import "IAMediaDataModel.h"
#import "AFNetworking.h"

#define  VideoRawArray_Max          30
#define  VideoEncodedDataArray_Max  30
#define  WIDTH [UIScreen mainScreen].bounds.size.width
#define  HEIGHT [UIScreen mainScreen].bounds.size.height

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]



@interface FirstViewController ()<IAAudioCaptureEngineDelegate,UITextFieldDelegate,UIAlertViewDelegate>
{
    NSString *h264File;
    NSFileHandle *fileHandle;
    NSFileHandle *readHandle;
    IAAudioCaptureEngine*  audioEngine;
}

@property (nonatomic,strong)H264HwEncoderImpl *h264Encoder;
@property (nonatomic,strong)AVCaptureSession *captureSession;
@property (nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic,strong)AVCaptureConnection *connection;

@property (nonatomic, strong) AVSampleBufferDisplayLayer *videoLayer;
@property (nonatomic, assign) int spsSize;
@property (nonatomic, assign) int ppsSize;

@property (strong, nonatomic)NSString* definition;
@property (strong, nonatomic)NSThread*        rtmpSendThread;

@property(nonatomic,strong)NSMutableArray* videoRawArray;
@property(nonatomic,strong)NSMutableArray* videoEncodedArray;
@property(nonatomic, assign)BOOL isRunning;

@property (assign, nonatomic)BOOL    hasPPSSended;
@property (assign, nonatomic)NSTimeInterval   startVideoTimeInterval;
@property (assign, nonatomic)NSTimeInterval   startAudioTimeInterval;

@property (strong, nonatomic)NSString* resolution;
@property (strong, nonatomic)NSTimer *timer;
@property (strong, nonatomic)NSTimer *countTimer;
@property (assign, nonatomic)NSInteger pastSeconds;
@property (strong, nonatomic)UIButton *beginButton;
@property (strong, nonatomic)UIView *endImageView;
@property (assign, nonatomic)BOOL flowFail;
@property (assign, nonatomic)BOOL isPushing;
@property (strong, nonatomic)NSString* pushUrl;
@property (strong, nonatomic)NSString* gameId;
@property (strong, nonatomic)NSString* token;
@property (strong, nonatomic)NSString* uid;
@property (strong, nonatomic)NSString* env;
@end

#define IA_RtmpField_UrlKey   @"IA_RtmpField_UrlKey"
#define IA_DefaultRtmpUrl     @"rtmp://wsvideopush.smartcourt.cn/prod/7d12c1e4-dbb8-45a7-afda-86822e72ee7a"
//@"rtmp://wsvideopull.smartcourt.cn/prod/dai123"


@implementation FirstViewController


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.view bringSubviewToFront:_beginButton];
    [self.view bringSubviewToFront:_endImageView];
  
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
}

-(void) viewDidDisappear:(BOOL)animated
{
  [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
}

-(void)startRecord{
    self.isRunning = YES;
    self.hasPPSSended = NO;
    [self setRtmp];
    [self startMic];
    self.startVideoTimeInterval = 0;
    self.startAudioTimeInterval = [NSDate timeIntervalSinceReferenceDate];
    [self.view bringSubviewToFront:_endImageView];

}

-(void)stopRecord{
    self.isRunning = NO;
    if (self.rtmpSendThread) {
        [self.rtmpSendThread cancel];
    }
    [self.h264Encoder End];
    [self stopCamera];
    [self stopMic];
    [self closeRtmp];
    
}
-(void)closeRtmp{
    
    rtmpDisconnect();
}
-(void)circula
{
    if (!self.uid||!self.gameId) {
        return;
    }
    
    NSDictionary *paramDic=@{@"head":@{@"version":@"2.1.1",@"appId":@"5000000",@"accessToken":self.token,@"extentions":@[],@"uid":self.uid},@"body":@{@"versionNo":@"0",@"gameId":self.gameId}};
    NSString *requestUrl = [NSString stringWithFormat:@"http://gpgame%@.api.smartcourt.cn/QueryGameData/getGameStatus",self.env];
    NSURL *URL = [NSURL URLWithString:requestUrl];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
  

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:6];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[self dataWithDict:paramDic]];
    
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
            _flowFail=YES;
        } else {
            NSDictionary *dic=responseObject;
            NSLog(@"%@",responseObject);
            UILabel *label=(UILabel *)[self.view viewWithTag:101];
            long errCode = [dic[@"code"] integerValue];
            NSDictionary *dataDic=dic[@"data"];
          
           if(errCode == 0){
            //查询成功的情况
            if ([dataDic[@"status"]isEqualToString:@"0"]) {
              label.text=@"直播未开始";
            }else if ([dataDic[@"status"]isEqualToString:@"1"])
            {
              label.text=@"直播进行中";
            }else if ([dataDic[@"status"]isEqualToString:@"2"])
            {
              label.text=@"直播已结束";
            }else if ([dataDic[@"status"]isEqualToString:@"3"])
            {
              label.text=@"直播已结束";
            }else
            {
              label.text=@"直播进行中";
            }
            _flowFail=NO;
          }else{
            NSString *msg = @"查询直播状态失败";
            if (errCode ==799) {
              msg = @"该用户已经在其他设备登陆！";
            }
            [self doBeforeCloseView];
            UIAlertView *alert=[[UIAlertView alloc]initWithTitle:nil message:msg delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
            [alert show];
          }
        
        }
    }];
    [dataTask resume];
   

  
}
- (NSData*)dataWithDict:(NSDictionary *)dict
{
    NSData *data=nil;
    if (dict) {
        NSError* error ;
        @try {
            data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
        }
        @catch (NSException *exception) {
            
        }
        @finally {
            
        }
        
    }
    return data;
}




-(void)beginFlow:(UIButton *)button
{
    if (!button.selected) {
         _beginButton.backgroundColor=[UIColor colorWithRed:1 green:0 blue:0 alpha:0.8];
         button.selected=!button.selected;
         self.isPushing = YES;
        _beginButton.layer.borderWidth=1;
        _beginButton.layer.borderColor=UIColorFromRGB(0x000000).CGColor;
        [self.view bringSubviewToFront:_beginButton];
        [self startRecord];
       
        _countTimer=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countSecond) userInfo:nil repeats:YES];;
        [_countTimer setFireDate:[NSDate distantPast]];
       
        if (_flowFail) {
            [self showViewInfo];
        }

        
    }else if (button.selected) {
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:nil message:@"确定要结束推流?" delegate:self cancelButtonTitle:nil otherButtonTitles:@"取消",@"确定", nil];
        
        [alert show];

    }
    
    
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *msg =  alertView.message;
  
  if([msg isEqualToString:@"确定要结束推流?"]){
    if (buttonIndex==1) {
      [self doBeforeCloseView];
    }
  }
  [self dismissViewControllerAnimated:true completion:nil];
  [self.delegate stopLiveRecord];
  
}

-(void)doBeforeCloseView
{
    NSLog(@"doBeforeCloseView");
  _beginButton.backgroundColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
   
  _beginButton.selected=NO;
  [_countTimer invalidate];
  [_timer invalidate];
  _beginButton.layer.borderColor=UIColorFromRGB(0x0080ff).CGColor;
  [self stopRecord];
}

-(void)countSecond
{
    UILabel *label=(UILabel *)[self.view viewWithTag:100];
    _pastSeconds++;
    NSInteger hour=_pastSeconds/3600;
    NSInteger min=_pastSeconds%3600/60;
    NSInteger sec=_pastSeconds%60;
    NSString *hours=[NSString stringWithFormat:@"%ld",hour];
    NSString *mins=[NSString stringWithFormat:@"%ld",min];
    NSString *secs=[NSString stringWithFormat:@"%ld",sec];
    if (hour<=0) {
        hours=[NSString stringWithFormat:@"0%@",hours];
    }
    
    if (min<=9) {
         mins=[NSString stringWithFormat:@"0%@",mins];
    }
    if (sec<=9) {
        secs=[NSString stringWithFormat:@"0%@",secs];
    }
   
    label.text=[NSString stringWithFormat:@"%@:%@:%@",hours,mins,secs];
    NSLog(@"%ld",_pastSeconds);
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    //默认码率
    self.definition = @"1.5M";
    //默认分别率
    self.resolution = @"720p";
  
    self.isPushing = NO;
    
    [self createH264Encoder];
    [self startCamera];
    
    _timer=[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(circula) userInfo:nil repeats:YES];
    [_timer setFireDate:[NSDate distantPast]];
   
    _pastSeconds=0;
    _beginButton=[[UIButton alloc]initWithFrame:CGRectMake(WIDTH-75, (HEIGHT-60)/2, 60, 60)];
    _beginButton.backgroundColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    _beginButton.layer.borderWidth=1;
    _beginButton.layer.borderColor=UIColorFromRGB(0x0080ff).CGColor;
    _beginButton.layer.cornerRadius=30;
    _beginButton.layer.masksToBounds=YES;
    [_beginButton setTitle:@"开始\n推流" forState:UIControlStateNormal];
    [_beginButton setTitle:@"结束\n推流" forState:UIControlStateSelected];
    _beginButton.titleLabel.font=[UIFont fontWithName:@"Helvetica-Bold" size:15];
    _beginButton.titleLabel.numberOfLines=2;
    [_beginButton addTarget:self action:@selector(beginFlow:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_beginButton];
    [self showTopView];
    
    
    UITapGestureRecognizer*  tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doTapGesture:)];
    [self.view addGestureRecognizer:tapGesture];
    
    NSString* rtmpUrlStr = [[NSUserDefaults standardUserDefaults] objectForKey:IA_RtmpField_UrlKey];
   
    
    [[NSUserDefaults standardUserDefaults] setObject:rtmpUrlStr forKey:IA_RtmpField_UrlKey];
    [self startRtmpSendThread];
}

-(void)doTapGesture:(UIGestureRecognizer*)gesture{
    
   
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
           // [self removeEncodedData:mediaModel];
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


- (void)startCamera {
    // 指定输入设备
    NSError *deviceError;
    AVCaptureDevice *cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevice error:&deviceError];
    
    //  cameraDevice.activeVideoMinFrameDuration = CMTimeMake(1, 15);
    // 指定输出设备
    AVCaptureVideoDataOutput *outputDevice = [[AVCaptureVideoDataOutput alloc] init];
    
    
    NSString *key = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    outputDevice.videoSettings = videoSettings;
    [outputDevice setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    outputDevice.minFrameDuration = CMTimeMake(1, 25);
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


- (void)orientationChanged:(id)notification
{
    [self setRelativeVideoOrientation];
}


-(void)startMic{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    h264File = [documentsDirectory stringByAppendingPathComponent:@"testaudio.aac"];
    [fileManager removeItemAtPath:h264File error:nil];
    [fileManager createFileAtPath:h264File contents:nil attributes:nil];
    fileHandle = [NSFileHandle fileHandleForWritingAtPath:h264File];
    
    audioEngine = [[IAAudioCaptureEngine alloc] init];
    audioEngine.delegate = self;
    [audioEngine open];
    
}

-(void)stopMic{
    
    [audioEngine close];
    [fileHandle synchronizeFile];
}

-(void)setRtmpUrl:(NSString*)pushUrl gameId:(NSString*)gameId token:(NSString*)token uid:(NSString*)uid env:(NSString*) env{
    
    self.pushUrl = pushUrl;
    self.gameId = gameId;
    self.token = token;
    self.uid = uid;
    self.env = env;
}


- (void)setRtmp {
    
  NSString* rtmpUrl =  self.pushUrl;
    if (!rtmpUrl || ([rtmpUrl length]<=0)) {
        rtmpUrl = @"rtmp://wsvideopull.smartcourt.cn/prod/dai123";
    }
    const char*  url = [rtmpUrl UTF8String];
    // const char *url = "rtmp://wsvideopull.smartcourt.cn/prod/dai123";
    NSLog(@"urllll :%s",url);
    rtmpConnect(url);
    rtmpSetVideoInfo(1280, 720, 15);
    rtmpSetAudioInfo(1, 44100, 16);
    
}

- (void)stopCamera {
    self.isPushing = NO;
    [self.captureSession stopRunning];
    [self.previewLayer removeFromSuperlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)createH264Encoder {
    
    if (self.h264Encoder) {
        [self.h264Encoder End];
    }
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

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (self.isPushing) {
        [self.h264Encoder encode:sampleBuffer];
    }
    
    
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
    //    NSLog(@"spspps");
    
    if (self.hasPPSSended) {
        return;
    }else{
        self.hasPPSSended = YES;
    }
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    
    NSMutableData* mutableSPSData = [NSMutableData dataWithData:ByteHeader];
    [mutableSPSData appendData:sps];
    
    NSMutableData* mutablePPSData = [NSMutableData dataWithData:ByteHeader];
    [mutablePPSData appendData:pps];
    
    rtmpSend((uint8_t *)[mutableSPSData bytes], (int)mutableSPSData.length, 1, 0);
    rtmpSend((uint8_t *)[mutablePPSData bytes], (int)mutablePPSData.length, 1, 0);
    
    return;
    
    [fileHandle writeData:ByteHeader];
    [fileHandle writeData:sps];
    [fileHandle writeData:ByteHeader];
    [fileHandle writeData:pps];
    
}

//rtmpSend(uint8_t *pBuffer, int bufLen, int type, int64_t timestamp);

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
    
    rtmpSend((uint8_t *)[mutableData bytes], (int)mutableData.length, 1,offsetInterval);
    
    
    
    return;
    
    
    
    
    //    const char bytes[] = "\x00\x00\x00\x01";
    //    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
    //    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    //
    //    NSMutableData* mutableData = [NSMutableData dataWithData:ByteHeader];
    //    [mutableData appendData:aData];
    //
    //    rtmpSend((uint8_t *)[mutableData bytes], (int)mutableData.length, 1, duration);
    //    timeDuration+=40000;
    //
    //    return;
    
    if (fileHandle != NULL)
    {
        [fileHandle writeData:ByteHeader];
        [fileHandle writeData:aData];
    }
    
}

#pragma

- (void)gotAudioEncodedData:(NSData*)aData len:(long long)len timeDuration:(long long)duration{
    
    IAMediaDataModel*  audioModel = [[IAMediaDataModel alloc] init];
    audioModel.data = aData;
    audioModel.size = len;
    audioModel.timestamp = duration;
    
    rtmpSend((uint8_t *)[aData bytes], (int)aData.length, 0, duration);
    
    return;
    
    if (fileHandle != NULL)
    {
        [fileHandle writeData:aData];
    }
    
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
-(void)showViewInfo
{
    UILabel *label=[[UILabel alloc]initWithFrame:CGRectMake((WIDTH-150)/2, (HEIGHT-34)/2, 150, 34)];
    label.text=@"推流失败";
    label.backgroundColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    label.textAlignment=NSTextAlignmentCenter;
    label.font=[UIFont systemFontOfSize:16];
    label.textColor=[UIColor whiteColor];
    label.layer.masksToBounds=YES;
    label.layer.cornerRadius=5;
    [self.view addSubview:label];
    [self performSelector:@selector(removeShowView:) withObject:label afterDelay:2];
    
}

-(void)removeShowView:(UILabel *)label
{
    
    [label removeFromSuperview];
}
-(void)showTopView
{
    _endImageView=[[UIImageView alloc]initWithFrame:CGRectMake((WIDTH-180)/2, 35, 180, 24)];
    _endImageView.backgroundColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    UIImageView *lineImage=[[UIImageView alloc]initWithFrame:CGRectMake(90, 5, 0.5, 15)];
    lineImage.backgroundColor=UIColorFromRGB(0x555555);
    [_endImageView addSubview:lineImage];
    _endImageView.layer.masksToBounds=YES;
    _endImageView.layer.cornerRadius=6;
    NSArray *textArray=@[@"00:00:00",@"...."];
    for (int i=0; i<2; ++i) {
        UILabel *label=[[UILabel alloc]initWithFrame:CGRectMake(15+90*i, 0, 60, 24)];
        label.text=[textArray objectAtIndex:i];
        label.textAlignment=NSTextAlignmentCenter;
        label.font=[UIFont systemFontOfSize:12];
        label.textColor=[UIColor whiteColor];
       
        label.tag=100+i;
        [_endImageView addSubview:label];
    }
    
    [self.view addSubview:_endImageView];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
  return  UIInterfaceOrientationMaskLandscapeRight;
}

@end
