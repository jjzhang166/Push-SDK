//
//  LiveConfig.h
//  anchor
//
//  Created by wangweishun on 8/4/16.
//  Copyright © 2016 PAJK. All rights reserved.
//

#ifndef LiveConfig_h
#define LiveConfig_h


typedef enum : NSUInteger{
    NONE_BLOCK = 0,
    VIDEODEVICE_LOAD_FAIL,
    VIDEO_SEND_BLOCKED,
    VIDEO_ENCODER_BLOCKED,
    VIDEO_CAPTURE_BLOCKED,
    VIDEO_ENCODER_DROPPED,
    VIDEO_BLOCKED_UNKNOWN,
    AUDIODEVICE_LOAD_FAIL,
    AUDIO_SEND_BLOCKED,
    AUDIO_ENCODER_BLOCKED,
    AUDIO_CAPTURE_BLOCKED,
    AUDIO_ENCODER_DROPPED,
    AUDIO_BLOCKED_UNKNOWN,
}PA_BLOCK_STATUS_TYPE;

typedef enum : NSUInteger {
    PA_START = 1,
    PA_PUSH_STREAM = 2,
    PA_STOP = 3,
    PA_OTHER = 4,
    PA_PUSH_SPEED = 5,
    PA_VIDEO_AUTHOR_FAIL = 6,
    PA_AUDIO_AUTHOR_FAIL = 7,
    PA_PUSH_EXCEPTION = 8,
} PAEventCode;

typedef enum : NSUInteger {
    IA_2M,
    IA_1Dot5M,
    IA_1M,
    IA_700K,
    IA_512K,
    IA_550K,
    IA_450K
} PABitRate;

typedef enum : NSUInteger {
    IA_720P,
    IA_540P
} PADefinition;

#define IA_Debug_Key            @"IA_Debug_Key"


#define IA_SendAudioThread_Key  @"IA_SendAudioThread_Key"
#define IA_CoustomRtmpThread_Key    @"IA_CoustomRtmpThread_Key"

//#define IA_RecordLocal_Key     @"IA_RecordLocal_Key"
//#define IA_NeedOptimiseRtmpUrl_Key   @"IA_NeedOptimiseRtmpUrl_Key"

#define IA_Streaming_Key    @"2"
//#define IA_Record_Key       @"1"
//#define IA_RecordStreaming_Key  @"3"

//#define IA_GameType_Complex_Key  @"0"
//#define IA_GameType_Simple_Key   @"1"
//#define IA_GameType_Activity_Key    @"2"

//#define IA_Football_Str    @"football"
//#define IA_Basketball_Str  @"basketball"


#define IA_ResignActive_Key       @"IA_ResignActive_Key"
#define IA_Active_Key             @"IA_Active_Key"
//#define IA_RecordVideoFilePrefix  @"i"

//#define  IA_APP_ID    @"5400000"
//#define  IA_PlatformMark_Str   @"smartArena"

//#define  IA_ReSetScoreEvent_Id        @"203"
//#define  IA_OneScoreEvent_Id          @"501"
//#define  IA_TwoScoreEvent_Id          @"502"
//#define  IA_ThreeScoreEvent_Id        @"503"
//#define  IA_FootballGoalEvent_Id      @"601"

//http://smart-video.oss-cn-beijing.aliyuncs.com/game/gpgameraw/2016-05-05/61aed90738efeab0_132422_1_i.mp4  /game/gpgameraw/2016-05-05/61aed90738efeab0_132422_1_i.mp4

#define IA_START_LiveStr   @"开始直播"

#endif /* LiveConfig_h */
