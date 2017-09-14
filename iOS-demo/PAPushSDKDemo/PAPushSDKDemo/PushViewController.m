//
//  PushViewController.m
//  PAPushSDKDemo
//
//  Created by Derek Lix on 21/06/2017.
//  Copyright © 2017 Derek Lix. All rights reserved.
//

#import "PushViewController.h"
#import <UIKit/UIKit.h>
#import "PAPushSDK.h"
#import "PDTimer.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import "UIAlertView+Block.h"
#import "UIDevice-Hardware.h"
#import "IAUtility.h"
#import "AppDelegate.h"
#import "BeautyFilterModel.h"
#import "PushConfigView.h"

#define NotificationLock CFSTR("com.apple.springboard.lockcomplete")
#define NotificationChange CFSTR("com.apple.springboard.lockstate")
#define NotificationPwdUI CFSTR("com.apple.springboard.hasBlankedScreen")

#define kNoNetLastTime 50
#define kCustomPhone @"021-33257200"

#define kResolution @"540x960"

@interface PushViewController ()
@property (nonatomic, strong) PAPushSDK *pushSDK;

@property (nonatomic, strong) UILabel *loadingLabel;
@property (nonatomic, strong) UIView *focusBox;

@property (nonatomic, assign) BOOL interrupttedBeforeInactive;
@property (nonatomic, assign) double defaultCharmNumber;
@property (nonatomic, assign) double imTotalCharmNumber;  //im消息累计值

@property (nonatomic, strong) PDTimer *pushSpeedTimer;  //推流速度定时器
@property (nonatomic, strong) PDTimer *perMinuteTimer;  //一分钟刷新一次在线人数等数据
@property (nonatomic, strong) PDTimer *countDownTimer;  //断网50S倒计时
@property (nonatomic, strong) PDTimer *beatHeartTimer;  //定时心跳, retinavision心跳10s， logcenter心跳10s

@property (nonatomic, assign) BOOL isInvokeBroadcast; //是否调用上架接口
@property (nonatomic, assign) BOOL sdkPushStatus;    //sdk推流状态
@property (nonatomic, assign) long long lastPushFailed;  //推流失败时间戳（长时间(50S)推流不成功，结束推流）
@property (nonatomic, assign) NSInteger tipIndex;  //长时间(50S)推流速度太低(<20%)，给明显的提示，建议调增网络
@property (nonatomic, assign) BOOL isLockScreen;   //default NO

@property (nonatomic, assign) BOOL isNoNetState;
@property (nonatomic, strong) NSDate *noNetdate;
@property (nonatomic, strong) NSDate *startPushTime;   //开始服务器推流

@property (nonatomic, assign) BOOL isFrontCamera;
@property (nonatomic, assign) BOOL isBeautifyOn;
@property (nonatomic, assign) CGFloat micGain;

@property (nonatomic, assign) NSInteger pushFrameRate; //帧率
@property (nonatomic, strong) CTCallCenter *callCenter;
@property (nonatomic, assign) BOOL noAudioAlertExist;
@property (nonatomic, strong) UIButton* configBtn;
@property (nonatomic, strong) PushConfigView* configView;
@property (nonatomic, assign) CGRect   originConfigViewRect;

@property (copy, nonatomic) NSString* resolution;
@property (copy, nonatomic) NSString* definition;
@property (copy, nonatomic) NSString* pushUrl;

@end

@implementation PushViewController

