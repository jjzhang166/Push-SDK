//
//  PACameraFilterEngine.m
//  PAMakeupDemo
//
//  Created by Derek Lix on 9/20/16.
//  Copyright © 2016 Derek Lix. All rights reserved.
//

#import "PACameraFilterEngine.h"
#import "GPUImage.h"
#import "PACameraFilterEngine.h"
#import "GPUImageSaturationFilter.h"
#import "GPUImageWhiteBalanceFilter.h"
#import "PAHighPassSkinSmoothingFilter.h"
#import "GPUImageView.h"
#import "IAUtility.h"
#import "LFGPUImageBeautyFilter.h"
#import "LFGPUImageEmptyFilter.h"

//#define PA_UseMakeup_Filter  @"PA_UseMakeup_Filter"

#define ScreenWidth [[UIScreen mainScreen] bounds].size.width
#define ScreenHeight [[UIScreen mainScreen] bounds].size.height

#define PA_GPU_CALLBACK_FILTER

@interface PACameraFilterEngine()
    
    
    @property(nonatomic, assign) float smoothLevel;
    @property(nonatomic, assign) float brightnessLevel;
    @property(nonatomic, assign) float toneLevel;
    
    @property (nonatomic, strong) GPUImageStillCamera *videoCamera;
    @property (nonatomic, strong) GPUImageOutput<GPUImageInput> *filter;
    @property (nonatomic, strong) GPUImageView *gpuImageView;
    //@property (nonatomic, strong) GPUImageBrightnessFilter * brightnessFilter;
    @property (nonatomic, strong) PAHighPassSkinSmoothingFilter* highPassFilter;
    @property (nonatomic, strong) PALiveVideoConfiguration*       config;
    
    @property (nonatomic, strong) LFGPUImageBeautyFilter* beautyFilter;
    @property (nonatomic, strong) GPUImageAlphaBlendFilter *blendFilter;
    @property (nonatomic, strong) GPUImageUIElement *uiElementInput;
    @property (nonatomic, strong) GPUImageCropFilter *cropfilter;
    @property (nonatomic, strong) GPUImageOutput<GPUImageInput> *output;
    @property (nonatomic, copy) NSString*  sessionPreset;
    @property (nonatomic, strong) UIView *warterMarkView;
    @property (nonatomic, assign) BOOL mirror;
    @property (nonatomic, strong) GPUImageMovieWriter *movieWriter;
    @property (nonatomic, assign) BOOL saveLocalVideo;
    @property (nonatomic, strong) UIView *waterMarkContentView;
    @property (nonatomic, strong, nullable) NSURL *saveLocalVideoPath;
    
- (void)reset;
- (void)pauseCameraCapture;
- (void)resumeCameraCapture;
- (void)setOutputBufferWidth:(NSInteger)width;
- (void)setOutputBufferHeight:(NSInteger)height;
- (void)openCaptureTorch:(BOOL)au;
- (void *)getCurrentFilter;
- (void)setCurrentFilter:(void *)filter;
- (void)setFilterWithImage:(NSString *)imageName;
- (void)useBlurFilter;
- (void)capturePhotoAsImageProcessedUpToFilter:(void *)finalFilterInChain withCompletionHandler:(void (^)(UIImage *processedImage, NSError *error))block;
    
    
    @end

@implementation PACameraFilterEngine
    
- (void)didOutputVideoSampleBuffer:(CVPixelBufferRef)pixelBuffer
    {
        if(self.delegate && [self.delegate respondsToSelector:@selector(cameraOutputBuffer:)])
        {
            [self.delegate cameraOutputBuffer:pixelBuffer];
        }
        
    }
    
    
- (void)setOutputBufferWidth:(NSInteger)width
    {
        if(_videoCamera)
        {
            [_videoCamera setOutputWidth:(int)width];
        }
    }
    
- (void)setOutputBufferHeight:(NSInteger)height
    {
        if(_videoCamera)
        {
            [_videoCamera setOutputWidth:(int)height];
        }
    }
    
    
    //self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetiFrame960x540 cameraPosition:AVCaptureDevicePositionFront];
    //self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    //self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    //self.filterView = [[GPUImageView alloc] initWithFrame:self.view.frame];
    //self.filterView.center = self.view.center;
    //
    //[self.view addSubview:self.filterView];
    //[self.videoCamera addTarget:self.filterView];
    //[self.videoCamera startCameraCapture];
    
    
- (void)setDisplayView:(UIView*)view
    {
        
        if(!_gpuImageView)
        {
            _preView = view;
            _gpuImageView = [[GPUImageView alloc] initWithFrame:view.bounds];
            
            _gpuImageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
            [_preView addSubview:_gpuImageView];
            [_videoCamera removeAllTargets];
            [_videoCamera addTarget:_gpuImageView];
            _gpuImageView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
            [_gpuImageView setEnabled:YES];
            [_gpuImageView setBackgroundColor:[UIColor blackColor]];
            //

            //setup watermark
//            [self setupWaterMarkView];

        }
}

