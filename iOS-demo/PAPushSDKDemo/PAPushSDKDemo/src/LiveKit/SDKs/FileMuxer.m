//
//  FileMuxer.m
//  anchor
//
//  Created by wangyong on 2017/6/16.
//  Copyright © 2017年 PAJK. All rights reserved.
//

#import "FileMuxer.h"

extern long long FileMuxerInit(void);
extern int FileMuxerUninit(long long nHandler);
extern int FileMuxerOpen(long long nHandler, const char *outputPath);
extern int FileMuxerClose(long long nHandler);
extern int FileMuxerSetAudioParameter(long long nHandler, int codecID, int bitrate, int samplerate, int samplebit, int channels);
extern int FileMuxerSetVideoParameter(long long nHandler, int codecID, int bitrate, int width, int height, float fps, int gopsize);
extern int FileMuxerSetSPSPPS(long long nHandler, uint8_t *sps, uint8_t *pps, int spsLen, int ppsLen);
extern int FileMuxerInputAudioSample(long long nHandler, uint8_t *data, int size, long long pts, long long dts);
extern int FileMuxerInputVideoSample(long long nHandler, uint8_t *data, int size, long long pts, long long dts, bool keyframe);


@interface FileMuxer ()

@property(nonatomic ,assign) long long fileHandler;

@end

@implementation FileMuxer

- (instancetype)initFileMuxer{
    
    if (self = [super init]) {
        self.fileHandler = FileMuxerInit();
    }
    return self;
    
}
- (int)UninitFileMuxer {
    return FileMuxerUninit(self.fileHandler);
}

- (int)FileMuxerOpenFilePath:(const char *)outputPath{
    return FileMuxerOpen(self.fileHandler, outputPath);
}

- (int)FileMuxerClose{
    return FileMuxerClose(self.fileHandler);
}

-(int) FileMuxerSetAudioParameter:(int)codecID birtate:(int)bitrate samplerate:(int)samplerate samplebit:(int)samplebit channels:(int)channels{
    return FileMuxerSetAudioParameter(self.fileHandler, codecID, bitrate, samplerate, samplebit, channels);
}

-(int) FileMuxerSetVideoParameter:(int)codecID birtate:(int)bitrate width:(int)width height:(int)height fps:(float)fps gopsize:(int)gopsize {
    return FileMuxerSetVideoParameter(self.fileHandler, codecID, bitrate, width, height, fps, gopsize);
}

-(int) FileMuxerSetSPSPPSWith:(uint8_t *)sps  pps:(uint8_t *)pps spsLen:(int)spsLen ppsLen:(int)ppsLen{
    return FileMuxerSetSPSPPS(self.fileHandler, sps, pps, spsLen, ppsLen);
}

-(int) FileMuxerInputAudioSample:(uint8_t *)data size:(int)size pts:(long long)pts dts:(long long)dts{
    return FileMuxerInputAudioSample(self.fileHandler, data, size, pts, dts);
}

-(int) FileMuxerInputVideoSample:(uint8_t *)data size:(int)size pts:(long long)pts dts:(long long)dts keyframe:(bool)keyframe{
    return FileMuxerInputVideoSample(self.fileHandler, data, size, pts, dts, keyframe);
}
@end