- (void)dealloc
{
    LogDebug(@"LivePushViewController dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [self unRegisterNotifications];
    if (self.pushSDK) {
        [self.pushSDK destroy];
        self.pushSDK = nil;
    }
    [self distroyAllTimer];
}

- (void)distroyAllTimer
{
    if (self.countDownTimer) {
        [self.countDownTimer invalidate];
        self.countDownTimer = nil;
    }
    if (self.beatHeartTimer) {
        [self.beatHeartTimer invalidate];
        self.beatHeartTimer = nil;
    }
    if (self.perMinuteTimer) {
        [self.perMinuteTimer invalidate];
        self.perMinuteTimer = nil;
    }
    if (self.pushSpeedTimer) {
        [self.pushSpeedTimer invalidate];
        self.pushSpeedTimer = nil;
    }
}

- (instancetype)init
{
    if (self = [super init]) {
        _isFrontCamera = YES;
        _isBeautifyOn = YES;
        _micGain = 10;
        _lastPushFailed = 0;
        _isInvokeBroadcast = NO;
        _noAudioAlertExist = NO;
        if ([[UIDevice currentDevice] platformType] <= UIDevice5CiPhone) { //5c、5
            _pushFrameRate = 20;
        } else {
            _pushFrameRate = 25;
        }
    }
    return self;
}

- (void)setupAccessoryViews{
    CGFloat btnWidth = 50.f;
    CGFloat btnX = [UIScreen mainScreen].bounds.size.width - btnWidth - 20;
    self.configBtn = [[UIButton alloc] initWithFrame:CGRectMake(btnX, 20, btnWidth, btnWidth)];
    [self.configBtn setBackgroundColor:[UIColor colorWithWhite:0.f alpha:0.3f]];
    [self.configBtn.layer setCornerRadius:25.f];
    [self.configBtn addTarget:self action:@selector(configBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.configBtn setTitle:@"配置" forState:UIControlStateNormal];
    [self.view addSubview:self.configBtn];
}

- (void)configBtnClick:(id)sender{
    if (self.configView) {
        [self.configView removeFromSuperview];
        self.configView = nil;
    }else{
        __weak typeof(self) weakSelf = self;
        self.configView = [[PushConfigView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 250, [UIScreen mainScreen].bounds.size.width, 250) configViewHandler:^(BOOL restart, NSString *definition, NSString *resoultion, NSString* pushUrl) {
            [weakSelf executeRestartClick:restart definition:definition resoultion:resoultion pushUrl:pushUrl];
        }];
        [self.view addSubview:self.configView];
        self.originConfigViewRect = self.configView.frame;
    }
}

- (void)executeRestartClick:(BOOL)shouldStart definition:(NSString*)defintion resoultion:(NSString*)resoultion pushUrl:(NSString*)url{
    
    if (shouldStart) {
        self.definition = defintion;
        self.resolution = resoultion;
        self.pushUrl = url;
        [self.pushSDK setPushUrl:_pushUrl];
        
        PADefinition defintion = IA_540P;
        if ([self.resolution isEqualToString:@"480p"]) {
        }else if ([self.resolution isEqualToString:@"540p"]){
        }else if ([self.resolution isEqualToString:@"720p"]){
            defintion = IA_720P;
        }
        
        
        PABitRate bitRate = IA_550K;
        if ([self.definition isEqualToString:@"512"]) {
            bitRate = IA_512K;
        }else if ([self.definition isEqualToString:@"768"]){
            bitRate = IA_700K;
        }else if ([self.definition isEqualToString:@"1M"]){
            bitRate = IA_1M;
        }else if ([self.definition isEqualToString:@"1.5M"]){
            bitRate = IA_1Dot5M;
        }else if ([self.definition isEqualToString:@"2M"]){
            bitRate = IA_2M;
        }
        
        [self.pushSDK setParam:defintion fps:(int)_pushFrameRate sampleRate:44100 sampleBit:16 channels:2 bitRate:bitRate];
        [self restartPushStream];
    }
    
    [self.configView removeFromSuperview];
    self.configView = nil;
}

-(void)registerKeyboard{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void) keyboardWasShown:(NSNotification *) notif
{
    NSDictionary *info = [notif userInfo];
    NSValue *value = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [value CGRectValue];
    
    self.configView.frame = CGRectMake(self.originConfigViewRect.origin.x, keyboardRect.origin.y-50, self.originConfigViewRect.size.width, self.originConfigViewRect.size.height);
}
- (void)keyboardWillHide:(id)sender{
    self.configView.frame = self.originConfigViewRect;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupAccessoryViews];
    [self registerKeyboard];
    
    //test url
    self.pushUrl  = IA_DefaultRtmpUrl;
    
    [self registerNotifications];
    
    if ([IAUtility isMoreThanIOS10]){
        [self addCallListener];
    }
    
    __weak typeof(self) wself = self;
    self.pushSDK = [[PAPushSDK alloc] initPushSDK:^(NSInteger resultCode, PAEventCode resultId, NSInteger reservedCode) {
        if (resultId == PA_START) {
            if (resultCode < 0) { //rtmp连接失败,重新推
                wself.sdkPushStatus = NO;
                LogError(@"[PushSDK] rtmp连接失败，resultCode ＝ %@", @(resultCode));
                if ([[JKNReachability reachability] isReachable]) {
                    [wself performSelector:@selector(startPushStream) withObject:nil afterDelay:1];
                    return;
                } else {
                    LogError(@"[Live end] rtmp连接失败：%@", @(resultCode));
                    [wself showPushErrorWithTitle:nil message:@"无网络连接，请检查网络重新开播（1）"];
                }
            } else if (resultCode == 0) { //rtmp连接成功, 只会回调一次
                LogInfo(@"[PushSDK] rtmp连接成功");
            } else {
                LogInfo(@"[PushSDK] rtmp连接成功, resultCode = %@", @(resultCode));
            }
        } else if (resultId == PA_PUSH_STREAM) {
            if (resultCode < 0) { //推流失败, push SDK会重连
                LogError(@"[PushSDK] rtmp推流失败 resultCode = %@",@(resultCode));
                wself.sdkPushStatus = NO;
                if (wself.lastPushFailed == 0) {
                    wself.lastPushFailed = [[NSDate date] timeIntervalSince1970] * 1000;
                } else {
                    long long now = [[NSDate date] timeIntervalSince1970] * 1000;
                    if (now - wself.lastPushFailed > 50 * 1000 ) { //50S,长时间(50S)推流不成功
                        LogError(@"[Live end] rtmp推流失败：%@", @(resultCode));
                        if ([[JKNReachability reachability] isReachable]) {
                            [wself showPushErrorWithTitle:nil message:@"推流服务异常，请稍后再进行直播"];
                        } else {
                            [wself showPushErrorWithTitle:nil message:@"无网络连接，请检查网络重新开播（2）"];
                        }
                        return;
                    }
                }
                [wself restartPushStream];
            } else {
                wself.sdkPushStatus = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    wself.sdkPushStatus = YES;
                    if (!wself.isInvokeBroadcast) {
                        [wself pushConnectSuccess];
                    }
                });
                
                wself.lastPushFailed = 0;
                LogDebug(@"[PushSDK] 推流成功");
            }
        } else if (resultId == PA_STOP) {
            if (resultCode < 0) { //停止失败
                LogError(@"[Live end] rtmp停止失败：%@", @(resultCode));
                [wself showPushErrorWithTitle:nil message:@"网络异常，请检查网络连接或稍后进行直播"];
            } else {
                LogInfo(@"[PushSDK] rtmp停止, resultCode = %@", @(resultCode));
            }
        } else if (resultId == PA_PUSH_EXCEPTION){
            
            [wself dropExceptionLog:resultCode errorCode:reservedCode];
            
            if ((resultCode==AUDIODEVICE_LOAD_FAIL)||(resultCode==AUDIO_SEND_BLOCKED)||(resultCode==AUDIO_ENCODER_BLOCKED)||(resultCode==AUDIO_CAPTURE_BLOCKED)||(resultCode==AUDIO_ENCODER_DROPPED)) {
                if (!wself.noAudioAlertExist) {
                    wself.noAudioAlertExist = YES;
                    __weak typeof(self) wself = self;
                    UIAlertView*  alertView = [[UIAlertView alloc] initWithTitle:nil message:@"您的直播无声音，请结束直播重新开播" delegate:nil cancelButtonTitle:@"暂不结束" otherButtonTitles:@"立即结束", nil];
                    [alertView showHudWithBackBlock:^{
                        [wself finishLive];
                    }];
                }
            }
            
            else if ((resultCode==VIDEODEVICE_LOAD_FAIL)||(resultCode==VIDEO_SEND_BLOCKED)||(resultCode==VIDEO_ENCODER_BLOCKED)||(resultCode==VIDEO_CAPTURE_BLOCKED)||(resultCode==VIDEO_ENCODER_DROPPED)) {
                if (!wself.noAudioAlertExist) {
                    wself.noAudioAlertExist = YES;
                    __weak typeof(self) wself = self;
                    UIAlertView*  alertView = [[UIAlertView alloc] initWithTitle:nil message:@"您的直播无画面，请结束直播重新开播" delegate:nil cancelButtonTitle:@"暂不结束" otherButtonTitles:@"立即结束", nil];
                    [alertView showHudWithBackBlock:^{
                        [wself finishLive];
                    }];
                }
            }
            
        }else {
            if (resultCode < 0) {
            }
            LogError(@"[PushSDK] Push SDK Callback errorCode = %@, resultId = %@", @(resultCode), @(resultId));
        }
    }];
    
    //begin to push
    [self prepareStartPush];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    [self.view bringSubviewToFront:self.configBtn];
}

