//
//  PAHighPassSkinSmoothingFilter.m
//  PAMakeupDemo
//
//  Created by Derek Lix on 9/20/16.
//  Copyright © 2016 Derek Lix. All rights reserved.
//

#import "PAHighPassSkinSmoothingFilter.h"
#import "PAStillImageHighPassFilter.h"
#import "GPUImageThreeInputFilter.h"


#define PA_DiffBlend_Key    @"PA_DiffBlend_Key"


@interface PAGPUImageCombinationFilter : GPUImageThreeInputFilter
{
    GLint smoothDegreeUniform;
}

@property (nonatomic, assign) CGFloat intensity;

@end

NSString *const kPAGPUImageBeautifyFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 varying highp vec2 textureCoordinate3;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform sampler2D inputImageTexture3;
 uniform mediump float smoothDegree;
 
 void main()
 {
     highp vec4 bilateral = texture2D(inputImageTexture, textureCoordinate);
     highp vec4 canny = texture2D(inputImageTexture2, textureCoordinate2);
     highp vec4 origin = texture2D(inputImageTexture3,textureCoordinate3);
     highp vec4 smooth;
     lowp float r = origin.r;
     lowp float g = origin.g;
     lowp float b = origin.b;
     if (canny.r < 0.2 && r > 0.3725 && g > 0.1568 && b > 0.0784 && r > b && (max(max(r, g), b) - min(min(r, g), b)) > 0.0588 && abs(r-g) > 0.0588) {
         smooth = (1.0 - smoothDegree) * (origin - bilateral) + bilateral;
     }
     else {
         smooth = origin;
     }
     smooth.r = log(1.0 + 0.2 * smooth.r)/log(1.2);
     smooth.g = log(1.0 + 0.2 * smooth.g)/log(1.2);
     smooth.b = log(1.0 + 0.2 * smooth.b)/log(1.2);
     gl_FragColor = smooth;
 }
 );

@implementation PAGPUImageCombinationFilter

- (id)init {
    if (self = [super initWithFragmentShaderFromString:kPAGPUImageBeautifyFragmentShaderString]) {
        smoothDegreeUniform = [filterProgram uniformIndex:@"smoothDegree"];
    }
    self.intensity = 0.66;
    return self;
}

- (void)setIntensity:(CGFloat)intensity {

    _intensity = intensity;
    [self setFloat:intensity forUniform:smoothDegreeUniform program:filterProgram];
}

@end


NSString * const CIHighPassSkinSmoothingMaskBoostFilterFragmentShaderString =
SHADER_STRING
(
 precision lowp float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 
 void main() {
     vec4 color = texture2D(inputImageTexture,textureCoordinate);
     
     float hardLightColor = color.b;
     for (int i = 0; i < 3; ++i)
     {
         if (hardLightColor < 0.5) {
             hardLightColor = hardLightColor  * hardLightColor * 2.;
         } else {
             hardLightColor = 1. - (1. - hardLightColor) * (1. - hardLightColor) * 2.;
         }
     }
     
     float k = 255.0 / (164.0 - 75.0);
     hardLightColor = (hardLightColor - 75.0 / 255.0) * k;
     
     gl_FragColor = vec4(vec3(hardLightColor),color.a);
 }
 );

NSString * const GPUImageGreenAndBlueChannelOverlayFragmentShaderString =
SHADER_STRING
(
 precision lowp float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 
 void main() {
     vec4 image = texture2D(inputImageTexture, textureCoordinate);
     vec4 base = vec4(image.g,image.g,image.g,1.0);
     vec4 overlay = vec4(image.b,image.b,image.b,1.0);
     float ba = 2.0 * overlay.b * base.b + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
     gl_FragColor = vec4(ba,ba,ba,image.a);
 }
 );

@interface PAHighPassSkinSmoothingMaskGenerator : GPUImageFilterGroup

@property (nonatomic) CGFloat highPassRadiusInPixels;

@property (nonatomic,weak) PAStillImageHighPassFilter *highPassFilter;


@end

@implementation PAHighPassSkinSmoothingMaskGenerator

