#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <pthread.h>
#include "libavutil/opt.h"
#include "libavutil/mathematics.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"

#ifdef __Android__
#include <jni.h>
#include <android/log.h>
#define LOG_TAG "FileMuxer"
#endif //__Android__

#define AVSYNC_DRIFT_SCALE 22

#define RECORD_INIT_PTS -12345

#ifdef __Android__

#define PackageName(a) Java_com_wangyong_demo_pushsdk_FileMuxer_##a

#define ALOGD(...)  __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define ALOGI(...)  __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define ALOGE(...)  __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

#else

#define ALOGD(...) printf(__VA_ARGS__);
#define ALOGI(...) printf(__VA_ARGS__);
#define ALOGE(...) printf(__VA_ARGS__);

#endif // __Android__

#define HANDLER_CHECK_AND_CAST if(0 >= nHandler) return ERROR_POINTER; \
									   MuxerHandler *handler = (MuxerHandler*)nHandler;

#define ERROR_NONE 0 
#define ERROR_UNKNOWN -1
#define ERROR_POINTER -2
#define ERROR_MEMORY -3
#define ERROR_FFMPEG_INIT -4
#define ERROR_JAVA_ENV -5

static int sws_flags = SWS_BICUBIC;

typedef struct AudioInfo {
	int codecID;
	int bitrate;
	int samplerate;
	int samplebit;
	int channels;
}AudioInfo;

typedef struct SPSPPSInfo {
	uint8_t *sps;
	uint8_t *pps;
	int ppsLen;
	int spsLen;
}SPSPPSInfo;

typedef struct VideoInfo {
	int codecID;
	int bitrate;
	int width;
	int height;
	float fps;
	int gopsize;
}VideoInfo;

typedef struct MuxerHandler {
	char *outputName;
	SPSPPSInfo spsppsInfo;	
	AudioInfo audioInfo;
	VideoInfo videoInfo;
	AVOutputFormat *fmt;
	AVFormatContext *oc;
	AVStream *audio_st;
	AVStream *video_st;

// Get reference file informations.
#if 0
	AVStream *input_audio_st;
	AVStream *input_video_st;
#endif

	long long audioStartPTS;
	long long audioStartDTS;
	long long videoStartPTS;
	long long videoStartDTS;
	bool fileHeaderWrited;
	bool videoKeyframeArrived;
	AVBitStreamFilterContext* h264bsfc;
	AVBitStreamFilterContext* aacbsfc;
	pthread_mutex_t interface_lock;

	long long audioPrePTS;
	long long videoPrePTS;
#ifdef __Android__
	uint8_t *adts_header;
#endif
}MuxerHandler;

#ifdef __Android__
jlong PackageName(nativeInit)(JNIEnv *env, jobject thiz);
jint PackageName(nativeUninit)(JNIEnv *env, jobject thiz, jlong nHandler);
jint PackageName(nativeOpen)(JNIEnv *env, jobject thiz, jlong nHandler, jstring jfilename);
jint PackageName(nativeClose)(JNIEnv *env, jobject thiz, jlong handler);
jint PackageName(nativeSetAudioParameter)(JNIEnv *env, jobject thiz, jlong nHandler, jint codecID, jint bitrate, jint samplerate, jint samplebit, jint channels);
jint PackageName(nativeSetVideoParameter)(JNIEnv *env, jobject thiz, jlong nHandler, jint codecID, jint bitrate, jint width, jint height, jint fps, jint gopsize);
jint PackageName(nativeSetSPSPPS)(JNIEnv *env, jobject thiz, jlong nHandler, uint8_t* jsps, uint8_t *jpps, jint spsSize, jint ppsSize);
jint PackageName(nativeInputAudioSample)(JNIEnv *env, jobject thiz, jlong nHandler, uint8_t *jdata, jint size, jlong pts, jlong dts);
jint PackageName(nativeInputVideoSample)(JNIEnv *env, jobject thiz, jlong nHandler, uint8_t *jdata, jint size, jlong pts, jlong dts, jboolean keyframe);
#else
long long FileMuxerInit(void);
int FileMuxerUninit(long long nHandler);
int FileMuxerOpen(long long nHandler, const char *path);
int FileMuxerClose(long long nHandler);
int FileMuxerSetAudioParameter(long long nHandler, int codecID, int bitrate, int samplerate, int samplebit, int channels);
int FileMuxerSetVideoParameter(long long nHandler, int codecID, int bitrate, int width, int height, int fps, int gopsize);
int FileMuxerSetSPSPPS(long long nHandler, uint8_t *sps, uint8_t *pps, int spsLen, int ppsLen);
int FileMuxerInputAudioSample(long long nHandler, uint8_t *data, int size, long long pts, long long dts);
int FileMuxerInputVideoSample(long long nHandler, uint8_t *data, int size, long long pts, long long dts, bool keyframe);
#endif

//// *********** Private *************** ////
static AVStream *CreateOutputStream(MuxerHandler *Handler, int streamType);
#ifdef __Android__
static int generateADTSHeader(MuxerHandler *handler, int size);
#endif

//// ********** Block *************** ////
#ifndef __USER_BLOCK__
#define __USER_BLOCK__
#endif // __USER_BLOCK__
extern bool needBlocked;