-(void)dropExceptionLog:(NSInteger)typeCode errorCode:(NSInteger)reservedCode{
    NSString* exceptionBehavior = @"";
    NSString* desciption = @"";
    switch (typeCode) {
        case NONE_BLOCK:
            break;
        case VIDEODEVICE_LOAD_FAIL:{
            exceptionBehavior = PA_VIDEOHARDWARE_LOADERROR;
            desciption = @"videohardware load fail";
        }
            break;
        case VIDEO_SEND_BLOCKED:{
            exceptionBehavior = PA_RUNTIME_NOVIDEO;
            desciption = @"video send block";
        }
            break;
        case VIDEO_ENCODER_BLOCKED:{
            exceptionBehavior = PA_RUNTIME_NOVIDEO;
            desciption = @"video encode block";
        }
            break;
        case VIDEO_CAPTURE_BLOCKED:{
            exceptionBehavior = PA_RUNTIME_NOVIDEO;
            desciption = @"video capture block";
        }
            break;
        case VIDEO_ENCODER_DROPPED:{
            exceptionBehavior = PA_RUNTIME_NOVIDEO;
            desciption = @"video drop block";
        }
            break;
        case VIDEO_BLOCKED_UNKNOWN:{
            exceptionBehavior = PA_RUNTIME_NOVIDEO;
            desciption = @"video unknown block";
        }
            break;
        case AUDIODEVICE_LOAD_FAIL:{
            exceptionBehavior = PA_AUDIOHARDWARE_LOADERROR;
            desciption = @"audiohardware load fail";
        }
            break;
        case AUDIO_SEND_BLOCKED:{
            exceptionBehavior = PA_RUNTIME_NOAUDIO;
            desciption = @"audio send block";
        }
            break;
        case AUDIO_ENCODER_BLOCKED:{
            exceptionBehavior = PA_RUNTIME_NOAUDIO;
            desciption = @"audio encode block";
        }
            break;
        case AUDIO_CAPTURE_BLOCKED:{
            exceptionBehavior = PA_RUNTIME_NOAUDIO;
            desciption = @"audio capture block";
        }
            break;
        case AUDIO_ENCODER_DROPPED:{
            exceptionBehavior = PA_RUNTIME_NOAUDIO;
            desciption = @"audio drop block";
        }
            break;
        case AUDIO_BLOCKED_UNKNOWN:{
            exceptionBehavior = PA_RUNTIME_NOAUDIO;
            desciption = @"audio unknown block";
        }
            break;
        default:
            break;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    
    __weak typeof(self) wself = self;
    if (!self.perMinuteTimer) {
        self.perMinuteTimer = [PDTimer scheduledTimerWithTimeInterval:60 userInfo:nil repeats:YES actionBlock:^(id userInfo) {
            
        }];
    } else {
        [self.perMinuteTimer resumeTimer];
    }
    
    if (!self.pushSpeedTimer) {
        self.pushSpeedTimer = [PDTimer scheduledTimerWithTimeInterval:2 userInfo:nil repeats:YES actionBlock:^(id userInfo) {
            NSInteger pushSpeed = [self.pushSDK getSendSpeed];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSInteger standardSpeed = [self getBitRate] * 8 / 1024;
                //                [wself.containerView.speedView setSpeedValue:pushSpeed standardSpeed:standardSpeed];
                //                [wself.containerView.speedView setLossRate:[self getLossRate]];
                
                if (_pushStatus == LivePushStatusRuning) {
                    if (pushSpeed * 8 < standardSpeed * 0.2) { //推流速度太低(<20%)
                        wself.tipIndex++;
                    } else {
                        wself.tipIndex = 0;
                    }
                    if (wself.tipIndex >= 25) { //50s, 25*2 = 50
                        wself.tipIndex = 0;
                        [wself.view showHudWithTextOnly:@"您的网速不太稳定，直播效果较差，请检测网速" afterDelay:3];
                        LogError(@"[PushSDK] 超过50S推流速度太低！");
                    }
                }
            });
        }];
    } else {
        [self.pushSpeedTimer resumeTimer];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.perMinuteTimer pauseTimer];
    [self.pushSpeedTimer pauseTimer];
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"resign_window" object:nil];
}

