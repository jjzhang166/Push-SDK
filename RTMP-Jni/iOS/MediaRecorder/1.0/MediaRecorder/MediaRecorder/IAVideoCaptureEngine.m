//
//  IAVideoCaptureEngine.m
//  MediaRecorder
//
//  Created by Derek Lix on 15/12/17.
//  Copyright © 2015年 Derek Lix. All rights reserved.
//

#import "IAVideoCaptureEngine.h"

@interface IAVideoCaptureEngine ()

@property(nonatomic, strong)UIView* superView;

@end

@implementation IAVideoCaptureEngine


-(id)initWithSuperView:(UIView*)superView{
    
    if (self = [super init]) {
        self.superView = superView;
    }
    return self;
}

-(void)startVideoCapture{
}
-(void)endVideoCapture{
}

@end
