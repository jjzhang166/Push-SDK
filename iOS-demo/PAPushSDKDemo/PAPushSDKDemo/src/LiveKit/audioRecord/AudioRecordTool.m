
//
//  AudioRecordTool.m
//  VideoStudy
//
//  Created by wangweishun on 31/03/2017.
//  Copyright © 2017 DD. All rights reserved.
//

#import "AudioRecordTool.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface AudioRecordTool() <AVAudioRecorderDelegate> {
       BOOL _isPause;
}

@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (nonatomic, strong) NSMutableDictionary *recordSetting;
@property (nonatomic, strong) NSTimer *timer;

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundIdentifier;
#endif

@end

@implementation AudioRecordTool

+ (void)checkRecordPermission:(PermissionBlock)response {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if(granted) {
            response(YES);
        } else {
            response(NO);
        }
    }];
}

- (instancetype)init {
    if (self = [super init]) {
        _maxRecordTime = 60;
    }
    return self;
}

/**
 *  设置音频会话
 */

- (void)setAudioSession
{
//    //Instanciate an instance of the AVAudioSession object.
//    AVAudioSession * audioSession = [AVAudioSession sharedInstance];
//    //Setup the audioSession for playback and record.
//    //We could just use record and then switch it to playback leter, but
//    //since we are going to do both lets set it up once
//    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
//    //Activate the session
//    [audioSession setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
//    
    NSError *error = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&error];
    if(error) {
        DDLogDebug(@"audioSession: %@ %ld %@", [error domain], (long)[error code], [[error userInfo] description]);
        return;
    }
    
    error = nil;
 //   [audioSession setActive:YES error:&error];
    if(error) {
        DDLogDebug(@"audioSession: %@ %ld %@", [error domain], (long)[error code], [[error userInfo] description]);
        return;
    }
}

/**
 *  设置录音一些属性
 */
- (void)initRecordSetting {
        /**
         1.音频格式
         AVFormatIDKey 键定义了写入内容的音频格式(coreAudioType.h)
         kAudioFormatLinearPCM 文件大 高保真
         kAudioFormatMPEG4AAC 显著压缩文件，并保证高质量的音频内容
         kAudioFormatAppleIMA4 显著压缩文件，并保证高质量的音频内容
         kAudioFormatiLBC
         kAudioFormatULaw
         
         2.采样率
         AVSampleRateKey 用于定义音频的采样率
         采样率越高 内容质量越高 相应文件越大
         标准采样率8000 16000 22050 44100(CD采样率)
         
         3.通道数
         AVNumberOfChannelsKey
         设值为1:意味着使用单声道录音
         设值为2:意味着使用立体声录制
         除非使用外部硬件进行录制，一般是用单声道录制
         
         */
      _recordSetting = [NSMutableDictionary dictionaryWithCapacity:10];
#if 0
    // 音频格式
    _recordSetting[AVFormatIDKey] = @(kAudioFormatMPEG4AAC);
    // 录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）
    _recordSetting[AVSampleRateKey] = @(44100);
    // 音频通道数 1 或 2
    _recordSetting[AVNumberOfChannelsKey] = @(2);
    // 线性音频的位深度  8、16、24、32
    _recordSetting[AVLinearPCMBitDepthKey] = @(16);
    //录音的质量
    _recordSetting[AVEncoderAudioQualityKey] = [NSNumber numberWithInt:AVAudioQualityMedium];
#else
    
    // 音频格式
    _recordSetting[AVFormatIDKey] = @(kAudioFormatLinearPCM);
    // 录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）
    _recordSetting[AVSampleRateKey] = @(HLSAudioRecordSampleRate);
    // 音频通道数 1 或 2
    _recordSetting[AVNumberOfChannelsKey] = @(2);
    // 线性音频的位深度  8、16、24、32
    _recordSetting[AVLinearPCMBitDepthKey] = @(16);
    _recordSetting[AVEncoderBitRateKey] = @(16);
    //录音的质量
    _recordSetting[AVEncoderAudioQualityKey] = @(AVAudioQualityHigh);
    _recordSetting[AVLinearPCMIsNonInterleaved] = @(NO);
    _recordSetting[AVLinearPCMIsFloatKey] = @(NO);
    _recordSetting[AVLinearPCMIsBigEndianKey] = @(NO);
#endif
}

