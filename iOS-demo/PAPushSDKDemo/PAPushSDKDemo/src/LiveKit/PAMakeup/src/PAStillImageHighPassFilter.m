//
//  PAStillImageHighPassFilter.m
//  PAMakeupDemo
//
//  Created by Derek Lix on 9/20/16.
//  Copyright © 2016 Derek Lix. All rights reserved.
//

#import "PAStillImageHighPassFilter.h"

NSString * const GPUImageStillImageHighPassFilterFragmentShaderString =
SHADER_STRING
(
 precision lowp float;
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main() {
     vec4 image = texture2D(inputImageTexture, textureCoordinate);
     vec4 blurredImage = texture2D(inputImageTexture2, textureCoordinate);
     gl_FragColor = vec4((image.rgb - blurredImage.rgb + vec3(0.5,0.5,0.5)), image.a);
 }
 );

@interface PAStillImageHighPassFilter ()

@property (nonatomic,weak) GPUImageGaussianBlurFilter *blurFilter;

@end

@implementation PAStillImageHighPassFilter

- (instancetype)init {
    if (self = [super init]) {
        GPUImageGaussianBlurFilter *blurFilter = [[GPUImageGaussianBlurFilter alloc] init];
        [self addFilter:blurFilter];
        self.blurFilter = blurFilter;

        GPUImageTwoInputFilter *filter = [[GPUImageTwoInputFilter alloc] initWithFragmentShaderFromString:GPUImageStillImageHighPassFilterFragmentShaderString];
        [self addFilter:filter];
        
        [self.blurFilter addTarget:filter atTextureLocation:1];
        
        self.initialFilters = @[self.blurFilter,filter];
        self.terminalFilter = filter;
    }
    return self;
}

- (void)setRadiusInPixels:(CGFloat)radiusInPixels {
    self.blurFilter.blurRadiusInPixels = radiusInPixels;
}

- (CGFloat)radiusInPixels {
    return self.blurFilter.blurRadiusInPixels;
}


@end
