#include <pthread.h>

#include "webrtc/modules/audio_processing/include/audio_processing.h"
#include "webrtc/modules/include/module_common_types.h"

#ifdef __Android__
#include <jni.h>
#include <android/log.h>
#define LOG_TAG "AudioProcessing_jni"
#endif //__Android__

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __Android__

#define PackageName(a) Java_com_wangyong_demo_pushsdk_Audio_WebRTCAudioProcessing_##a
#define ALOGD(...)  __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define ALOGI(...)  __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define ALOGE(...)  __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

#elif defined __IOS__

#define ALOGD(...) printf(__VA_ARGS__);
#define ALOGI(...) printf(__VA_ARGS__);
#define ALOGE(...) printf(__VA_ARGS__);

#endif // __Android__

#define CHECK_AND_CAST if(0 >= nProcessor) return ERROR_POINTER; \
							   WebRTCAudioProcessing *processor = (WebRTCAudioProcessing *)nProcessor;

enum Error {
	// Fatal errors.
	kNoError = 0,
	kUnspecifiedError = -1,
	kCreationFailedError = -2,
	kUnsupportedComponentError = -3,
	kUnsupportedFunctionError = -4,
	kNullPointerError = -5,
	kBadParameterError = -6,
	kBadSampleRateError = -7,
	kBadDataLengthError = -8,
	kBadNumberChannelsError = -9,  
	kFileError = -10,
	kStreamParameterNotSetError = -11,
	kNotEnabledError = -12,

	// Warnings are non-fatal.
	// This results when a set_stream_ parameter is out of range. Processing
	// will continue, but the parameter may have been truncated.
	kBadStreamParameterWarning = -13,

	ERROR_MEMORY = -30,
	ERROR_POINTER = -31,
	ERROR_JAVA_ENV = -32,
	ERROR_WEBRTC = -33,
	ERROR_OPERATION = -34,
	ERROR_PARAMETER = -35,
};   

typedef struct WebRTCAudioProcessing {

	unsigned char*	processedData;
	int			processedSize;

	unsigned char*	unProcessedData;
	int			unProcessedSize;

	webrtc::AudioProcessing* apm;
	webrtc::AudioFrame *frame;
	webrtc::AudioFrame *echo_frame;
	bool is_echo_cancel;
	int64_t	processedFrameCount;

	pthread_mutex_t interface_lock;
}WebRTCAudioProcessing;


#ifdef __Android__
jlong PackageName(nativeOpen)(JNIEnv *env, jobject thiz, jint enableNS, jint enableAEC, jint aecDelay, jint enableAGC, jint enableVAD);
void PackageName(nativeClose)(JNIEnv *env, jobject thiz, jlong nProcessor);
int PackageName(nativeSetParameters)(JNIEnv *env, jobject thiz, jlong nProcessor, jint frameSize, jint sampleRate, jint sampleBit, jint channels);
int PackageName(nativeProcess)(JNIEnv *env, jobject thiz, jlong nProcessor, jbyteArray jData);
#else
long long open(int enableNS, int enableAEC, int aecDelay, int enableAGC, int enableVAD);
void close(long long nProcessor);
int setParameters(long long nProcessor, int frameSize, int sampleRate, int sampleBit, int channels);
int process(long long nProcessor, uint8_t *data, int bufLen);
#endif

static int innerClose(long long nProcessor);
static webrtc::NoiseSuppression::Level NSLevelConvert(int level);
static webrtc::EchoCancellation::SuppressionLevel AECLevelConvert(int level);
static webrtc::GainControl::Mode AGCModeConvert(int mode);

#ifdef __cplusplus
}
#endif
