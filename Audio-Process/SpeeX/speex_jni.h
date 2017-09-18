#include <string.h>  
#include <unistd.h>  
#include <stdlib.h>
#include <pthread.h>

#ifdef __Android__
#include <jni.h>
#include <android/log.h>
#define LOG_TAG "Speex_jni"
#endif //__Android__

#include <speex/speex.h>  
#include <speex/speex_echo.h>
#include <speex/speex_preprocess.h>


#ifdef __Android__

#define PackageName(a) Java_com_wangyong_demo_pushsdk_Audio_SpeexProcessor_##a
#define ALOGD(...)  __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define ALOGI(...)  __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define ALOGE(...)  __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

#elif defined __IOS__

#define ALOGD(...) printf(__VA_ARGS__);
#define ALOGI(...) printf(__VA_ARGS__);
#define ALOGE(...) printf(__VA_ARGS__);

#endif // __Android__

#define CHECK_AND_CAST if(0 >= nProcessor) return ERROR_POINTER; \
									   SpeexProcessor *processor = (SpeexProcessor*)nProcessor;

typedef enum ERROR_STATUS {
	ERROR_NONE = 0,
	ERROR_MEMORY = -1,
	ERROR_POINTER = -2,
	ERROR_JAVA_ENV = -3,
}ERROR_STATUS;

typedef struct SpeexProcessor {
	SpeexPreprocessState *preprocess_state;  
	SpeexEchoState *echo_state;  

	pthread_mutex_t interface_lock;
}SpeexProcessor;
