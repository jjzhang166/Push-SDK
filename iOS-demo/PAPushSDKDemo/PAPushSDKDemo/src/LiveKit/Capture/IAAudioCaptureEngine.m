//
//  IAAudioCaptureEngine.m
//  MediaRecorder
//
//  Created by Derek Lix on 15/12/16.
//  Copyright © 2015年 Derek Lix. All rights reserved.
//

#import "IAAudioCaptureEngine.h"

#import <UIKit/UIKit.h>
#import "IAUtility.h"

#define  SUPPORT_AAC_ENCODER  @"SUPPORT_AAC_ENCODER"
#define  Max_audioRawArray    30
#define  Max_encodedDataArray 30

@interface IAAudioCaptureEngine ()<AVCaptureAudioDataOutputSampleBufferDelegate,UIAlertViewDelegate,AVAudioSessionDelegate>
{
    AVCaptureSession* m_capture ;
    AudioConverterRef m_converter;
    char * audioInData ;
    int  remainSize;
}

@property(nonatomic,strong)NSMutableArray* audioRawArray;
@property(nonatomic,strong)NSMutableArray* audioEncodedArray;
@property(nonatomic,assign)NSTimeInterval  startAudioTimeInterval;
@property (strong, nonatomic)UIAlertView* authorStatusAlert;
@property (strong,nonatomic)NSTimer*      detechAuthorTimer;
@property (strong,nonatomic)IAAudioAuthorizationHandler  handler;

@end


@implementation IAAudioCaptureEngine

-(id)initWithAudioDataOutputSampleBufferDelegate:(id)delegateObserver  authorizationHandler:(IAAudioAuthorizationHandler)handler{
    
    if (self = [super init]) {
        
        self.outputSampleBufferDelegate = delegateObserver;
        self.handler = handler;
    }
    return self;
}

-(void)open {
    NSError *error;
    self.startAudioTimeInterval = 0;
    m_capture = [[AVCaptureSession alloc]init];
    
    
    
    AVCaptureDevice *audioDev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (authStatus==AVAuthorizationStatusNotDetermined) {
        if (self.detechAuthorTimer) {
            [self.detechAuthorTimer invalidate];
            self.detechAuthorTimer = nil;
        }
        self.detechAuthorTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(detechAtuhorizationStatus) userInfo:nil repeats:YES];
    } else if (authStatus != AVAuthorizationStatusAuthorized) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:PA_MICROPHONE_AUTHORIZE_FAIL object:nil];
        
    }else{
        
    }
    
    if (audioDev == nil)
    {
        NSLog(@"Couldn't create audio capture device");
        return ;
    }
    

    
    // create mic device
    AVCaptureDeviceInput *audioIn = [AVCaptureDeviceInput deviceInputWithDevice:audioDev error:&error];
    if (error != nil)
    {
        NSLog(@"Couldn't create audio input");
        return ;
    }
    
    
    // add mic device in capture object
    if ([m_capture canAddInput:audioIn] == NO)
    {
        NSLog(@"Couldn't add audio input");
        return ;
    }
    [m_capture addInput:audioIn];
    
    [self performSelectorOnMainThread:@selector(setAudioDevice) withObject:nil waitUntilDone:YES];
    m_capture.usesApplicationAudioSession = YES;
    m_capture.automaticallyConfiguresApplicationAudioSession = YES;
    
    
    // export audio data
    self.outputDevice = [[AVCaptureAudioDataOutput alloc] init];
    dispatch_queue_t audioQueue = dispatch_queue_create("IAAudioQueue", NULL);
    //   [audioOutput setSampleBufferDelegate:self.outputSampleBufferDelegate queue:dispatch_get_main_queue()];
    [self.outputDevice setSampleBufferDelegate:self.outputSampleBufferDelegate queue:audioQueue];
    if ([m_capture canAddOutput:self.outputDevice] == NO)
    {
        NSLog(@"Couldn't add audio output");
        return ;
    }
    [m_capture addOutput:self.outputDevice];
    [self.outputDevice connectionWithMediaType:AVMediaTypeAudio];
    
    NSArray* array = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    NSLog(@"device array:%@",array);
    
    [m_capture startRunning];
    return ;
}