#pragma mark - get/setter
- (UILabel *)loadingLabel
{
    if (_loadingLabel == nil) {
        self.loadingLabel = [[UILabel alloc] init];
        _loadingLabel.textColor = [UIColor lightGrayColor];
        [self.view addSubview:_loadingLabel];
    }
    
    return _loadingLabel;
}

- (void)setSdkPushStatus:(BOOL)sdkPushStatus
{
    LogInfo(@"[PushSDK] 推流状态变化：%@", @(sdkPushStatus));
    _sdkPushStatus = sdkPushStatus;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_sdkPushStatus) {
            self.loadingLabel.text = @"正在连接...";
        }
        self.loadingLabel.hidden = _sdkPushStatus;
    });
}

- (void)setIsBeautifyOn:(BOOL)isBeautifyOn
{
    _isBeautifyOn = isBeautifyOn;
    [_pushSDK setBeautyFace:isBeautifyOn];
}

- (NSUInteger)getPushSpeed
{
    NSUInteger speed = (NSUInteger)([self.pushSDK getSendSpeed] * 1024);
    return speed;
}

- (NSUInteger)getBitRate
{
    PABitRate rate = [self.pushSDK getBitRate];
    NSUInteger bitRate = 0; //kb
    switch (rate) {
        case IA_2M:
            bitRate = 2048;
            break;
        case IA_1Dot5M:
            bitRate = 1536;
            break;
        case IA_1M:
            bitRate = 1024;
            break;
        case IA_700K:
            bitRate = 700;
            break;
        case IA_512K:
            bitRate = 512;
            break;
        case IA_550K:
            bitRate = 550;
            break;
        case IA_450K:
            bitRate = 450;
            break;
        default:
            bitRate = 450;
            break;
    }
    return bitRate * 1024 / 8; //Byte
}

