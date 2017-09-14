//
//  IAMediaRtmpEngine.h
//  MediaRecorder
//
//  Created by Derek Lix on 16/3/9.
//  Copyright © 2016年 Derek Lix. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "IAAudioCaptureEngine.h"
#import "IAVideoCaptureEngine.h"
#import "H264HwEncoderImpl.h"
#import "LiveConfig.h"
#import "PAAudioCaptureEngine.h"


#define  PA_CalculateDiscardframe_Interval   3

typedef void(^IAConnectRtmpHandler)(BOOL isScuccess,NSInteger errorCode);
typedef void(^IAFinishedRecordHandler)(NSString* videoUrl ,NSString* destinationUrl,BOOL success);

@class IAMediaRtmpEngine;

@protocol IAMediaRtmpEngineDelegate <NSObject>

@required
-(void)needRestartStreaming:(IAMediaRtmpEngine*)rtmpEngine errorCode:(NSInteger)errorCode;
-(void)pushFailure:(IAMediaRtmpEngine*)rtmpEngine errorCode:(NSInteger)errorCode;

@optional
//for write
- (void)coordinatorDidBeginRecording:(IAMediaRtmpEngine *)coordinator;
- (void)coordinator:(IAMediaRtmpEngine *)coordinator didFinishRecordingToOutputFileURL:(NSURL *)outputFileURL error:(NSError *)error;

@end

@interface IAMediaRtmpEngine : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate,PAAudioCoderDelegate>

@property(nonatomic,assign)BOOL   showScorePanel;
@property(nonatomic,assign)BOOL   showGameEvent;
@property(nonatomic,assign)double timeInterval;
@property(nonatomic,assign)NSInteger  homeTeamScore;
@property(nonatomic,assign)NSInteger  guestTeamScore;
@property(nonatomic,strong)NSString*  gameId;
@property(nonatomic,strong)NSString*  liveType;
@property(nonatomic,strong)NSString*  gameType;
@property(nonatomic,strong)IAFinishedRecordHandler  finishedRecordHandler;
@property(nonatomic,strong)NSString*  sportType;
@property(nonatomic,assign)BOOL       supportRecorder;
@property(nonatomic,strong)H264HwEncoderImpl* h264Encoder;
@property(nonatomic,weak)id<IAMediaRtmpEngineDelegate> delegate;
@property (nonatomic, assign) NSInteger reStreamingCount;
@property(nonatomic,readonly)BOOL   isPushing;

//for log
@property(nonatomic,assign)NSTimeInterval beforeVideoEncodeTimeInterval;
@property(nonatomic,assign)NSTimeInterval afterVideoEncodedTimeInterval;
@property(nonatomic,assign)NSTimeInterval beforeVideoSendTimeInterval;
@property(nonatomic,assign)NSTimeInterval afterVideoSendedTimeInterval;

@property(nonatomic,assign)NSTimeInterval beforeAudioEncodeTimeInterval;
@property(nonatomic,assign)NSTimeInterval afterAudioEncodedTimeInterval;
@property(nonatomic,assign)NSTimeInterval beforeAudioSendTimeInterval;
@property(nonatomic,assign)NSTimeInterval afterAudioSendedTimeInterval;

//for record
@property(nonatomic,assign)BOOL needfullcourtRecord;

-(id)initWithDelegate:(id<IAMediaRtmpEngineDelegate>)delegate bitRate:(PABitRate)bitRate definition:(PADefinition)defintion;

-(void)getInfoWith:(AVCaptureVideoDataOutput*)videoDataOutput audioDataOuput:(AVCaptureAudioDataOutput*)audioDataOuput;

-(void)startRtmpSend:(NSString*)url connectHandler:(IAConnectRtmpHandler)handler;
-(void)stopRtmp;
-(CGFloat)upLoadNetworkSpeed;
-(void)showGameEvent:(BOOL)show;
-(long long)totalPushData;
-(NSTimeInterval)startPushTime;
-(void)setVolumeEngine:(NSInteger)volume;

-(void)startRecord;
-(void)finishRecording;
-(BOOL)doesThreadExecuting;

-(NSURL*)currentRecordVideoLocalUrl;
//update streamingData

-(void)updateStreamingScorePanelTime:(NSString*)time;
-(void)sendEvent2StreamingWithGameEvent:(BOOL)isHostGame  eventId:(NSString*)eventId homeTeamName:(NSString*)homeTeamName guestTeamName:(NSString*)guestTeamName;
-(void)sendScore2StreamingWithHomeScore:(NSInteger)homeScore guestScore:(NSInteger)guestScore;

-(int) SetScoreboardParameter:(int)paramID param1:(const char*)param1 param2:(const char*)param2
                       pSize1:(int)pSize1 pSize2:(int)pSize2;

-(CGFloat)dropdownFrameRate;
-(void)calculateDropFrameRte:(NSInteger)count;

- (NSInteger)startWonderfullClip:(NSString*)filePath;
- (void)endWonderfullClip;

@end