- (void)startBackgroundTask {
    [self stopBackgroundTask];
    
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    _backgroundIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self stopBackgroundTask];
    }];
#endif
}

- (void)stopBackgroundTask {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    if (_backgroundIdentifier != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundIdentifier];
        _backgroundIdentifier = UIBackgroundTaskInvalid;
    }
#endif
}

#pragma mark - actions
- (void)updateMeters {
    if (!_audioRecorder)
        return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_audioRecorder updateMeters];
        
        _currentTimeInterval = _audioRecorder.currentTime;
        
        if (!_isPause) {
            float progress = self.currentTimeInterval / self.maxRecordTime * 1.0;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (_recordProgress) {
                    _recordProgress(progress);
                }
            });
        }
        
        //获取第一个通道的音频，注音音频的强度方位-160到0
        float peakPower = [_audioRecorder averagePowerForChannel:0];
        double ALPHA = 0.015;
        double peakPowerForChannel = pow(10, (ALPHA * peakPower));
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // 更新扬声器
            if (_recordPeakPowerForChannel) {
                _recordPeakPowerForChannel(peakPowerForChannel);
            }
        });
        
        if (self.currentTimeInterval > self.maxRecordTime) {
            NSLog(@"audioRecordTool updateMeters");
            [self stopRecord];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (_maxTimeStopHandler) {
                    _maxTimeStopHandler();
                }
            });
        }
    });
}

- (CGFloat)decibels{
    if (self.audioRecorder) {
        double lowPassResults = pow(10, (0.05 * [self.audioRecorder peakPowerForChannel:0]));
        return lowPassResults;
//        NSInteger exactlyValue = [self.audioRecorder averagePowerForChannel:0]+160; //conver from 0 to 160, not -160 to 0.
//        return [self adapterUIValue:exactlyValue];
    }
    return 0.0;
}

- (CGFloat)adapterUIValue:(CGFloat)value{
    CGFloat result = value - 120;
    result = result<0?0:result;
    result = result>10?10:result;
    return result;
}

#pragma mark - timer
- (void)startTimer {
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(updateMeters) userInfo:nil repeats:YES];
    }
}

- (void)resetTimer {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

#pragma mark - record
- (void)prepareRecordAtRecordPath:(NSURL *)recordPath {
    [self initRecordSetting];
    [self prepareRecordAtRecordPath:recordPath recordSetting:_recordSetting];
}

- (void)prepareRecordAtRecordPath:(NSURL *)recordPath recordSetting:(NSDictionary *)recordSetting {
    [self setAudioSession];
    //_recordPath = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat: @"audio_%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"caf"]]];
    _recordPath = recordPath;
    if (recordSetting) {
        self.recordSetting = [NSMutableDictionary dictionaryWithDictionary:recordSetting];
    }
    if (_audioRecorder) {
        [self cancelRecord];
    }
    
    NSError *error = nil;
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:_recordPath settings:_recordSetting error:&error];
    if (error) {
        DDLogDebug(@"AVAudioRecorder初始化失败！");
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                        message:@"您的设备不支持当前录音设置"
                                                       delegate:self
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles: nil];
        [alert show];
    } else {
        if (self.audioRecorder) {
            self.audioRecorder.delegate = self;
            self.audioRecorder.meteringEnabled = YES;
            [self.audioRecorder prepareToRecord];
            [self.audioRecorder recordForDuration:_maxRecordTime];
            [self startBackgroundTask];
        }
    }
}

- (BOOL)startRecord {
    if ([_audioRecorder record]) {
        [self resetTimer];
        [self startTimer];
        return YES;
    }
    return NO;
}