-(void)setAudioDevice{
    
    BOOL success = [[AVAudioSession sharedInstance] setActive:NO error: nil];
    if (!success) {
        NSLog(@"deactivationError");
    }
    
    // create and set up the audio session
    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    [audioSession setDelegate:self];
    NSError*  error;
    BOOL categoryResult = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionMixWithOthers  error:&error];
    
    
    // set up for bluetooth microphone input
    UInt32 allowBluetoothInput = 1;
    OSStatus stat = AudioSessionSetProperty (
                                             kAudioSessionProperty_OverrideCategoryEnableBluetoothInput,
                                             sizeof (allowBluetoothInput),
                                             &allowBluetoothInput
                                             );
    NSLog(@"astatus = %x", stat);    // problem if this is not zero
    UInt32 mode = kAudioSessionMode_VoiceChat;
    
    stat = AudioSessionSetProperty(kAudioSessionProperty_Mode, sizeof(mode), &mode);
    
    if (stat)
        printf("couldn't set audio session mode!");
    
    // check the audio route
    UInt32 size = sizeof(CFStringRef);
    CFStringRef route;
    OSStatus result = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &route);
    NSLog(@"route = %@", route);
    // if bluetooth headset connected, should be "HeadsetBT"
    // if not connected, will be "ReceiverAndMicrophone"
    
 
    NSArray* routes = [[AVAudioSession sharedInstance] availableInputs];
    for (AVAudioSessionPortDescription* route in routes)
    {
        if (route.portType == AVAudioSessionPortBluetoothHFP)
        {
            NSError* error ;
            BOOL result = [[AVAudioSession sharedInstance] setPreferredInput:route error:&error];
            NSLog(@"setPreferredInput result :%d error:%@",result,error);
        }else{
            NSLog(@"set built-in microphone");
        }
    }
  
    // activate audio session
    success = [[AVAudioSession sharedInstance] setActive:YES error: nil];
    if (!success) {
        NSLog(@"activationError");
    }
    
    
  //  [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeSpokenAudio error:nil];
    
  //  [[AVAudioSession sharedInstance] setActive:YES withOptions:kAudioSessionSetActiveFlag_NotifyOthersOnDeactivation error:nil];
    

}



-(void)detechAtuhorizationStatus{
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (authStatus==AVAuthorizationStatusNotDetermined) {
        
    }else if (authStatus != AVAuthorizationStatusAuthorized){
        
        if (self.detechAuthorTimer) {
            [self.detechAuthorTimer invalidate];
            self.detechAuthorTimer = nil;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:PA_MICROPHONE_AUTHORIZE_FAIL object:nil];
        
        
    }else{
        
        if (self.detechAuthorTimer) {
            [self.detechAuthorTimer invalidate];
            self.detechAuthorTimer = nil;
        }
    }
}

-(void)close {
    
    self.outputSampleBufferDelegate = self;
    if (self.detechAuthorTimer) {
        [self.detechAuthorTimer invalidate];
        self.detechAuthorTimer = nil;
    }
    
    if (m_capture != nil && [m_capture isRunning])
    {
        [m_capture stopRunning];
    }
    
    if(NULL != audioInData)
        free(audioInData);
    
    return;
}
-(BOOL)isOpen {
    if (m_capture == nil)
    {
        return NO;
    }
    
    return [m_capture isRunning];
}


-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (self.handler) {
        self.handler(NO);
    }
}

#pragma  AVAudioSessionDelegate

- (void)beginInterruption{
} /* something has caused your audio session to be interrupted */

/* the interruption is over */
- (void)endInterruptionWithFlags:(NSUInteger)flags NS_AVAILABLE_IOS(4_0){
} /* Currently the only flag is AVAudioSessionInterruptionFlags_ShouldResume. */

- (void)endInterruption{
} /* endInterruptionWithFlags: will be called instead if implemented. */

/* notification for input become available or unavailable */
- (void)inputIsAvailableChanged:(BOOL)isInputAvailable{
}

@end
