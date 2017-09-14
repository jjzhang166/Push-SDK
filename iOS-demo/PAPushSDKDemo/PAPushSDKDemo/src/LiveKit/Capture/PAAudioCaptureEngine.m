//
//  PAAudioCaptureEngine.m
//  anchor
//
//  Created by Derek Lix on 24/11/2016.
//  Copyright © 2016 PAJK. All rights reserved.
//

#import "PAAudioCaptureEngine.h"
#import "PAAudioCoder.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "PAAudioDeviceHelper.h"
#import "IAUtility.h"


#define kNumberBuffers      3
#define kSamplingRate       44100

#define t_sample             SInt16
#define kNumberChannels     1
#define kBitsPerChannels    (sizeof(t_sample) * 8)
#define kBytesPerFrame      (kNumberChannels * sizeof(t_sample))
//#define kFrameSize          (kSamplingRate * sizeof(t_sample))
#define kFrameSize          4096


#define EVERY_READ_LENGTH  10240
#define MIN_SIZE_PER_FRAME 10240


typedef struct PAAudioCallbackStruct
{
    AudioStreamBasicDescription mDataFormat;
    AudioQueueRef               queue;
    AudioQueueBufferRef         mBuffers[kNumberBuffers];
    AudioFileID                 outputFile;
    
    unsigned long               frameSize;
    long long                   recPtr;
    int                         run;
    
} PAAudioCallbackStruct;


@interface PAAudioCaptureEngine ()
{
    PAAudioCallbackStruct aqc;
    AudioFileTypeID fileFormat;
    long audioDataLength;
    long audioDataIndex;
}

@property(nonatomic, strong) PAAudioCoder*            audioEncoder;
@property(nonatomic, assign) PAAudioCallbackStruct    aqc;
@property(nonatomic, assign) long                     audioDataLength;
@property(nonatomic, strong) PAAudioDeviceHelper*     audioDeviceHelper;
@property (strong,nonatomic)NSTimer*                  detechAuthorTimer;
@property(nonatomic,assign) BOOL                      needMuted;

@end

@implementation PAAudioCaptureEngine

@synthesize aqc;
@synthesize audioDataLength;



-(id)init
{
    if (self=[super init]) {
        self.isRunning = NO;
        self.needMuted = NO;
        __weak typeof(self) weakSelf = self;
        self.audioEncoder = [[PAAudioCoder alloc] initWithDataCallbackHandler:^(char *buffer, UInt32 length) {
            if (weakSelf.delegate&&[weakSelf.delegate respondsToSelector:@selector(audioCoder:length:)]) {
                [weakSelf.delegate audioCoder:buffer length:length];
            }
        } beginHandler:^{
            
            if (weakSelf.delegate&&[weakSelf.delegate respondsToSelector:@selector(beginningCode)]) {
                [weakSelf.delegate beginningCode];
            }
        }];


        self.audioDeviceHelper = [[PAAudioDeviceHelper alloc] init];
        [self.audioDeviceHelper setupSession];
        
    }
    return self;
}


static void PAAudioInputCallback (void                   * inUserData,
                                  AudioQueueRef          inAudioQueue,
                                  AudioQueueBufferRef    inBuffer,
                                  const AudioTimeStamp   * inStartTime,
                                  unsigned long          inNumPackets,
                                  const AudioStreamPacketDescription * inPacketDesc){
    
    
    PAAudioCaptureEngine * engine = (__bridge PAAudioCaptureEngine *) inUserData;
    if (inNumPackets > 0)
    {
        if (engine.audioEncoder&&engine.isRunning) {
            
            if(engine.needMuted){
                memset(inBuffer->mAudioData, 0, inBuffer->mAudioDataByteSize);
            }

            [engine.audioEncoder convertpcm2aac:inBuffer->mAudioData bufferSize:inBuffer->mAudioDataByteSize];
        }
    }
    
    if (engine.aqc.run)
    {
        AudioQueueEnqueueBuffer(engine.aqc.queue, inBuffer, 0, NULL);
    }else{
        
    }
}

- (void) start{

    NSLog(@"PAAudioCaptureEngine start");
    [self detechAtuhorizationStatus];
    
    aqc.mDataFormat.mSampleRate = kSamplingRate;
    aqc.mDataFormat.mFormatID = kAudioFormatLinearPCM;
    aqc.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger |kLinearPCMFormatFlagIsPacked;
    aqc.mDataFormat.mFramesPerPacket = 1;
    aqc.mDataFormat.mChannelsPerFrame = kNumberChannels;
    aqc.mDataFormat.mBitsPerChannel = kBitsPerChannels;
    aqc.mDataFormat.mBytesPerPacket = kBytesPerFrame;
    aqc.mDataFormat.mBytesPerFrame = kBytesPerFrame;
    aqc.frameSize = kFrameSize;
    OSStatus result = AudioQueueNewInput(&aqc.mDataFormat, PAAudioInputCallback, (__bridge void *)(self), NULL, kCFRunLoopCommonModes, 0,  &aqc.queue);
    if (result!=noErr) {
        //AudioQueueNewInput error
        [[NSNotificationCenter defaultCenter] postNotificationName:PA_AUDIOHARDWARE_LOADERROR object:nil];
    }
    for (int i=0;i<kNumberBuffers;i++)
    {
        AudioQueueAllocateBuffer(aqc.queue, aqc.frameSize, &aqc.mBuffers[i]);
        AudioQueueEnqueueBuffer(aqc.queue, aqc.mBuffers[i], 0, NULL);
    }
    aqc.recPtr = 0;
    aqc.run = 1;
    
    audioDataIndex = 0;
    
    AudioQueueStart(aqc.queue, NULL);
    
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
}

- (void) stop{
    NSLog(@"PAAudioCaptureEngine stop");
    AudioQueueStop(aqc.queue, true);
    aqc.run = 0;
    AudioQueueDispose(aqc.queue, true);
    
    NSError *error = nil;
    
    [[AVAudioSession sharedInstance] setActive:NO error:&error];
}

- (void) pause{
    
    AudioQueuePause(aqc.queue);
}


-(void)setVolumeEngine:(NSInteger)volume{
    if(volume > 0)
        self.needMuted = NO;
    else
        self.needMuted = YES;
}

-(void)checkAudioAuthori{
    
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

- (void) dealloc
{
    NSLog(@"dealloc");
    if (self.detechAuthorTimer) {
        [self.detechAuthorTimer invalidate];
        self.detechAuthorTimer = nil;
    }
    
    AudioQueueStop(aqc.queue, true);
    aqc.run = 0;
    AudioQueueDispose(aqc.queue, true);
    
}


@end
