//
//  HuitiRtmp.h
//  MediaRecorder
//
//  Created by 晖王 on 15/12/9.
//  Copyright © 2015年 晖王. All rights reserved.
//

#ifndef HuitiRtmp_h
#define HuitiRtmp_h

//extern  {

extern int  rtmpConnect(const char *url);
extern int rtmpDisconnect();
extern void rtmpSetAudioInfo(int channels, int sampleRate, int sampleBit);
extern void rtmpSetVideoInfo(int width, int height, int fps);

extern  int rtmpSend(uint8_t *pBuffer, int bufLen, int type, int64_t timestamp);

//}

#endif /* HuitiRtmp_h */