- (BOOL)resumeRecord {
    _isPause = NO;
    if (_audioRecorder) {
        if ([_audioRecorder record]) {
            return YES;
        }
    }
    return NO;
}

- (void)pauseRecord {
    _isPause = YES;
    if (_audioRecorder) {
        [_audioRecorder pause];
    }
}

- (void)stopRecord {
    NSLog(@"audioRecordTool stopRecord");
    _isPause = NO;
    [self cancelRecord];
    [self resetTimer];
    [self stopBackgroundTask];
}

- (void)cancelRecord {
    if (_audioRecorder) {
        if (self.audioRecorder.isRecording) {
            [self.audioRecorder stop];
        }
        self.audioRecorder = nil;
    }
}

- (void)cancellAndDeleteRecord {
    NSLog(@"audioRecordTool cancellAndDeleteRecord");
    _isPause = NO;
    [self stopRecord];
    if (self.recordPath) { // 删除目录下的文件
        NSFileManager *fileManeger = [NSFileManager defaultManager];
        NSString *path = [self.recordPath absoluteString];
        if ([fileManeger fileExistsAtPath:path]) {
            NSError *error = nil;
            [fileManeger removeItemAtPath:path error:&error];
            if (error) {
                DDLogDebug(@"error :%@", error.description);
            }
        }
    }
}

- (NSString *)recordFormattedCurrentTime {
    NSUInteger time = (NSUInteger)self.audioRecorder.currentTime;
    return [self formatterTime:time];
}

#pragma mark - save record
- (NSURL *)saveRecordingWithName:(NSString *)name {
    NSTimeInterval timestamp = [NSDate timeIntervalSinceReferenceDate];
    NSString *filename = [NSString stringWithFormat:@"%@-%f.caf", name, timestamp];
    NSString *document = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *savePath = [document stringByAppendingPathComponent:filename];
    NSURL *sourceURL = self.recordPath;
    NSURL *saveURL = [NSURL fileURLWithPath:savePath];
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] copyItemAtURL:sourceURL toURL:saveURL error:&error];
    if (success) {
        DDLogDebug(@"[Record] Save Record success: %@", saveURL);
    } else {
        DDLogDebug(@"[Record] Save Record failured: %@", error);
    }
    return saveURL;
}

#pragma mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    DDLogDebug(@"[Record] Record Finished!");
    if (self.recordCompletionHandler) {
        self.recordCompletionHandler(flag);
    };
    if (flag) {
        DDLogDebug(@"[Record] 录音文件路径: %@, 大小: %@", self.recordPath, @([self getFileSize:self.recordPath.absoluteString] / 1024.0));
    }
  //  [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    DDLogDebug(@"[Record] Record Error: %@", error);
    if (self.recordCompletionHandler) {
        self.recordCompletionHandler(false);
    };
  //  [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
}

- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder {
    DDLogDebug(@"[Record] BeginInterruption: Recording process is interrupted");
    [self pauseRecord];
}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder {
    DDLogDebug(@"[Record] EndInterruption: Resuming the recording...");
    [self resumeRecord];
}

#pragma mark - utils
- (NSString *)formatterTime:(NSUInteger)time {
    NSInteger hours = (time / 3600);
    NSInteger minutes = (time / 60) % 60;
    NSInteger seconds = time % 60;
    NSString *format = @"%02i:%02i:%02i";
    return [NSString stringWithFormat:format, hours, minutes, seconds];
}

- (NSInteger)getFileSize:(NSString *)filePath
{
    NSFileManager *fileManager = [[NSFileManager alloc]init];
    if([fileManager fileExistsAtPath:filePath]) {
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:nil];
        NSNumber *theFileSize = [attributes objectForKey:NSFileSize];
        if (theFileSize) {
            return [theFileSize integerValue];
        }
    } else {
        DDLogDebug(@"[Record] filePath = %@ not exist!", filePath);
    }
    return -1;
}

- (void)dealloc {
    NSLog(@"audioRecordTool dealloc");
    [self stopRecord];
    self.audioRecorder = nil;
}

@end
