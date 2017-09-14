//
//  IAHuitiRtmp.m
//  MediaRecorder
//
//  Created by Eoollo on 16/5/31.
//  Copyright © 2016年 Derek Lix. All rights reserved.
//

#import "IAHuitiRtmp.h"

extern int  rtmpConnect(const char *url);
extern int rtmpDisconnect();
extern int setAbsoluteTimeMs(int time);
extern void rtmpSetAudioInfo(int channels, int sampleRate, int sampleBit);
extern void rtmpSetVideoInfo(int width, int height, int fps);
extern  int rtmpSend(uint8_t *pBuffer, int bufLen, int type, int64_t timestamp);

extern int CompoundInit(int sportType, int inputColorType, int outputColorType, int width, int height);  //inputColorType = outputColorType = 25
extern int CompoundUninit(void);
extern int SetLogoFile(const char *logoFile);
extern int SetScoreboardFile(const char *scoreboardFile);
extern int Compound(int hasScoreboard, int hasEvent, uint8_t *videoBuf, uint8_t *dstBuf);
extern int SetFontPFInfo(const char* fontFile, int color, int size, float alpha); //color = 0,size =20,alpha = 1
extern int SetFontMisoBoldInfo(const char* fontFile, int color, int size, float alpha); //color = 0,size =32,alpha = 1
//extern int SetScoreboardParameter(int paramID, const char* param1, const char* param2); //color = 0,size =32,alpha = 1
extern int SetScoreboardParameter(int paramID, const char* param1, const char* param2, int pSize1, int pSize2); //param1 param2的长度，汉字算2，英文数字算1

extern int SetEventFile(const char *eventFile);
extern int SetEventString(const char *eventString);

//extern int SetLogoInfo(int width, int height, int left, int top, int right, int bottom, uint8_t* logoData);
extern int SetLogoRect(int left, int top, int right, int bottom);
extern int SetScoreboardRect(int left, int top, int right, int bottom);
extern int SetEventRect(int left, int top, int right, int bottom);
extern int SetBackgroundFile(const char *hostFile, const char *visitingFile,
                             const char *timeFile, const char *eventFile, const char *staticFile);

@implementation IARtmpSender

-(int)rtmpConnect:(const char*)url{
    return rtmpConnect(url);
}

-(int) rtmpDisconnect{
    return rtmpDisconnect();
}
-(int) setAbsoluteTimeMs:(int)time{
    return setAbsoluteTimeMs(time);
}

-(void) rtmpSetAudioInfo:(int)channels smapleRate:(int)sampleRate sampleBit:(int)sampleBit{
    rtmpSetAudioInfo(channels, sampleRate, sampleBit);
}

-(void) rtmpSetVideoInfo:(int)width height:(int)height fps:(int)fps{
    return rtmpSetVideoInfo(width, height, fps);
}
-(int) rtmpSend:(uint8_t *)pBuffer bufLen:(int)bufLen type:(int)type timestamp:(int64_t)timestamp{
    return rtmpSend(pBuffer, bufLen, type, timestamp);
}

@end

@implementation IARtmpCompound

//inputColorType = outputColorType = 25
-(int) CompoundInit:(int)sportType input:(int)inputColorType outType:(int)outputColorType
              widht:(int)width height:(int)height{
    CompoundUninit();
    return CompoundInit(sportType, inputColorType, outputColorType, width, height);
}

-(int) CompoundUninit{
    return CompoundUninit();
}

-(int) SetLogoFile:(const char *)logoFile{
    return SetLogoFile(logoFile);
}

-(int) Compound:(int)hasScoreboard hasEvent:(int)hasEvent
       videoBuf:(uint8_t *)videoBuf dstBuf:(uint8_t *)dstBuf{
    return Compound(hasScoreboard, hasEvent, videoBuf, dstBuf);
}


//color = 0,size =20,alpha = 1
-(int) SetFontPFInfo:(const char*)fontFile color:(int)color size:(int)size alpha:(float)alpha{
    return SetFontPFInfo(fontFile, color, size, alpha);
}

//color = 0,size =32,alpha = 1
-(int) SetFontMisoBoldInfo:(const char*)fontFile
                     color:(int)color size:(int)size alpha:(float)alpha{
    return SetFontMisoBoldInfo(fontFile, color, size, alpha);
}

//param1 param2的长度，汉字算2，英文数字算1
-(int) SetScoreboardParameter:(int)paramID param1:(const char*)param1 param2:(const char*)param2
                       pSize1:(int)pSize1 pSize2:(int)pSize2{
    return SetScoreboardParameter(paramID, param1, param2, pSize1, pSize2);
}

-(int) SetEventString:(const char *)eventString{
    return SetEventString(eventString);
}

//-(int) SetLogoInfo:(int)width height:(int)height left:(int)left top:(int)top right:(int)right bottom:(int)bottom logoData:(uint8_t *)logoData{
//    return SetLogoInfo(width, height, left, top, right, bottom, logoData);
//}

-(int) SetLogoRect:(int)left top:(int)top right:(int)right bottom:(int)bottom{
    return SetLogoRect(left, top, right, bottom);
}

-(int)SetEventRect:(int)left top:(int)top right:(int)right bottom:(int)bottom{
    return SetEventRect(left, top, right, bottom);
}

-(int) SetBackgroundFile:(const char *)hostFile visitingFile:(const char *)visitingFile
                timeFile:(const char *)timeFile eventFile:(const char *)eventFile staticFile:(const char *)staticFile{
    return SetBackgroundFile(hostFile, visitingFile,
                             timeFile, eventFile, staticFile);
}
@end


