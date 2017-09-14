//
//  IAVideoCaptureEngine.m
//  MediaRecorder
//
//  Created by Derek Lix on 15/12/17.
//  Copyright © 2015年 Derek Lix. All rights reserved.
//

#import "IAVideoCaptureEngine.h"
#import <ImageIO/ImageIO.h>
#import "IAUtility.h"


static const NSString *AVCaptureStillImageIsCapturingStillImageContext = @"AVCaptureStillImageIsCapturingStillImageContext";

@interface IAVideoCaptureEngine ()

@property(nonatomic, strong)UIView* superView;
@property (nonatomic,strong)AVCaptureSession *captureSession;
@property (nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic,strong)AVCaptureConnection *connection;
@property (nonatomic, strong) AVSampleBufferDisplayLayer *videoLayer;
@property (assign, nonatomic)BOOL    hasPPSSended;
@property (assign, nonatomic)NSTimeInterval   startVideoTimeInterval;
@property (nonatomic,assign)PADefinition   defintion;
@property (nonatomic,strong)UIView*         flashView;
@property (nonatomic,assign)CGFloat effectiveScale;
@property (nonatomic,strong)AVCaptureDevice* cameraDevice;
@property (strong,nonatomic)NSTimer*      detechAuthorTimer;
@property (strong,nonatomic)IAVideoAuthorizationHandler  handler;
@property (strong,nonatomic)AVCaptureStillImageOutput* stillImageOutput;


@end





@implementation IAVideoCaptureEngine

-(id)initWithSuperView:(UIView*)superView outputSampleBufferDelegateObserver:(id)delegateObserver   authorizationHandler:(IAVideoAuthorizationHandler)handler{
    
    if (self = [super init]) {
        self.superView = superView;
        self.outputSampleBufferDelegateObserver = delegateObserver;
        self.defintion = IA_720P;
        self.handler = handler;
    }
    return self;
}

-(void)restartVideoWith:(PADefinition)definition{
    
    self.defintion = definition;
}

-(void)startVideoPreview{
    [self startCamera];
}

-(void)stopVideoCapture{
    
    self.outputSampleBufferDelegateObserver = nil;
    if (self.detechAuthorTimer) {
        [self.detechAuthorTimer invalidate];
        self.detechAuthorTimer = nil;
    }
    
    if (self.captureSession) {
        [self.captureSession stopRunning];
    }
    if (self.previewLayer) {
        [self.previewLayer removeFromSuperlayer];
    }
    
}

- (void)startCamera {
    // 指定输入设备
    NSError *deviceError;
    self.cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSLog(@"deveice format :%@",self.cameraDevice.formats);
    // 指定输出设备
    self.outputDevice = [[AVCaptureVideoDataOutput alloc] init];
    
    NSString *key = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
    self.outputDevice.alwaysDiscardsLateVideoFrames=YES;
    // NSDictionary *videoSettings =[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:25],AVVideoExpectedSourceFrameRateKey,value,key, nil];
    NSDictionary *videoSettings =[NSDictionary dictionaryWithObject:value forKey:key];
    self.outputDevice.videoSettings = videoSettings;
    [self.outputDevice setSampleBufferDelegate:self.outputSampleBufferDelegateObserver queue:dispatch_get_main_queue()];
    self.outputDevice.minFrameDuration = CMTimeMake(1, 25);
    
    AVCaptureDeviceInput *inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:self.cameraDevice error:&deviceError];
    
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus==AVAuthorizationStatusNotDetermined) {
        if (self.detechAuthorTimer) {
            [self.detechAuthorTimer invalidate];
            self.detechAuthorTimer = nil;
        }
        self.detechAuthorTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(detechAtuhorizationStatus) userInfo:nil repeats:YES];
    } else if (authStatus != AVAuthorizationStatusAuthorized) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:@"未检测到视频,无法开始直播,请检测手机麦克风" delegate:self cancelButtonTitle:@"确认" otherButtonTitles:nil, nil];
        [alert show];
    }
    
    //将设备输入输出添加到会话中
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession addInput:inputDevice];
    
    
    //    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    //    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    //    [self.stillImageOutput setOutputSettings:outputSettings];
    //    [self.captureSession addOutput:self.stillImageOutput];
    
    
    [self.captureSession addOutput:self.outputDevice];
    [self.captureSession beginConfiguration];
    
    //    if (self.defintion==IA_720P) {
    //        [self.captureSession setSessionPreset:[NSString stringWithString:AVCaptureSessionPreset1280x720]];//need configuration
    //    } else if (self.defintion==IA_540P){
    [self.captureSession setSessionPreset:[NSString stringWithString:AVCaptureSessionPresetiFrame960x540]];
    //    }
    
    self.connection = [self.outputDevice connectionWithMediaType:AVMediaTypeVideo];
    self.connection.videoOrientation = AVCaptureVideoOrientationPortrait;//AVCaptureVideoOrientationLandscapeRight;
    
    if ([self.connection isVideoStabilizationSupported])
    {
        NSLog(@"VideoStabilizationSupported! Curr val: %i", [self.connection isVideoStabilizationEnabled]);
        //        if ([self.connection isVideoStabilizationEnabled])
        {
            NSLog(@"enabling Video Stabilization!");
            self.connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeOff;
            NSLog(@"after: %i", [self.connection isVideoStabilizationEnabled]);
        }
    }
    
    
    [self.captureSession commitConfiguration];
    
    ////device orient
    
    //创建预览层
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    //    CGFloat width = [UIScreen mainScreen].bounds.size.height>[UIScreen mainScreen].bounds.size.width?[UIScreen mainScreen].bounds.size.height:[UIScreen mainScreen].bounds.size.width;
    //    CGFloat height = [UIScreen mainScreen].bounds.size.height<[UIScreen mainScreen].bounds.size.width?[UIScreen mainScreen].bounds.size.height:[UIScreen mainScreen].bounds.size.width;
    self.previewLayer.frame = self.superView.bounds;//CGRectMake(0, 0, width, height);
    //    self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    [self.superView.layer addSublayer:self.previewLayer];
    
    //开始
    [self.captureSession startRunning];
}