-(void)setupWaterMarkView{
    
    CGFloat topY = 100.f;
    UIImageView* imageView = [[UIImageView alloc] init];
    imageView.alpha = 0.8f;
    CGRect imageRect = CGRectMake(0, topY, 186, 60);
    imageView.frame = imageRect;
    imageView.image = [UIImage imageNamed:@"live_logo"];
    self.warterMarkView = imageView;
}

- (UIView *)waterMarkContentView{
    if(!_waterMarkContentView){
        _waterMarkContentView = [[UIView alloc] init];
        _waterMarkContentView.frame = CGRectMake(0, 0, 540,960);
        _waterMarkContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _waterMarkContentView;
}

    
- (void)enableMakeupFilter{
    
#ifdef PA_UseMakeup_Filter
    
    NSLog(@"enableMakeupFilter");
    self.filterOn = YES;
    [_videoCamera removeTarget:self.gpuImageView];
    self.highPassFilter = [[PAHighPassSkinSmoothingFilter alloc] init];
    self.highPassFilter.amount = 0.75f;
    [_videoCamera addTarget:self.highPassFilter];
    self.filter = self.highPassFilter;
    [self.highPassFilter addTarget:_gpuImageView];
    
#ifdef PA_GPU_CALLBACK_FILTER
    __weak typeof(self) _self = self;
    [self.highPassFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        if(YES==_self.bufferProcessing)
        return;
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            _self.bufferProcessing = YES;
            [_self didOutputVideoSampleBuffer:[output PixelBufferOutput]];
            _self.bufferProcessing = NO;
        });
    }];
#endif
    
#else
    
    [self reloadFilter:YES];
    
#endif
}
    
- (void)reloadFilter:(BOOL)beautyFace{
    
    [self.filter removeAllTargets];
    [self.blendFilter removeAllTargets];
    [self.uiElementInput removeAllTargets];
    [self.videoCamera removeAllTargets];
    [self.output removeAllTargets];
    [self.cropfilter removeAllTargets];
    
    if (beautyFace) {
        self.output = [[LFGPUImageEmptyFilter alloc] init];
        self.filter = [[LFGPUImageBeautyFilter alloc] init];
        self.beautyFilter = (LFGPUImageBeautyFilter*)self.filter;
    } else {
        self.output = [[LFGPUImageEmptyFilter alloc] init];
        self.filter = [[LFGPUImageEmptyFilter alloc] init];
        self.beautyFilter = nil;
    }
    
    //        ///< 调节镜像
    //        [self reloadMirror];
    //
    //< 480*640 比例为4:3  强制转换为16:9
    if(self.sessionPreset&&[self.sessionPreset isEqualToString:AVCaptureSessionPreset640x480]){
        //   CGRect cropRect = self.configuration.landscape ? CGRectMake(0, 0.125, 1, 0.75) : CGRectMake(0.125, 0, 0.75, 1);
        CGRect cropRect = CGRectMake(0.125, 0, 0.75, 1);
        self.cropfilter = [[GPUImageCropFilter alloc] initWithCropRegion:cropRect];
        [self.videoCamera addTarget:self.cropfilter];
        [self.cropfilter addTarget:self.filter];
    }else{
        [self.videoCamera addTarget:self.filter];
    }
    
    //< 添加水印
    if(self.warterMarkView){
        
        [self.filter addTarget:self.blendFilter];
        [self.uiElementInput addTarget:self.blendFilter];
        [self.blendFilter addTarget:self.gpuImageView];
        if(self.saveLocalVideo) [self.blendFilter addTarget:self.movieWriter];
        [self.filter addTarget:self.output];
        [self.uiElementInput update];
    }else{
        
        [self.filter addTarget:self.output];
        [self.output addTarget:self.gpuImageView];
        // if(self.saveLocalVideo) [self.output addTarget:self.movieWriter];
    }
    
    
    CGSize videoSize = CGSizeMake(540, 960);
    [self.filter forceProcessingAtSize:videoSize];
    [self.output forceProcessingAtSize:videoSize];
    [self.blendFilter forceProcessingAtSize:videoSize];
    [self.uiElementInput forceProcessingAtSize:videoSize];
    
    
    //< 输出数据
    __weak typeof(self) _self = self;
    [self.output setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        if(YES==_self.bufferProcessing)
            return;
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            _self.bufferProcessing = YES;
            [_self didOutputVideoSampleBuffer:[output PixelBufferOutput]];
            _self.bufferProcessing = NO;
        });
    }];

}

