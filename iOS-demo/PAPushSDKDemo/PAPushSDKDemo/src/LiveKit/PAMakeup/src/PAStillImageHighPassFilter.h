//
//  PAStillImageHighPassFilter.h
//  PAMakeupDemo
//
//  Created by Derek Lix on 9/20/16.
//  Copyright © 2016 Derek Lix. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GPUImage.h"

@interface PAStillImageHighPassFilter : GPUImageFilterGroup

@property (nonatomic) CGFloat radiusInPixels;
@property (nonatomic,assign) CGFloat distanceNormalizationFactor;


@end