- (instancetype)init {
    if (self = [super init]) {
        GPUImageFilter *channelOverlayFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromString:GPUImageGreenAndBlueChannelOverlayFragmentShaderString];
        [self addFilter:channelOverlayFilter];
        
        PAStillImageHighPassFilter *highpassFilter = [[PAStillImageHighPassFilter alloc] init];
        [self addFilter:highpassFilter];
        self.highPassFilter = highpassFilter;
        
        //
        //        GPUImageBrightnessFilter *passthroughFilter = [[GPUImageBrightnessFilter alloc] init];
        //        passthroughFilter.brightness +=0.8;
        //        [self addFilter:passthroughFilter];
        
        GPUImageFilter *maskBoostFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromString:CIHighPassSkinSmoothingMaskBoostFilterFragmentShaderString];
        [self addFilter:maskBoostFilter];
        
        
        [channelOverlayFilter addTarget:highpassFilter];
        [highpassFilter addTarget:maskBoostFilter];
        
        self.initialFilters = @[channelOverlayFilter];
        self.terminalFilter = maskBoostFilter;
    }
    return self;
}

- (void)setHighPassRadiusInPixels:(CGFloat)highPassRadiusInPixels {

    self.highPassFilter.radiusInPixels = highPassRadiusInPixels;
}

- (CGFloat)highPassRadiusInPixels {

    return self.highPassFilter.radiusInPixels;
}

@end

@interface PAHighPassSkinSmoothingRadius ()

//@property (nonatomic) CGFloat value;
@property (nonatomic) PAGPUImageHighPassSkinSmoothingRadiusUnit unit;

@end

@implementation PAHighPassSkinSmoothingRadius

+ (instancetype)radiusInPixels:(CGFloat)pixels {
    PAHighPassSkinSmoothingRadius *radius = [PAHighPassSkinSmoothingRadius new];
    radius.unit =  PAHighPassSkinSmoothingRadiusUnitPixel;
    radius.value = pixels;
    return radius;
}

+ (instancetype)radiusAsFractionOfImageWidth:(CGFloat)fraction {
    PAHighPassSkinSmoothingRadius *radius = [PAHighPassSkinSmoothingRadius new];
    radius.unit =  PAHighPassSkinSmoothingRadiusUnitFractionOfImageWidth;
    radius.value = fraction;
    return radius;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

-(void)setValue:(CGFloat)value{
    _value = value;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.value = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(value))] floatValue];
        self.unit = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(unit))] integerValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:@(self.value) forKey:NSStringFromSelector(@selector(value))];
    [aCoder encodeObject:@(self.unit) forKey:NSStringFromSelector(@selector(unit))];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end

NSString * const GPUImageHighpassSkinSmoothingCompositingFilterFragmentShaderString =
SHADER_STRING
(
 precision lowp float;
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 varying highp vec2 textureCoordinate3;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform sampler2D inputImageTexture3;
 
 void main() {
     vec4 image = texture2D(inputImageTexture, textureCoordinate);
     vec4 toneCurvedImage = texture2D(inputImageTexture2, textureCoordinate);
     vec4 mask = texture2D(inputImageTexture3, textureCoordinate);
     gl_FragColor = vec4(mix(image.rgb,toneCurvedImage.rgb,1.0 - mask.b),1.0);
 }
 );

@interface PAHighPassSkinSmoothingFilter ()

@property (nonatomic,weak) PAHighPassSkinSmoothingMaskGenerator *maskGenerator;

@property (nonatomic,weak) GPUImageDissolveBlendFilter *dissolveFilter;
@property (nonatomic,weak) GPUImageAddBlendFilter*       addFilter;

@property (nonatomic,weak) GPUImageSharpenFilter *sharpenFilter;

@property (nonatomic,weak) GPUImageToneCurveFilter *skinToneCurveFilter;

@property (nonatomic) CGSize currentInputSize;

@property (nonatomic,weak) GPUImageThreeInputFilter*   threeInputFilter;

@property (nonatomic,weak)GPUImageHSBFilter *hsbFilter;

@end

@implementation PAHighPassSkinSmoothingFilter

