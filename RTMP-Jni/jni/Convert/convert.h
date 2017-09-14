#ifndef __CONVERT_H__
#define __CONVERT_H__

#include <pthread.h>

#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libavfilter/avfilter.h"

#include "libavutil/imgutils.h"
#include "libavcodec/internal.h"
#include "libavcodec/h264.h"
#include "libavcodec/h264data.h"
#include "libavcodec/golomb.h"

#define MAX_LOG2_MAX_FRAME_NUM    (12 + 4)
#define MIN_LOG2_MAX_FRAME_NUM    4

#define FFMAX(a,b) ((a) > (b) ? (a) : (b))
#define FFMAX3(a,b,c) FFMAX(FFMAX(a,b),c)
#define FFMIN(a,b) ((a) > (b) ? (b) : (a))
#define FFMIN3(a,b,c) FFMIN(FFMIN(a,b),c)
#define FAST_DIV255(x) ((((x) + 128) * 257) >> 16)

#ifdef _DEBUG_LOG

#ifdef ALOGD
#undef ALOGD
#endif
#ifdef ALOGI
#undef ALOGI
#endif
#ifdef ALOGE
#undef ALOGE
#endif

#ifdef __Android__
#include <android/log.h>
#define ANDROID_LOG_DEBUG 3
#define ANDROID_LOG_INFO 4
#define ANDROID_LOG_ERROR 6
#define ALOGD(...)  __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define ALOGI(...)  __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define ALOGE(...)  __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#elif defined __IOS__
#define ALOGD(...) printf(__VA_ARGS__);
#define ALOGI(...) printf(__VA_ARGS__);
#define ALOGE(...) printf(__VA_ARGS__);
#endif // __Android__

#else
#define ALOGD(...)
#define ALOGI(...)
#define ALOGE(...)
#endif

#define WIDTH 0
#define HEIGHT 1

#define DESIGN_WIDTH (width / 1280.0)
#define DESIGN_HEIGHT (height / 720.0)

#define BASKETBALL 1
#define FOOTBALL 2

typedef enum {false = 0, true = 1} bool;

enum{
    CONVERT_PARAM_ID_NONE = 0,
    CONVERT_PARAM_ID_TEAM = 1,
    CONVERT_PARAM_ID_SCORE = 2,
    CONVERT_PARAM_ID_TIME = 3
};

typedef struct RECT {
	int top;
	int left;
	int bottom;
	int right;
}RECT;

typedef struct TextStruct {
	char* data;
    int len;

	int left;
    int top;
    int width;
	int height;

	int align;
}TextStruct;

typedef struct PasterStruct {
	AVFrame 	*frame;
	uint8_t		*frameData;

	AVFrame 	*originalFrame;
	uint8_t		*originalFrameData;

	RECT		frameRect;
	TextStruct	scoreRect;
	TextStruct	textRect;
}PasterStruct;

int  m_nInited;
int	 mGameType;

AVFrame *logoFrame;
uint8_t *logoData;
RECT logoRect;

AVFrame *staticFrame;
uint8_t *staticFrameData;
RECT staticFrameRect;

AVFrame *inputVideoFrame;
AVFrame *outputVideoFrame;

AVFrame *YUV420PVideoFrame;
uint8_t *YUV420PVideoData;

char *fontPFPath = NULL;
int  fontPFSize = 0;
int  fontPFColor = 0;
float  fontPFAlpha = 1;

char *fontMisoBoldPath = NULL;
int  fontMisoBoldSize = 0;
int  fontMisoBoldColor = 0;
float  fontMisoBoldAlpha = 1;

PasterStruct hostTeam;
PasterStruct visitingTeam;
PasterStruct timeBoard;
PasterStruct eventBoard;

struct SwsContext* scoreboardScale;
struct SwsContext* eventScale;
struct SwsContext* inputVideoScale;
struct SwsContext* outputVideoScale;

pthread_mutex_t interface_lock;

static int Uninit(void);
static int decode_picture(const char* picfile, AVFrame* pDstFrame);
static int blend_image(AVFrame *dst, const AVFrame *src, int x, int y);
static void setDefaultRect(int gameType, int width, int height);
static int fillPasterFrame(const char* picfile, PasterStruct* paster);
static void freePasterStruct(PasterStruct *paster);
#ifndef __IOS__
static inline int decode_vui(GetBitContext *gb, SPS *sps, int *timing_index);
static int AddVUI2SPS(uint8_t *inputSPS, int inputSize, int num_units_in_tick, int time_scale, uint8_t **outputSPS);
static void printColorFormat();
#endif

#endif // __CONVERT_H__