- (CGFloat)getLossRate
{
    return [self.pushSDK dropdownFrameRate];
}

- (void)setupPushConfig
{
    LogInfo(@"[PushSDK] start:开始推流设置: 帧率：%@", @(_pushFrameRate));
    [self.pushSDK setParam:IA_540P fps:(int)_pushFrameRate sampleRate:44100 sampleBit:16 channels:2 bitRate:IA_550K];
    [self.pushSDK setWindow:self.view];
    [self.pushSDK setupDevice];
    [self.pushSDK setBeautyFace:_isBeautifyOn];
    [self.pushSDK setCameraFront:_isFrontCamera];
    
    BeautyFilterModel *beautyModel = [BeautyFilterModel localBeautyModel];
    if (beautyModel) {
        [self.pushSDK setCameraBeautyFilterWithSmooth:beautyModel.smooth white:beautyModel.white pink:beautyModel.pink];
    } else {
        BeautyFilterModel *beautyModel = [BeautyFilterModel modelWithSmooth:0.5 white:0.4 pink:0.3];
        [beautyModel save];
        [self.pushSDK setCameraBeautyFilterWithSmooth:beautyModel.smooth white:beautyModel.white pink:beautyModel.pink];
    }
    LogInfo(@"[PushSDK] end:推流设置完成");
}