- (GPUImageAlphaBlendFilter *)blendFilter{
    if(!_blendFilter){
        _blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        _blendFilter.mix = 1.0;
        [_blendFilter disableSecondFrameCheck];
    }
    return _blendFilter;
}

- (GPUImageUIElement *)uiElementInput{
    if(!_uiElementInput){
        _uiElementInput = [[GPUImageUIElement alloc] initWithView:self.waterMarkContentView];
    }
    return _uiElementInput;
}
    
- (void)reloadMirror{
    if(self.mirror && self.captureDevicePosition == AVCaptureDevicePositionFront){
        self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    }else{
        self.videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    }
}
    
- (void)setWarterMarkView:(UIView *)warterMarkView{
    if(_warterMarkView && _warterMarkView.superview){
        [_warterMarkView removeFromSuperview];
        _warterMarkView = nil;
    }
    _warterMarkView = warterMarkView;
    self.blendFilter.mix = warterMarkView.alpha;
    [self.waterMarkContentView addSubview:_warterMarkView];
    [self reloadFilter:YES];
}

    //- (GPUImageMovieWriter*)movieWriter{
    //        if(!_movieWriter){
    //            _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.saveLocalVideoPath size:self.configuration.videoSize];
    //            _movieWriter.encodingLiveVideo = YES;
    //            _movieWriter.shouldPassthroughAudio = YES;
    //            self.videoCamera.audioEncodingTarget = self.movieWriter;
    //        }
    //        return _movieWriter;
    //}
    
    
    static float blurR = 0;
    
-(void)moreBlurrrer{
    
    blurR+= 4;
    ((GPUImageGaussianBlurFilter*)self.filter).blurRadiusInPixels =blurR;
}
    
-(void)reset{
    if (self.highPassFilter) {
        [self.highPassFilter reset];
    }
}
    
- (void)disableMakeupFilter{
    NSLog(@"disableMakeupFilter");
    
#ifdef PA_UseMakeup_Filter
    
    self.filterOn = NO;
    [self.videoCamera removeTarget:_highPassFilter];
    [self.videoCamera addTarget:self.gpuImageView];
    
    
#else
    
    [self reloadFilter:NO];
    
#endif
    
}
    
-(void)setSmoothLevel:(float)smoothLevel{
    
    _smoothLevel = smoothLevel;
    
    self.highPassFilter.radius = [PAHighPassSkinSmoothingRadius radiusInPixels:smoothLevel];
    [self.highPassFilter reset];
    
    [_videoCamera addTarget:self.highPassFilter];
    self.filter = self.highPassFilter;
    [self.highPassFilter addTarget:_gpuImageView];
}
    
-(void)setBrightnessLevel:(float)brightnessLevel{
    
    _brightnessLevel = brightnessLevel;
    if (self.highPassFilter) {
        self.highPassFilter.brightnessLevel = brightnessLevel;
    }
    
}
    
    
-(void)setToneLevel:(float)toneLevel{
    
    _toneLevel = toneLevel;
    if (self.highPassFilter) {
        self.highPassFilter.toneLevel = toneLevel;
    }
}
    
-(void)configMakeup:(float)smooth  brightness:(float)brightness tone:(float)tone{
    
#ifdef PA_UseMakeup_Filter
    
    //reset config
    _smoothLevel = smooth;
    _brightnessLevel = brightness;
    _toneLevel = tone;
    
    //setup config
    CGFloat resultSmooth  = [self adjustSmooth:smooth];
    float   resultBrightness = [self adjustBrightness:brightness];
    float   resultTone = [self adjustTone:tone];
    self.highPassFilter.radius.value = resultSmooth;
    [self.highPassFilter reset];
    self.highPassFilter.brightnessLevel = resultBrightness;
    self.highPassFilter.toneLevel = resultTone;
    
#else
    
    if (self.beautyFilter) {
        self.beautyFilter.beautyLevel = smooth;
        self.beautyFilter.brightLevel = brightness;
        self.beautyFilter.toneLevel = tone;
    }
    
#endif
    
    
    
}
    
    //    @property (nonatomic, assign) CGFloat beautyLevel;
    //    @property (nonatomic, assign) CGFloat brightLevel;
    //    @property (nonatomic, assign) CGFloat toneLevel;
    
-(float)adjustSmooth:(float)smooth{
    float value = [self frozenRange:smooth];
    float result  = 7*value;
    return result;
}
    
    
-(float)adjustBrightness:(float)brightness{
    
    float result = brightness ;
    result = [self frozenRange:brightness]/2;
    result = 0.7+result;
    return result;
}
    
-(float)adjustTone:(float)tone{
    
    float result = -[self frozenRange:tone]*10;
    return result;
}
    
