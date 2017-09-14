//
//  FirstViewController.h
//  MediaRecorder
//
//  Created by world on 16/1/6.
//  Copyright © 2016年 Derek Lix. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "H264HwEncoderImpl.h"
#import <AVFoundation/AVFoundation.h>

@protocol LiveRecordlDelegate <NSObject>

@required

- (void) stopLiveRecord;

@end


@interface FirstViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate,H264HwEncoderImplDelegate>

-(void)setRtmpUrl:(NSString*)pushUrl gameId:(NSString*)gameId token:(NSString*)token uid:(NSString*)uid env:(NSString*) env;

@property(nonatomic, weak) id delegate;

@end