- (void)changedCameraBeautyFilterWithSmooth:(CGFloat)smooth white:(CGFloat)white pink:(CGFloat)pink
{
    BeautyFilterModel *beautyModel = [BeautyFilterModel modelWithSmooth:smooth white:white pink:pink];
    [beautyModel save];
    [self.pushSDK setCameraBeautyFilterWithSmooth:smooth white:white pink:pink];
}

#pragma mark - stream
- (void)startPushStream
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.pushStatus = LivePushStatusStart;
    LogInfo(@"[Live] 开始推流－－推流地址Push url: %@", _pushUrl);
    if (self.pushUrl) {
        [self.pushSDK setPushUrl:_pushUrl];
        [self.pushSDK startStreaming];
        LogInfo(@"[PushSDK] SDK开始推流");
    } else {
        LogError(@"[Live end] StartPushStream push url is null");
        [self showPushErrorWithTitle:@"" message:@"获取推流地址失败，请退出后重新开播"];
    }
}

- (void)restartPushStream
{
    LogInfo(@"[PushSDK] 重新推流...");
    [self.pushSDK restartPushStreaming];
}

- (void)stopPushStream
{
    LogInfo(@"[Live] 停止推流stopPushStream");;
    
    self.pushStatus = LivePushStatusEnd;
    [self.pushSDK stopStreaming];
    [self distroyAllTimer];
}

#pragma mark - rtmp connect success
- (void)pushConnectSuccess
{
    self.isInvokeBroadcast = YES;
    self.startPushTime = [NSDate date];
}

- (void)setPushActive:(BOOL)active
{
    if (self.beatHeartTimer) {
        if (active) {
            [self.pushSpeedTimer resumeTimer];
            [self.perMinuteTimer resumeTimer];
            [self.beatHeartTimer resumeTimer];
        } else {
            [self.pushSpeedTimer pauseTimer];
            [self.perMinuteTimer pauseTimer];
            [self.beatHeartTimer pauseTimer];
        }
    }
    
    @synchronized(self) {
        [self.pushSDK setActive:active];
    }
}

#pragma mark - 打点页面描述
- (NSString *)customPageDescription
{
    return @"pajk_phone_push_streem_show";
}

#pragma mark - actions
- (void)back
{
    if (_pushStatus == LivePushStatusRuning) {
        [self stopPushStream];
    }
    [self distroyAllTimer];
    
    [super back];
}

- (void)singleTapped:(UITapGestureRecognizer *)tap
{
    if (_pushStatus == LivePushStatusRuning) {
        CGPoint point = [tap locationInView:self.view];
        [self runBoxAnimationOnView:_focusBox point:point];
        PADebug(@"pointx:%@,pointy:%@",@(point.x),@(point.y));
        [_pushSDK setFocusAtPoint:point];
    }
}