- (void)setCaptureVideoOrientation:(AVCaptureVideoOrientation)orientation
{
    self.connection.videoOrientation = orientation;
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position )
            return device;
    return nil;
}

- (void)switchCaptureDevicePosition
{
    NSArray *inputs = self.captureSession.inputs;
    for ( AVCaptureDeviceInput *input in inputs ) {
        AVCaptureDevice *device = input.device;
        if ( [device hasMediaType:AVMediaTypeVideo] ) {
            AVCaptureDevicePosition position = device.position;
            AVCaptureDevice *newCamera = [self cameraWithPosition:(position == AVCaptureDevicePositionFront? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront)];
            AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            
            // beginConfiguration ensures that pending changes are not applied immediately
            [self.captureSession beginConfiguration];
            [self.captureSession removeInput:input];
            [self.captureSession addInput:newInput];
            
            self.connection = [self.outputDevice connectionWithMediaType:AVMediaTypeVideo];
            self.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
            
            if ([self.connection isVideoStabilizationSupported]) {
                self.connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeOff;
            }
            
            // Changes take effect once the outermost commitConfiguration is invoked.
            [self.captureSession commitConfiguration];
            break;
        }
    }
}

- (void)setVideoScaleAndCropFactor:(CGFloat)factor
{
    if (!self.cameraDevice)
        return;
    
    NSLog(@"factor :%f",factor);
    NSError *error = nil;
    [self.cameraDevice lockForConfiguration:&error];
    
    CGFloat preFactor = [self.cameraDevice videoZoomFactor];
    CGFloat offset = fabsf(factor-preFactor);
    
    if (!error) {
        
        if (offset>=0.5) {
            NSInteger count = 100;
            CGFloat increaseValue = (factor-preFactor)/count;
            for (NSInteger num=0; num<count; num++) {
                preFactor+=increaseValue;
                preFactor = MIN(10.0f, preFactor);
                preFactor = MAX(1.0f, preFactor);
                CGFloat sleepValue = 20000/count;
                [self.cameraDevice setVideoZoomFactor:preFactor];
                usleep(sleepValue);
            }
            
        }else{
            CGFloat zoomFactor = factor;
            zoomFactor = MIN(10.0f, zoomFactor);
            zoomFactor = MAX(1.0f, zoomFactor);
            [self.cameraDevice setVideoZoomFactor:factor];
        }
        [self.cameraDevice unlockForConfiguration];
    };
}

- (void)detechAtuhorizationStatus
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus==AVAuthorizationStatusNotDetermined) {
        
    }else if (authStatus != AVAuthorizationStatusAuthorized){
        
        if (self.detechAuthorTimer) {
            [self.detechAuthorTimer invalidate];
            self.detechAuthorTimer = nil;
        }
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:@"未检测到视频,无法开始直播,请检测手机麦克风" delegate:self cancelButtonTitle:@"确认" otherButtonTitles:nil, nil];
        [alert show];
        
    }else{
        
        if (self.detechAuthorTimer) {
            [self.detechAuthorTimer invalidate];
            self.detechAuthorTimer = nil;
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (self.handler) {
        self.handler(NO);
    }
}

- (void)captureStillImageWith:(NSString*)destinationImageUrl
{
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in self.stillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) { break; }
    }
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
        [IAUtility setStillCaptureImageData:imageData];
    }];
}


@end