-(float) frozenRange:(float)value{
    
    float result = value ;
    result = value<0.0?0.0:value;
    result = result>1.0?1.0:value;
    return result;
}
    
    
-(void)setSkinSmooth:(CGFloat)skinsmooth{
    
}
    
- (instancetype)initWithAVCaptureSessionPreset:(NSString *const)sessionPreset position:(AVCaptureDevicePosition)position config:(PALiveVideoConfiguration *)config
    
    {
        if(self=[super init])
        {
            self.filterOn = NO;
            self.bufferProcessing = NO;
            self.config = config;
            
            self.sessionPreset = sessionPreset;
            
            _videoCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:sessionPreset cameraPosition:position];
            if (_videoCamera==nil) {
                [[NSNotificationCenter defaultCenter] postNotificationName:PA_VIDEOHARDWARE_LOADERROR object:nil];
            }
            
            if ([IAUtility isIphone7]) {//make sure 16:9
            }else if ([IAUtility moreThanIphone6]){
            }else{
                //            [_videoCamera setOutputWidth:360];
                //            [_videoCamera setOutputHeight:640];
            }
            
            [_videoCamera setHorizontallyMirrorFrontFacingCamera:NO];
            _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
#ifndef PA_GPU_CALLBACK_FILTER
            [_videoCamera setDelegate:(id)self];
#endif
        }
        return self;
    }
    
    
- (void)startCameraCapture;
    {
        if(_videoCamera)
        {
            [_videoCamera startCameraCapture];
        }
    }
    
- (void)stopCameraCapture;
    {
        if(_videoCamera)
        {
            [_videoCamera stopCameraCapture];
        }
    }
    
- (void)pauseCameraCapture;
    {
        if(_videoCamera)
        {
            [_videoCamera pauseCameraCapture];
        }
    }
    
    
- (void)resumeCameraCapture;
    {
        if(_videoCamera)
        {
            [_videoCamera resumeCameraCapture];
        }
    }
    
    
- (void)openCaptureTorch:(BOOL)au
    {
        if(_videoCamera)
        {
            [_videoCamera openCaptureTorch:au];
        }
    }
    
- (void)swapFrontAndBackCameras:(AVCaptureDevicePosition)devicePosition
{
    if(_videoCamera)
    {
        [_videoCamera swapFrontAndBackCameras:devicePosition];
        if (devicePosition == AVCaptureDevicePositionBack) {
            _gpuImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        }else{
            _gpuImageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        }
    }
}

-(AVCaptureDevicePosition)captureDevicePosition{
    
    if (_videoCamera) {
        return _videoCamera.cameraPosition;
    }
    return AVCaptureDevicePositionUnspecified;
    
}
    
- (void)capturePhotoAsImageProcessedUpToFilter:(void *)finalFilterInChain withCompletionHandler:(void (^)(UIImage *processedImage, NSError *error))block;
    {
        if(_videoCamera)
        {
            [_videoCamera capturePhotoAsImageProcessedUpToFilter:(__bridge GPUImageOutput<GPUImageInput> *)finalFilterInChain withCompletionHandler:block];
        }
    }
    
- (void *)getCurrentFilter
{
    return (__bridge void *)self.filter;
}

- (void)setCurrentFilter:(void *)filter
    {
        [_videoCamera removeAllTargets];
        [_filter removeAllTargets];
        [_videoCamera addTarget:(__bridge id<GPUImageInput>)filter];
        [_filter addTarget:self.gpuImageView];
        
        _filter = (__bridge id<GPUImageInput>)filter;
    }
    
- (void)setFilterWithImage:(NSString *)imageName
    {
        [_videoCamera removeAllTargets];
        [_filter removeAllTargets];
        
        GPUImageMissEtikateFilter *etikateFilter = [[GPUImageMissEtikateFilter alloc] initWithImage:imageName];
        [etikateFilter addTarget:self.gpuImageView];
        [_videoCamera addTarget:etikateFilter];
        _filter = etikateFilter;
    }
    
- (void)useBlurFilter;
    {
        [_videoCamera removeAllTargets];
        [_filter removeAllTargets];
        
        GPUImageiOSBlurFilter *blurFilter = [[GPUImageiOSBlurFilter alloc] init];
        [blurFilter addTarget:self.gpuImageView];
        [_videoCamera addTarget:blurFilter];
        
        _filter = blurFilter;
    }

    
- (void)focusInPoint:(CGPoint)devicePoint {
    [_videoCamera focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:CGPointMake(devicePoint.x/ScreenWidth, devicePoint.y/ScreenHeight) monitorSubjectAreaChange:YES];
}

- (void)setAppOnScreen:(BOOL)onScreen{
    if (_videoCamera) {
        [_videoCamera setAppOnScreen:onScreen];
    }
}
    
@end