//对焦的动画效果
- (void)runBoxAnimationOnView:(UIView *)view point:(CGPoint)point
{
    [self.view addSubview:view];
    view.center = point;
    [UIView animateWithDuration:0.2f
                          delay:0.2f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         view.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0);
                     }
                     completion:^(BOOL complete) {
                         double delayInSeconds = 1.0f;
                         dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                         dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                             view.transform = CGAffineTransformIdentity;
                             [view removeFromSuperview];
                         });
                     }];
}

#pragma mark - request
- (void)prepareStartPush
{
    LogInfo(@"[live] prepareStartPush 准备推流");
    [self setupPushConfig];
    [self startPushStream];
}

#pragma mark - notification
- (void)registerNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeDeactive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
    
    
    if (![IAUtility isMoreThanIOS10]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVideoInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
    }
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNetworkChanged:) name:JKNReachabilityChangedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCameraAuthFail) name:PA_CAMERA_AUTHORIZE_FAIL object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMicroPhoneAuthFail) name:PA_MICROPHONE_AUTHORIZE_FAIL object:nil];
    
}

- (void)unRegisterNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL);
}

- (void)handleLogout
{
    if (_pushStatus == LivePushStatusEnd) {
        return;
    }
    LogError(@"[Live end] token错误退出");
    [self showPushErrorWithTitle:@"" message:@"设备验证失败"];
}

- (void)applicationEnterForeground
{
    LogDebug(@"[Live] App enter Foreground");
    if (![self hasPermissionOfCamera]) {
        return;
    }
    [self setPushActive:YES];
}

- (void)applicationEnterBackground
{
    LogDebug(@"[Live] App enter Background");
    if (![self hasPermissionOfCamera]) {
        return;
    }
    if (!_isLockScreen) {
        [self setPushActive:NO];
    }
    
}

- (void)applicationDidBecomeActive
{
    LogDebug(@"[Live] App become Active");
    if (_interrupttedBeforeInactive) {
        [self resumePushIfShould];
    }
    _isLockScreen = NO;
}

- (void)applicationDidBecomeDeactive
{
    LogDebug(@"[Live] App become deactive");
}

- (void)applicationWillTerminate
{
}


