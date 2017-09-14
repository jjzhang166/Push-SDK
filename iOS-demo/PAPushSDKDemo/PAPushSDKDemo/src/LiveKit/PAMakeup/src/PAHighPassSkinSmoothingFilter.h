//
//  PAHighPassSkinSmoothingFilter.h
//  PAMakeupDemo
//
//  Created by Derek Lix on 9/20/16.
//  Copyright © 2016 Derek Lix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"

typedef NS_ENUM(NSInteger, PAGPUImageHighPassSkinSmoothingRadiusUnit) {
    PAHighPassSkinSmoothingRadiusUnitPixel = 1,
    PAHighPassSkinSmoothingRadiusUnitFractionOfImageWidth = 2
};

@interface PAHighPassSkinSmoothingRadius : NSObject <NSCopying,NSSecureCoding>

@property (nonatomic,readwrite) CGFloat value;
@property (nonatomic,readonly) PAGPUImageHighPassSkinSmoothingRadiusUnit unit;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)radiusInPixels:(CGFloat)pixels;
+ (instancetype)radiusAsFractionOfImageWidth:(CGFloat)fraction;

@end

@interface PAHighPassSkinSmoothingFilter : GPUImageFilterGroup

@property (nonatomic) CGFloat amount;
@property (nonatomic,copy) NSArray *controlPoints; //value of Point
@property (nonatomic,strong) PAHighPassSkinSmoothingRadius *radius;
@property (nonatomic,assign) CGFloat blurRadius;
@property (nonatomic) CGFloat sharpnessFactor;

@property (nonatomic) CGFloat brightnessLevel;  //[0.0 2.0];
@property (nonatomic) CGFloat toneLevel;
@property (nonatomic) CGFloat saturation;

-(void)reset;


@end