- (instancetype)init {
    if (self = [super init]) {
        
        GPUImageExposureFilter *exposureFilter = [[GPUImageExposureFilter alloc] init];
        exposureFilter.exposure = -1.0;
        [self addFilter:exposureFilter];
        
        
        PAHighPassSkinSmoothingMaskGenerator *maskGenerator = [[PAHighPassSkinSmoothingMaskGenerator alloc] init];
        [self addFilter:maskGenerator];
        self.maskGenerator = maskGenerator;
        [exposureFilter addTarget:maskGenerator];
        
        GPUImageToneCurveFilter *skinToneCurveFilter = [[GPUImageToneCurveFilter alloc] init];
        [self addFilter:skinToneCurveFilter];
        self.skinToneCurveFilter = skinToneCurveFilter;
        
#ifdef PA_DiffBlend_Key
        
        GPUImageDissolveBlendFilter *dissolveFilter = [[GPUImageDissolveBlendFilter alloc] init];
        [self addFilter:dissolveFilter];
        self.dissolveFilter = dissolveFilter;
        [skinToneCurveFilter addTarget:dissolveFilter atTextureLocation:1];
#else
//        GPUImageHardLightBlendFilter* highlightFilter = [[GPUImageHardLightBlendFilter alloc] init];
//        [self addTarget:highlightFilter];
//        [skinToneCurveFilter addTarget:highlightFilter atTextureLocation:1];

        GPUImageSoftLightBlendFilter* highlightFilter = [[GPUImageSoftLightBlendFilter alloc] init];
        [self addTarget:highlightFilter];
        [skinToneCurveFilter addTarget:highlightFilter atTextureLocation:1];

#endif
        

        
//        GPUImageAddBlendFilter*  addFilter = [[GPUImageAddBlendFilter alloc] init];
//        [self addFilter:addFilter];
//        self.addFilter = addFilter;
        
        
      //  [skinToneCurveFilter addTarget:addFilter atTextureLocation:1];
        
        GPUImageThreeInputFilter *composeFilter = [[GPUImageThreeInputFilter alloc] initWithFragmentShaderFromString:GPUImageHighpassSkinSmoothingCompositingFilterFragmentShaderString];
        [self addFilter:composeFilter];
        
        [maskGenerator addTarget:composeFilter atTextureLocation:2];
        
#ifdef PA_DiffBlend_Key
        [self.dissolveFilter addTarget:composeFilter atTextureLocation:1];
#else
        [highlightFilter addTarget:composeFilter atTextureLocation:1];
#endif
        
        
      //  [addFilter addTarget:composeFilter atTextureLocation:1];
        
        GPUImageSharpenFilter *sharpen = [[GPUImageSharpenFilter alloc] init];
        [self addFilter:sharpen];
        [composeFilter addTarget:sharpen];
        self.sharpenFilter = sharpen;
        
        //
        //        GPUImageBrightnessFilter *passthroughFilter = [[GPUImageBrightnessFilter alloc] init];
        //        passthroughFilter.brightness +=0.1;
        //        [self addFilter:passthroughFilter];
        //        [sharpen addTarget:passthroughFilter];
        
        // Adjust HSB
        GPUImageHSBFilter *hsbFilter = [[GPUImageHSBFilter alloc] init];
        [hsbFilter adjustBrightness:1.0f];
        [hsbFilter adjustSaturation:1.05];
        [self addFilter:hsbFilter];
        self.hsbFilter = hsbFilter;
        [sharpen addTarget:hsbFilter];
        
        
//        PAGPUImageCombinationFilter *combinationFilter = [[PAGPUImageCombinationFilter alloc] init];
//        [maskGenerator addTarget:combinationFilter atTextureLocation:3];
//        [self addFilter:combinationFilter];
//       // [exposureFilter addTarget:combinationFilter];
//        [skinToneCurveFilter addTarget:combinationFilter];
        
#ifdef PA_DiffBlend_Key
       // [dissolveFilter addTarget:combinationFilter];
        self.initialFilters = @[exposureFilter,skinToneCurveFilter,dissolveFilter,composeFilter];
#else
        [highlightFilter   addTarget:combinationFilter];
        self.initialFilters = @[exposureFilter,skinToneCurveFilter,highlightFilter,composeFilter,combinationFilter];
#endif
        

    //    self.initialFilters = @[exposureFilter,skinToneCurveFilter,addFilter,composeFilter,combinationFilter];
        self.terminalFilter = hsbFilter;
        
        
        
        //set defaults
        self.amount = 0.75;
        self.radius = [PAHighPassSkinSmoothingRadius radiusInPixels:4.5/750.0];
        self.sharpnessFactor = 0.4;
        
        CGPoint controlPoint0 = CGPointMake(0, 0);
      //  CGPoint controlPoint1 = CGPointMake(120/255.0, 146/255.0);
        CGPoint controlPoint1 = CGPointMake(120/255.0, 146/255.0);
        CGPoint controlPoint2 = CGPointMake(1.0, 1.0);
        
        //#if TARGET_OS_IOS
        self.controlPoints = @[[NSValue valueWithCGPoint:controlPoint0],
                               [NSValue valueWithCGPoint:controlPoint1],
                               [NSValue valueWithCGPoint:controlPoint2]];
        //#else
        //        self.controlPoints = @[[NSValue valueWithPoint:controlPoint0],
        //                               [NSValue valueWithPoint:controlPoint1],
        //                               [NSValue valueWithPoint:controlPoint2]];
        //#endif

    }
    return self;
}

#pragma mark -
#pragma mark GPUImageInput protocol

//- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
//{
//    for (GPUImageOutput<GPUImageInput> *currentFilter in self.initialFilters)
//    {
//        if (currentFilter != self.inputFilterToIgnoreForUpdates)
//        {
//            if (currentFilter == self.threeInputFilter) {
//                textureIndex = 3;
//            }
//            
//            [currentFilter newFrameReadyAtTime:frameTime atIndex:textureIndex];
//        }
//    }
//}
//
//- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
//{
//    for (GPUImageOutput<GPUImageInput> *currentFilter in self.initialFilters)
//    {
//        if (currentFilter == self.threeInputFilter) {
//            textureIndex = 3;
//        }
//        [currentFilter setInputFramebuffer:newInputFramebuffer atIndex:textureIndex];
//    }
//}


- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex {
    [super setInputSize:newSize atIndex:textureIndex];
    self.currentInputSize = newSize;
    [self updateHighPassRadius];
}

-(void)updateHighPassBlurRadius{
    
    CGSize inputSize = self.currentInputSize;
    if (inputSize.width * inputSize.height > 0) {
        CGFloat radiusInPixels = 0;
        radiusInPixels = self.blurRadius;
        if (radiusInPixels != self.maskGenerator.highPassRadiusInPixels) {
            self.maskGenerator.highPassRadiusInPixels = radiusInPixels;
        }
    }

}

- (void)updateHighPassRadius {
    CGSize inputSize = self.currentInputSize;
    if (inputSize.width * inputSize.height > 0) {
        CGFloat radiusInPixels = 0;
        
//        switch (self.radius.unit) {
//            case PAHighPassSkinSmoothingRadiusUnitPixel:{
//                radiusInPixels = self.radius.value;
//            }
//                
//            
//                break;
//            case PAHighPassSkinSmoothingRadiusUnitFractionOfImageWidth:{
//                radiusInPixels = ceil(inputSize.width * self.radius.value);
//            }
//                break;
//            default:
//                break;
//        }
        
        
        radiusInPixels = self.radius.value;
        if (radiusInPixels != self.maskGenerator.highPassRadiusInPixels) {
            self.maskGenerator.highPassRadiusInPixels = radiusInPixels;
        }
    }
}

- (void)setRadius:(PAHighPassSkinSmoothingRadius *)radius {
    _radius = radius.copy;
    [self updateHighPassRadius];
}

-(void)setBlurRadius:(CGFloat)blurRadius{
    _blurRadius = blurRadius;
    [self updateHighPassBlurRadius];
}

- (void)setControlPoints:(NSArray *)controlPoints {
    self.skinToneCurveFilter.rgbCompositeControlPoints = controlPoints;
}

- (NSArray *)controlPoints {
    return self.skinToneCurveFilter.rgbCompositeControlPoints;
}


// Sharpness ranges from -4.0 to 4.0, with 0.0 as the normal level
// Mix ranges from 0.0 (only image 1) to 1.0 (only image 2), with 0.5 (half of either) as the normal level

- (void)setAmount:(CGFloat)amount {
    _amount = amount;
#ifdef PA_DiffBlend_Key
    self.dissolveFilter.mix = amount;
#else
#endif

    CGFloat aSharpness =  self.sharpnessFactor*amount;
    aSharpness = 0.0;
    self.sharpenFilter.sharpness = aSharpness;

}

- (void)setSharpnessFactor:(CGFloat)sharpnessFactor {
    _sharpnessFactor = sharpnessFactor;
     CGFloat aSharpness =  sharpnessFactor*self.amount;
    aSharpness = 0.0;
    self.sharpenFilter.sharpness = aSharpness;
}

-(void)setBrightnessLevel:(CGFloat)brightnessLevel{
    
    _brightnessLevel = brightnessLevel;
    [self.hsbFilter adjustBrightness:brightnessLevel];
//    if (self.hsbFilter) {
//        [self.hsbFilter reset];
//        [self.hsbFilter adjustBrightness:brightnessLevel];
//    }
}

-(void)setToneLevel:(CGFloat)toneLevel{

    _toneLevel = toneLevel;
    [self.hsbFilter rotateHue:toneLevel];
    
//    if (self.hsbFilter) {
//        [self.hsbFilter reset];
//        [self.hsbFilter rotateHue:toneLevel];
//    }
}

-(void)setSaturation:(CGFloat)saturation{
    
    _saturation = saturation;
    [self.hsbFilter adjustSaturation:saturation];
}

-(void)reset{
    
    if (self.hsbFilter) {
        [self.hsbFilter reset];
    }
}

@end
