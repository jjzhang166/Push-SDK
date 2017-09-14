//
//  AudioRecordTool.h
//  VideoStudy
//
//  Created by wangweishun on 31/03/2017.
//  Copyright © 2017 DD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef void(^AudioRecordCompletionHandler)(BOOL);
typedef void(^AudioRecordStopCompletionHandler)(BOOL);
typedef void(^AudioRecordMaxtimeStopHandler)();
typedef void(^AudioRecordProgressHandler)(float progress);
typedef void(^AduioPeakPowerForChannelHandler)(float peakPowerForChannel); // peakPowerForChannel: 0~1.0


#define HLSAudioRecordSampleRate  11025.0
//#define HLSAudioRecordSampleRate  44100

/**
 * 录制音频类
 */
@interface AudioRecordTool : NSObject

@property (nonatomic, copy, readonly) NSURL *recordPath;
@property (nonatomic, copy) NSString *recordDuration;
@property (nonatomic, assign) float maxRecordTime;  //默认60秒为最大
@property (nonatomic, readonly) NSTimeInterval currentTimeInterval;

@property (nonatomic, copy) AudioRecordCompletionHandler recordCompletionHandler;  //录制完成回调
@property (nonatomic, copy) AudioRecordMaxtimeStopHandler maxTimeStopHandler;  //最大录制时间到回调
@property (nonatomic, copy) AudioRecordProgressHandler recordProgress; //录制进度回调
@property (nonatomic, copy) AduioPeakPowerForChannelHandler recordPeakPowerForChannel; //

// 检查麦克风权限
+ (void)checkRecordPermission:(PermissionBlock)response;

// reocrd
- (void)prepareRecordAtRecordPath:(NSURL *)recordPath;
- (void)prepareRecordAtRecordPath:(NSURL *)recordPath recordSetting:(NSDictionary *)recordSetting;
- (BOOL)startRecord;
- (BOOL)resumeRecord;
- (void)pauseRecord;
- (void)stopRecord;
- (void)cancelRecord;
- (void)cancellAndDeleteRecord;
- (CGFloat)decibels;

//  save record
- (NSURL *)saveRecordingWithName:(NSString *)name;


@end
