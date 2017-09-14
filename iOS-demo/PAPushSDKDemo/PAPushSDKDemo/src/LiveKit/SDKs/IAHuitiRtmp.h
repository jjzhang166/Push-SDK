//
//  IAHuitiRtmp.h
//  MediaRecorder
//
//  Created by Eoollo on 16/5/31.
//  Copyright © 2016年 Derek Lix. All rights reserved.
//


#import <Foundation/Foundation.h>

//const int CONVERT_PARAM_ID_NONE = 0;
//const int CONVERT_PARAM_ID_TEAM = 1;
//const int CONVERT_PARAM_ID_SCORE = 2;
//const int CONVERT_PARAM_ID_TIME = 3;


@interface IARtmpSender:NSObject

@property(nonatomic,strong)NSString* numStr;

-(int) rtmpConnect:(const char *)url;
-(int) rtmpDisconnect;
-(int) setAbsoluteTimeMs:(int)time;
-(void) rtmpSetAudioInfo:(int)cha smapleRate:(int)samplerate sampleBit:(int)samplebit;
-(void) rtmpSetVideoInfo:(int)width height:(int)height fps:(int)fps;
-(int) rtmpSend:(uint8_t *)pBuffer bufLen:(int)bufLen type:(int)type timestamp:(int64_t)timestamp;

@end

@interface IARtmpCompound : NSObject

//inputColorType = outputColorType = 25
-(int) CompoundInit:(int)sportType input:(int)inputColorType outType:(int)outputColorType
              widht:(int)width height:(int)height;
-(int) CompoundUninit;
-(int) SetLogoFile:(const char *)logoFile;
-(int) Compound:(int)hasScoreboard hasEvent:(int)hasEvent
       videoBuf:(uint8_t *)videoBuf dstBuf:(uint8_t *)dstBuf;

//color = 0,size =20,alpha = 1
-(int) SetFontPFInfo:(const char*)fontFile color:(int)color size:(int)size alpha:(float)alpha;

//color = 0,size =32,alpha = 1
-(int) SetFontMisoBoldInfo:(const char*)fontFile
                     color:(int)color size:(int)size alpha:(float)alpha;

//param1 param2的长度，汉字算2，英文数字算1
-(int) SetScoreboardParameter:(int)paramID param1:(const char*)param1 param2:(const char*)param2
                       pSize1:(int)pSize1 pSize2:(int)pSize2;

-(int) SetEventString:(const char *)eventString;
//-(int) SetLogoInfo:(int)width height:(int)height left:(int)left top:(int)top right:(int)right bottom:(int)bottom logoData:(uint8_t *)logoData;
-(int) SetLogoRect:(int)left top:(int)top right:(int)right bottom:(int)bottom;
-(int) SetEventRect:(int)left top:(int)top right:(int)right bottom:(int)bottom;
-(int) SetBackgroundFile:(const char *)hostFile visitingFile:(const char *)visitingFile
                timeFile:(const char *)timeFile eventFile:(const char *)eventFile staticFile:(const char *)staticFile;
@end



