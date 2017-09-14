#ifndef __FACE_DETECTION_H__
#define __FACE_DETECTION_H__

#include <opencv2/core/core.hpp>
#include <opencv2/objdetect.hpp>
#include <string>
#include <vector>

#ifdef __Android__
#include <jni.h>
#include <android/log.h>

#define LOG_TAG "FaceDetection"
#define ALOGD(...) ((void)__android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__))
#define ALOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__))
#define ALOGE(...) ((void)__android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__))

#elif defined __IOS__

#define ALOGD(...) printf(__VA_ARGS__)
#define ALOGI(...) printf(__VA_ARGS__)
#define ALOGE(...) printf(__VA_ARGS__)

#endif // __Android__

using namespace std;
using namespace cv;

typedef struct DetectorAgregator DetectorAgregator;

typedef struct RECT {
	int left;
	int top;
	int right;
	int bottom;
}RECT;

typedef struct FaceDetection {
	pthread_mutex_t 		interface_lock;
	DetectorAgregator * 	detectorAgregator;
	int						width;
	int						height;
}FaceDetection;

FaceDetection* pFDHandle= NULL;

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __Android__
JNIEXPORT jlong Java_com_huiti_liverecord_core_VideoEncoder_nativeFaceDetectionInit(JNIEnv *env, jobject thiz,
		jstring template_file, jint width, jint height, jint minFaceSize);
#elif defined __IOS__
int64_t faceDetectionInit(const char* templateFile, int width, int height, int minFaceSize);
#endif // __Android__

#ifdef __Android__
JNIEXPORT void Java_com_huiti_liverecord_core_VideoEncoder_nativeFaceDetectionUninit(JNIEnv *env, jobject thiz, jlong handle);
#elif defined __IOS__
void faceDetectionUninit(int64_t handle);
#endif // __Android__

#ifdef __Android__
JNIEXPORT void Java_com_huiti_liverecord_core_VideoEncoder_nativeSetFaceSize(JNIEnv *env, jobject thiz, jlong handle, jint faceSize);
#elif defined __IOS__
void setFaceSize(int64_t handle, int faceSize);
#endif // __Android__

#ifdef __Android__
JNIEXPORT jobject Java_com_huiti_liverecord_core_VideoEncoder_nativeFaceDetect(JNIEnv *env, jobject thiz,
		jlong handle, jbyteArray yData);
#elif defined __IOS__
int faceDetect(int64_t handle, uint8_t* imageGray, void* rect);
#endif // __Android__

#ifdef __cplusplus
}
#endif


#endif //__FACE_DETECTION_H__
