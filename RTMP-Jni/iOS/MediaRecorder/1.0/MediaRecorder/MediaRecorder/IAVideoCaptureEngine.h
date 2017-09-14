//
//  IAVideoCaptureEngine.h
//  MediaRecorder
//
//  Created by Derek Lix on 15/12/17.
//  Copyright © 2015年 Derek Lix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface IAVideoCaptureEngine : NSObject

-(id)initWithSuperView:(UIView*)superView;

-(void)startVideoCapture;
-(void)endVideoCapture;

@end
