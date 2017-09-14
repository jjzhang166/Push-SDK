//
//  PAPushSDK.h
//  anchor
//
//  Created by wangweishun on 8/6/16.
//  Copyright © 2016 PAJK. All rights reserved.
//

#import "LiveConfig.h"

typedef void(^PAPushSDKCallbackHandler)(NSInteger resultCode, PAEventCode resultId, NSInteger reservedCode);

#import <Foundation/Foundation.h>

@interface PAPushSDK : NSObject

// SDK版本号
+ (NSString *)sdkVersion;

// 创建推流SDK实例
- (id)initPushSDK:(PAPushSDKCallbackHandler)callback;

// 设置推流的音视频参数和推流码率
- (void)setParam:(PADefinition)definition fps:(int)fps sampleRate:(int)sampleRate sampleBit:(int)sampleBit channels:(int)channels
          bitRate:(PABitRate)bitRate;

// 设置显示窗口
- (void)setWindow:(UIView *)window;

// 设置推流地址
- (void)setPushUrl:(NSString *)url;

//开启设备（摄像头、麦克风等）
- (void)setupDevice;

// 开始推流
- (void)startStreaming;

// 重新推流（自动重连）
- (void)restartPushStreaming;

// 结束推流
- (void)stopStreaming;

// 设置摄像头
- (void)setCameraFront:(BOOL)cameraFront;

// 是否开启美颜
- (void)setBeautyFace:(BOOL)beautyFace;

/**
 *	@brief 设置美颜滤镜
 *  @param smooth       磨皮系数 取值范围［0.0, 1.0］
 *  @param white        美白系数 取值范围［0.0, 1.0］
 *  @param pink         粉嫩系数 取值范围［0.0, 1.0］
 */
- (void)setCameraBeautyFilterWithSmooth:(float)smooth white:(float)white pink:(float)pink;

// 聚焦到某个点
- (void)setFocusAtPoint:(CGPoint)point;

// 设置声音
- (void)setVolume:(NSInteger)volume;

// 返回当前发送速度(kb/s)
- (CGFloat)getSendSpeed;

// 获取码率
- (PABitRate)getBitRate;

// 得到视频丢帧数
- (NSInteger)getVideoDroppedFrameNum;

// 设置是否活动中, active：YES，继续推流；NO，停止推流
- (void)setActive:(BOOL)active;

// 销毁推流SDK实例
- (void)destroy;

//丢帧率
-(CGFloat)dropdownFrameRate;

@end
