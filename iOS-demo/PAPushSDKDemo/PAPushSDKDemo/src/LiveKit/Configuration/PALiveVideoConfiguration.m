//
//  PALiveVideoConfiguration.m
//  anchor
//
//  Created by wangweishun on 8/5/16.
//  Copyright © 2016 PAJK. All rights reserved.
//

#import "PALiveVideoConfiguration.h"
#import <AVFoundation/AVFoundation.h>

@implementation PALiveVideoConfiguration

#pragma mark -- LifeCycle
+ (instancetype)defaultConfiguration{
    PALiveVideoConfiguration *configuration = [PALiveVideoConfiguration defaultConfigurationForQuality:ELiveVideoQuality_Default];
    return configuration;
}

+ (instancetype)defaultConfigurationForQuality:(PALiveVideoQuality)videoQuality{
    PALiveVideoConfiguration *configuration = [PALiveVideoConfiguration defaultConfigurationForQuality:videoQuality orientation:UIInterfaceOrientationPortrait];
    return configuration;
}

+ (instancetype)defaultConfigurationForQuality:(PALiveVideoQuality)videoQuality orientation:(UIInterfaceOrientation)orientation{
    PALiveVideoConfiguration *configuration = [PALiveVideoConfiguration new];
    switch (videoQuality) {
        case ELiveVideoQuality_Low1:
        {
            configuration.sessionPreset = ECaptureSessionPreset368x640;
            configuration.videoFrameRate = 15;
            configuration.videoMaxFrameRate = 15;
            configuration.videoMinFrameRate = 10;
            configuration.videoBitRate = 500 * 1024;
            configuration.videoMaxBitRate = 600 * 1024;
            configuration.videoMinBitRate = 250 * 1024;
        }
            break;
        case ELiveVideoQuality_Low2:
        {
            configuration.sessionPreset = ECaptureSessionPreset368x640;
            configuration.videoFrameRate = 24;
            configuration.videoMaxFrameRate = 24;
            configuration.videoMinFrameRate = 12;
            configuration.videoBitRate = 800 * 1024;
            configuration.videoMaxBitRate = 900 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        case ELiveVideoQuality_Low3:
        {
            configuration.sessionPreset = ECaptureSessionPreset368x640;
            configuration.videoFrameRate = 30;
            configuration.videoMaxFrameRate = 30;
            configuration.videoMinFrameRate = 15;
            configuration.videoBitRate = 800 * 1024;
            configuration.videoMaxBitRate = 900 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        case ELiveVideoQuality_Medium1:
        {
            configuration.sessionPreset = ECaptureSessionPreset540x960;
            configuration.videoFrameRate = 15;
            configuration.videoMaxFrameRate = 15;
            configuration.videoMinFrameRate = 10;
            configuration.videoBitRate = 800 * 1024;
            configuration.videoMaxBitRate = 900 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        case ELiveVideoQuality_Medium2:
        {
            configuration.sessionPreset = ECaptureSessionPreset540x960;
            configuration.videoFrameRate = 24;
            configuration.videoMaxFrameRate = 24;
            configuration.videoMinFrameRate = 12;
            configuration.videoBitRate = 800 * 1024;
            configuration.videoMaxBitRate = 900 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        case ELiveVideoQuality_Medium3:
        {
            configuration.sessionPreset = ECaptureSessionPreset540x960;
            configuration.videoFrameRate = 30;
            configuration.videoMaxFrameRate = 30;
            configuration.videoMinFrameRate = 15;
            configuration.videoBitRate = 1000 * 1024;
            configuration.videoMaxBitRate = 1200 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        case ELiveVideoQuality_High1:
        {
            configuration.sessionPreset = ECaptureSessionPreset720x1280;
            configuration.videoFrameRate = 15;
            configuration.videoMaxFrameRate = 15;
            configuration.videoMinFrameRate = 10;
            configuration.videoBitRate = 1000 * 1024;
            configuration.videoMaxBitRate = 1200 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        case ELiveVideoQuality_High2:
        {
            configuration.sessionPreset = ECaptureSessionPreset720x1280;
            configuration.videoFrameRate = 24;
            configuration.videoMaxFrameRate = 24;
            configuration.videoMinFrameRate = 12;
            configuration.videoBitRate = 1200 * 1024;
            configuration.videoMaxBitRate = 1300 * 1024;
            configuration.videoMinBitRate = 800 * 1024;
        }
            break;
        case ELiveVideoQuality_High3:
        {
            configuration.sessionPreset = ECaptureSessionPreset720x1280;
            configuration.videoFrameRate = 30;
            configuration.videoMaxFrameRate = 30;
            configuration.videoMinFrameRate = 15;
            configuration.videoBitRate = 1200 * 1024;
            configuration.videoMaxBitRate = 1300 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        default:
            break;
    }
    configuration.sessionPreset = [configuration supportSessionPreset:configuration.sessionPreset];
    configuration.videoMaxKeyframeInterval = configuration.videoFrameRate*2;
    configuration.orientation = orientation;
    if(orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown){
        configuration.videoSize = CGSizeMake(368, 640);
    }else{
        configuration.videoSize = CGSizeMake(640, 368);
    }
    return configuration;
}

#pragma mark -- Setter Getter
- (NSString*)avSessionPreset{
    NSString *avSessionPreset = nil;
    switch (self.sessionPreset) {
        case ECaptureSessionPreset368x640:
        {
            avSessionPreset = AVCaptureSessionPreset640x480;
        }
            break;
        case ECaptureSessionPreset540x960:
        {
            avSessionPreset = AVCaptureSessionPresetiFrame960x540;
        }
            break;
        case ECaptureSessionPreset720x1280:
        {
            avSessionPreset = AVCaptureSessionPreset1280x720;
        }
            break;
        default:{
            avSessionPreset = AVCaptureSessionPreset640x480;
        }
            break;
    }
    return avSessionPreset;
}

#pragma mark -- Custom Method
- (PALiveVideoSessionPreset)supportSessionPreset:(PALiveVideoSessionPreset)sessionPreset{
    NSString *avSessionPreset = [self avSessionPreset];
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    
    if(![session canSetSessionPreset:avSessionPreset]){
        if(sessionPreset == ECaptureSessionPreset720x1280){
            sessionPreset = ECaptureSessionPreset540x960;
            if(![session canSetSessionPreset:avSessionPreset]){
                sessionPreset = ECaptureSessionPreset368x640;
            }
        }else if(sessionPreset == ECaptureSessionPreset540x960){
            sessionPreset = ECaptureSessionPreset368x640;
        }
    }
    return sessionPreset;
}

- (BOOL)isClipVideo{
    return self.sessionPreset == ECaptureSessionPreset368x640 ? YES : NO;
}

#pragma mark -- encoder
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:[NSValue valueWithCGSize:self.videoSize] forKey:@"videoSize"];
    [aCoder encodeObject:@(self.videoFrameRate) forKey:@"videoFrameRate"];
    [aCoder encodeObject:@(self.videoMaxKeyframeInterval) forKey:@"videoMaxKeyframeInterval"];
    [aCoder encodeObject:@(self.videoBitRate) forKey:@"videoBitRate"];
    [aCoder encodeObject:@(self.sessionPreset) forKey:@"sessionPreset"];
    [aCoder encodeObject:@(self.orientation) forKey:@"orientation"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    _videoSize = [[aDecoder decodeObjectForKey:@"videoSize"] CGSizeValue];
    _videoFrameRate = [[aDecoder decodeObjectForKey:@"videoFrameRate"] unsignedIntegerValue];
    _videoMaxKeyframeInterval = [[aDecoder decodeObjectForKey:@"videoMaxKeyframeInterval"] unsignedIntegerValue];
    _videoBitRate = [[aDecoder decodeObjectForKey:@"videoBitRate"] unsignedIntegerValue];
    _sessionPreset = [[aDecoder decodeObjectForKey:@"sessionPreset"] unsignedIntegerValue];
    _orientation = [[aDecoder decodeObjectForKey:@"orientation"] unsignedIntegerValue];
    return self;
}

- (NSUInteger)hash {
    NSUInteger hash = 0;
    NSArray *values = @[[NSValue valueWithCGSize:self.videoSize],
                        @(self.videoFrameRate),
                        @(self.videoMaxFrameRate),
                        @(self.videoMinFrameRate),
                        @(self.videoMaxKeyframeInterval),
                        @(self.videoBitRate),
                        @(self.videoMaxBitRate),
                        @(self.videoMinBitRate),
                        @(self.isClipVideo),
                        self.avSessionPreset,
                        @(self.sessionPreset),
                        @(self.orientation),];
    
    for (NSObject *value in values) {
        hash ^= value.hash;
    }
    return hash;
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    } else {
        PALiveVideoConfiguration *object = other;
        return CGSizeEqualToSize(object.videoSize, self.videoSize)  &&
        object.videoFrameRate == self.videoFrameRate &&
        object.videoMaxFrameRate == self.videoMaxFrameRate &&
        object.videoMinFrameRate == self.videoMinFrameRate &&
        object.videoMaxKeyframeInterval == self.videoMaxKeyframeInterval &&
        object.videoBitRate == self.videoBitRate &&
        object.videoMaxBitRate == self.videoMaxBitRate &&
        object.videoMinBitRate == self.videoMinBitRate &&
        object.isClipVideo == self.isClipVideo &&
        [object.avSessionPreset isEqualToString:self.avSessionPreset] &&
        object.sessionPreset == self.sessionPreset &&
        object.orientation == self.orientation;
    }
}

- (id)copyWithZone:(nullable NSZone *)zone{
    PALiveVideoConfiguration *other = [self.class defaultConfiguration];
    return other;
}

- (NSString *)description{
    NSMutableString *desc = @"".mutableCopy;
    [desc appendFormat:@"<PALiveVideoConfiguration: %p>",self];
    [desc appendFormat:@" videoSize:%@",NSStringFromCGSize(self.videoSize)];
    [desc appendFormat:@" videoFrameRate:%zi",self.videoFrameRate];
    [desc appendFormat:@" videoMaxFrameRate:%zi",self.videoMaxFrameRate];
    [desc appendFormat:@" videoMinFrameRate:%zi",self.videoMinFrameRate];
    [desc appendFormat:@" videoMaxKeyframeInterval:%zi",self.videoMaxKeyframeInterval];
    [desc appendFormat:@" videoBitRate:%zi",self.videoBitRate];
    [desc appendFormat:@" videoMaxBitRate:%zi",self.videoMaxBitRate];
    [desc appendFormat:@" videoMinBitRate:%zi",self.videoMinBitRate];
    [desc appendFormat:@" isClipVideo:%zi",self.isClipVideo];
    [desc appendFormat:@" avSessionPreset:%@",self.avSessionPreset];
    [desc appendFormat:@" sessionPreset:%zi",self.sessionPreset];
    [desc appendFormat:@" orientation:%zi",self.orientation];
    return desc;
}

@end
