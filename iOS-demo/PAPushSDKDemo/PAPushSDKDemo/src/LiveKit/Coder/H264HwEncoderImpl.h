//
//  H264HwEncoderImpl.h
//  h264v1
//
//  Created by Ganvir, Manish on 3/31/15.
//  Copyright (c) 2015 Ganvir, Manish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IAMediaDataModel.h"
#import "LiveConfig.h"
#import "IAHuitiRtmp.h"

@import AVFoundation;

@class H264HwEncoderImpl;

typedef void(^IAInitialFinishedHandler)(void);
typedef void(^IACompoundFinishedHandler)(void);

@protocol H264HwEncoderImplDelegate <NSObject>

- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps object:(H264HwEncoderImpl*)object;
- (void)gotEncodedData:(NSData*)aData isKeyFrame:(BOOL)isKeyFrame timeDuration:(long long)duration object:(H264HwEncoderImpl*)object;

@end

@interface H264HwEncoderImpl : NSObject

@property (weak, nonatomic) NSString *error;
@property (weak, nonatomic) id<H264HwEncoderImplDelegate> delegate;
@property (assign, nonatomic) PABitRate  bitRate;
@property (nonatomic,assign)BOOL         shouldDiscardframe;

-(id)initWithFirstFrameEncodedHandler:(IAInitialFinishedHandler)handler compoundFinishedHandler:(IACompoundFinishedHandler)compoundFinishedHandler;

- (void) initWithConfiguration;
- (void) start:(int)width  height:(int)height;
- (void) initEncode:(int)width  height:(int)height;
- (void) changeResolution:(int)width  height:(int)height;
- (void) encode:(CMSampleBufferRef )sampleBuffer;
- (void)encodeWithImageBuffer:(CVImageBufferRef *)imageBuffer;
- (void) End;
-(void)showGameEvent:(BOOL)show;
-(BOOL)isEncoding;

-(IAMediaDataModel*)audioEncodedDataModel;
-(void)removeEncodedData:(IAMediaDataModel*)encodedModel;

-(int) SetScoreboardParameter:(int)paramID param1:(const char*)param1 param2:(const char*)param2
                       pSize1:(int)pSize1 pSize2:(int)pSize2;
-(int) SetEventString:(const char *)eventString;



@end
