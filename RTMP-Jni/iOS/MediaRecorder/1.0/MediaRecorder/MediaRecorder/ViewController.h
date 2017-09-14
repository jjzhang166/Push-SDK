//
//  ViewController.h
//  MediaRecorder
//
//  Created by 晖王 on 15/12/8.
//  Copyright © 2015年 晖王. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "H264HwEncoderImpl.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate,H264HwEncoderImplDelegate>


@end