- (void)onVideoInterruption:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    AVAudioSessionInterruptionType type = [[userInfo objectForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    
    if (type == AVAudioSessionInterruptionTypeBegan) {
        [self setPushActive:NO];
        _interrupttedBeforeInactive = YES;
    } else {
        AVAudioSessionInterruptionOptions options = [[userInfo objectForKey:AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
        
        if (options == AVAudioSessionInterruptionOptionShouldResume) {
            if (_interrupttedBeforeInactive) {
                [self resumePushIfShould];
            }
        }
    }
}

- (void)resumePushIfShould
{
    sleep(1);
    [self setPushActive:YES];
    _interrupttedBeforeInactive = NO;
}

- (void)userTappedNotification:(NSNotification *)notification
{
}

- (void)imCharmReceiveNotification:(NSNotification *)notification
{
}

- (void)onCameraAuthFail
{
    LogError(@"[live Camera] 授权失败");
    [self showPermissionDialogWithTitle:@"您暂未开启相机权限" message:@"请至系统设置－健康直播助手中开启"];
}

- (void)onMicroPhoneAuthFail
{
    LogError(@"[live MicroPhone] 授权失败");
    [self showPermissionDialogWithTitle:@"您暂未开启麦克风权限" message:@"请至系统设置－健康直播助手中开启"];
}

- (void)onNetworkChanged:(NSNotification *)reachabilityNotis
{
    [self handleNetworkCheck];
}

- (void)handleNetworkCheck
{
    JKNReachability *reachability = [JKNReachability reachability];
    if (![reachability isReachable]) {
        [self.view showHudWithText:@"网络连接已断开, 请检查您的网络"];
        _isNoNetState = YES;
        self.noNetdate = [NSDate date];  //记录网络中断时间
        if (!self.countDownTimer) {
            __weak typeof(self) wself = self;
            self.countDownTimer = [PDTimer scheduledTimerWithTimeInterval:kNoNetLastTime userInfo:nil repeats:NO actionBlock:^(id userInfo) {
                if (wself.isNoNetState) { //无网状态超过50s
                    LogError(@"[Live end] 无网状态超过50s");
                    [wself showPushErrorWithTitle:nil message:@"无网络连接，请检查网络重新开播（4）"];
                }
            }];
        }
    } else {
        _isNoNetState = NO;
        if (self.noNetdate) { //网络中断打点
            self.noNetdate = nil;
        }
        if (self.countDownTimer) {
            [self.countDownTimer invalidate];
            self.countDownTimer = nil;
        }
        [self.view hideHud];
        if (_pushStatus == LivePushStatusRuning) {
            if ([reachability isReachableViaWWAN]) {// Network reachable via 2/3/4G
                __weak __typeof(self)weakSelf = self;
                [self handleWWANNetworkTipWithOkBlock:^{
                } cancelBlock:^{
                    LogError(@"[Live end] 非wifi网络退出");
                    [weakSelf back];
                }];
            } else {
                
            }
        }
    }
}

- (void)handleWWANNetworkTipWithOkBlock:(void(^)(void))okBlock cancelBlock:(void(^)(void))cancelBlock
{
    JKNReachability *reachability = [JKNReachability reachability];
    
    if (![reachability isReachable]) {// Network unreachable
        if (okBlock) {
            okBlock();
        }
    } else {
        if ([reachability isReachableViaWWAN]) {// Network reachable via 2/3/4G
            
        } else {
            if (okBlock) {
                okBlock();
            }
        }
    }
}

- (BOOL)hasPermissionOfCamera
{
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(authStatus != AVAuthorizationStatusAuthorized){
        LogError(@"[Live] Camera forbid");
        return NO;
    }
    return YES;
}

#pragma mark - Call listener
- (void)addCallListener
{
    self.callCenter = [[CTCallCenter alloc] init];
    __weak  typeof(self) weakSelf = self;
    self.callCenter.callEventHandler = ^(CTCall* call) {
        if([call.callState isEqualToString:CTCallStateIncoming]) {
            LogDebug(@"[Call] Call is incoming");
            [weakSelf setPushActive:NO];
            _interrupttedBeforeInactive = YES;
            
        }
        else if ([call.callState isEqualToString:CTCallStateConnected]) {
            LogDebug(@"[Call] Call has just been connected");
        }
        else if ([call.callState isEqualToString:CTCallStateDialing]) {
            LogDebug(@"[Call] Call is dialing");
        }
        else if ([call.callState isEqualToString:CTCallStateDisconnected]) {
            LogDebug(@"[Call] Call has been disconnected");
            sleep(1);
            [weakSelf resumePushIfShould];
        }
        else {
            LogDebug(@"[Call] Nothing is done");
        }
    };
}

#pragma mark - live unexpected exit
- (void)showPushErrorWithTitle:(NSString *)title message:(NSString *)message
{
    LogError(@"[Live End Dialog] 异常退出：%@", message);
    [self.view hideHud];
    
    self.pushStatus = LivePushStatusFailed;
    [self stopPushStream];
    [self unRegisterNotifications];
}

- (void)showPermissionDialogWithTitle:(NSString *)title message:(NSString *)message
{
}

#pragma mark - live finish
- (void)finishLive
{
    LogInfo(@"[Live end] 主播主动关闭直播");
    
    [_pushSDK stopStreaming];
    [self unRegisterNotifications];
    [self distroyAllTimer];
    
    
    self.pushStatus = LivePushStatusEnd;
    
    if (self.pushSDK) {
        [self.pushSDK destroy];
        self.pushSDK = nil;
    }
}



@end

