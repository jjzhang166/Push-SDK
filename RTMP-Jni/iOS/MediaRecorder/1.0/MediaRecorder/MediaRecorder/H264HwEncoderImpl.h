//
//  H264HwEncoderImpl.h
//  h264v1
//
//  Created by Ganvir, Manish on 3/31/15.
//  Copyright (c) 2015 Ganvir, Manish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IAMediaDataModel.h"

@import AVFoundation;
@protocol H264HwEncoderImplDelegate <NSObject>

- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps;
- (void)gotEncodedData:(NSData*)aData isKeyFrame:(BOOL)isKeyFrame timeDuration:(long long)duration;

@end
@interface H264HwEncoderImpl : NSObject 

- (void) initWithConfiguration;
- (void) start:(int)width  height:(int)height;
- (void) initEncode:(int)width  height:(int)height;
- (void) changeResolution:(int)width  height:(int)height;
- (void) encode:(CMSampleBufferRef )sampleBuffer;
- (void) End;

-(IAMediaDataModel*)audioEncodedDataModel;
-(void)removeEncodedData:(IAMediaDataModel*)encodedModel;


@property (weak, nonatomic) NSString *error;
@property (weak, nonatomic) id<H264HwEncoderImplDelegate> delegate;
@property (strong, nonatomic) NSString*  bitRate;

@end
