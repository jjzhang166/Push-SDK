//
//  FileMuxer.h
//  anchor
//
//  Created by wangyong on 2017/6/16.
//  Copyright © 2017年 PAJK. All rights reserved.
//

//#ifndef FileMuxer_h
//#define FileMuxer_h

#import <Foundation/Foundation.h>

@interface FileMuxer : NSObject

- (instancetype)initFileMuxer;
- (int)UninitFileMuxer;

-(int) FileMuxerOpenFilePath:(const char *)outputPath;
-(int) FileMuxerClose;

-(int) FileMuxerSetAudioParameter:(int)codecID birtate:(int)bitrate samplerate:(int)samplerate samplebit:(int)samplebit channels:(int)channels;
-(int) FileMuxerSetVideoParameter:(int)codecID birtate:(int)bitrate width:(int)width height:(int)height fps:(float)fps gopsize:(int)gopsize;
-(int) FileMuxerSetSPSPPSWith:(uint8_t *)sps  pps:(uint8_t *)pps spsLen:(int)spsLen ppsLen:(int)ppsLen;
-(int) FileMuxerInputAudioSample:(uint8_t *)data size:(int)size pts:(long long)pts dts:(long long)dts;
-(int) FileMuxerInputVideoSample:(uint8_t *)data size:(int)size pts:(long long)pts dts:(long long)dts keyframe:(bool)keyframe;

@end

