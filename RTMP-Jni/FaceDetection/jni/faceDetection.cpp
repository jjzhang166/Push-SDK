#include "faceDetection.h"

class CascadeDetectorAdapter: public DetectionBasedTracker::IDetector
{

public:
	CascadeDetectorAdapter(cv::Ptr<cv::CascadeClassifier> detector)
		: IDetector()
	  	, Detector(detector)
	{
		ALOGD("CascadeDetectorAdapter::Detect::Detect");
		CV_Assert(detector);
	}

	void detect(const cv::Mat &Image, std::vector<cv::Rect> &objects)
	{
		ALOGD("CascadeDetectorAdapter::Detect: begin");
		ALOGD("CascadeDetectorAdapter::Detect: scaleFactor=%.2f, minNeighbours=%d, minObjSize=(%dx%d), maxObjSize=(%dx%d)",
				scaleFactor, minNeighbours, minObjSize.width, minObjSize.height, maxObjSize.width, maxObjSize.height);

		Detector->detectMultiScale(Image, objects, scaleFactor, minNeighbours, 0, minObjSize, maxObjSize);

		ALOGD("CascadeDetectorAdapter::Detect: end");
	}

	virtual ~CascadeDetectorAdapter()
	{
		ALOGD("CascadeDetectorAdapter::Detect::~Detect");
	}

private:
	CascadeDetectorAdapter();
	cv::Ptr<cv::CascadeClassifier> Detector;
};

struct DetectorAgregator
{
	cv::Ptr<CascadeDetectorAdapter> mainDetector;
	cv::Ptr<CascadeDetectorAdapter> trackingDetector;

	cv::Ptr<DetectionBasedTracker> tracker;

	DetectorAgregator(cv::Ptr<CascadeDetectorAdapter>& _mainDetector, cv::Ptr<CascadeDetectorAdapter>& _trackingDetector)
		: mainDetector(_mainDetector)
		, trackingDetector(_trackingDetector)
	{
		CV_Assert(_mainDetector);
		CV_Assert(_trackingDetector);

		DetectionBasedTracker::Parameters DetectorParams;
		tracker = makePtr<DetectionBasedTracker>(mainDetector, trackingDetector, DetectorParams);
	}
};

void Uninit(FaceDetection* pFDHandle)
{
	if(NULL != pFDHandle)
	{
		pthread_mutex_lock(&(pFDHandle->interface_lock));

		if(NULL != pFDHandle->detectorAgregator)
		{
			if(NULL != pFDHandle->detectorAgregator->tracker)
				pFDHandle->detectorAgregator->tracker->stop();
			delete pFDHandle->detectorAgregator;
			pFDHandle->detectorAgregator = NULL;
		}

		pthread_mutex_unlock(&(pFDHandle->interface_lock));
		pthread_mutex_destroy(&(pFDHandle->interface_lock));

		free(pFDHandle);
		pFDHandle = NULL;
	}
}

#ifdef __Android__
JNIEXPORT jlong Java_com_huiti_liverecord_core_VideoEncoder_nativeFaceDetectionInit(JNIEnv *env, jobject thiz,
		jstring template_file, jint width, jint height, jint minFaceSize)
#elif defined __IOS__
int64_t faceDetectionInit(const char* templateFile, int width, int height, int minFaceSize)
#endif // __Android__
{
	ALOGI("Face Detection build %s %s\n", __DATE__, __TIME__);

	int nRC = 0;
#ifdef __Android__
    jboolean isCopy;
	char* templateFile = NULL;
	if(NULL != template_file)
		templateFile = (char*)env->GetStringUTFChars(template_file, &isCopy);

	if(NULL == template_file || NULL == templateFile)
#elif defined __IOS__
	if(NULL == templateFile)
#endif // __Android__
	{
		ALOGE("Cannot init face detection without template file !!!\n");
		nRC = -1;
		goto End;
	}

	ALOGI("Template file %s W * H = %d * %d face size %d\n", templateFile, width, height, minFaceSize);

	if(NULL != pFDHandle)
		Uninit(pFDHandle);

	pFDHandle = (FaceDetection*)malloc(sizeof(FaceDetection));
	if(NULL == pFDHandle)
	{
		ALOGE("Cannot alloce FD handle !!!\n");
		nRC = -1;
		goto End;
	}
ALOGE("Eoollo +++++++++++++++++++++ pFDHandle %p", pFDHandle);

	pthread_mutex_init(&(pFDHandle->interface_lock), NULL);
	pthread_mutex_lock(&(pFDHandle->interface_lock));

	pFDHandle->width = width;
	pFDHandle->height = height;

#ifdef __Android__
	try
	{
#endif // __Android__

		cv::Ptr<CascadeDetectorAdapter> mainDetector =
			makePtr<CascadeDetectorAdapter>(makePtr<CascadeClassifier>((string)templateFile));

		cv::Ptr<CascadeDetectorAdapter> trackingDetector =
			makePtr<CascadeDetectorAdapter>(makePtr<CascadeClassifier>((string)templateFile));

		pFDHandle->detectorAgregator = new DetectorAgregator(mainDetector, trackingDetector);
		if(NULL == pFDHandle->detectorAgregator || NULL == pFDHandle->detectorAgregator->tracker)
		{
			ALOGE("Cannot new DetectorAgregator !!!\n");
			nRC = -1;
			goto End;
		}

		if(minFaceSize > 0)
			mainDetector->setMinObjectSize(Size(minFaceSize, minFaceSize));

		pFDHandle->detectorAgregator->tracker->run();

ALOGE("Eoollo +++++++++++++++++++++ pFDHandle %p detectorAgregator %p", pFDHandle, pFDHandle->detectorAgregator);
#ifdef __Android__
	}
	catch(cv::Exception& e)
	{
		ALOGD("naviteFaceDetectionInit caught Exception: %s", e.what());
		//jclass je = env->FindClass("org/opencv/core/CvException");
		//if(!je)
		//	je = env->FindClass("java/lang/Exception");
		//env->ThrowNew(je, e.what());
	}
	catch (...)
	{
		ALOGD("naviteFaceDetectionInit caught unknown exception");
		jclass je = env->FindClass("java/lang/Exception");
		env->ThrowNew(je, "Unknown exception in JNI code of naviteFaceDetectionInit");
		nRC = -1;
	}
#endif // __Android__

End:

#ifdef __Android__
	if(NULL != template_file && NULL != templateFile)
		env->ReleaseStringUTFChars (template_file, templateFile);
#endif // __Android__

	if(NULL != pFDHandle)
		pthread_mutex_unlock(&(pFDHandle->interface_lock));
ALOGE("Eoollo +++++++++++++++++++++ pFDHandle %p", pFDHandle);

	if(-1 == nRC)
		return nRC;

ALOGE("Eoollo +++++++++++++++++++++ pFDHandle %p", pFDHandle);
	return (int64_t)pFDHandle;
}

#ifdef __Android__
JNIEXPORT void Java_com_huiti_liverecord_core_VideoEncoder_nativeFaceDetectionUninit(JNIEnv *env, jobject thiz, jlong handle)
#elif defined __IOS__
void faceDetectionUninit(int64_t handle)
#endif // __Android__
{
	FaceDetection *pFDHandle = (FaceDetection*)handle;

ALOGE("Eoollo +++++++++++++++++++++ pFDHandle %p", pFDHandle);
#ifdef __Android__
	try
	{
#endif // __Android__

		if(NULL != pFDHandle)
			Uninit(pFDHandle);

#ifdef __Android__
	}
	catch(cv::Exception& e)
	{
		ALOGD("nativeestroyObject caught cv::Exception: %s", e.what());
		jclass je = env->FindClass("org/opencv/core/CvException");
		if(!je)
			je = env->FindClass("java/lang/Exception");
		env->ThrowNew(je, e.what());
	}
	catch (...)
	{
		ALOGD("nativeDestroyObject caught unknown exception");
		jclass je = env->FindClass("java/lang/Exception");
		env->ThrowNew(je, "Unknown exception in JNI code of DetectionBasedTracker.nativeDestroyObject()");
	}
#endif // __Android__
}

#ifdef __Android__
JNIEXPORT void Java_com_huiti_liverecord_core_VideoEncoder_nativeSetFaceSize(JNIEnv *env, jobject thiz, jlong handle, jint faceSize)
#elif defined __IOS__
void setFaceSize(int64_t handle, int faceSize)
#endif // __Android__
{
	FaceDetection *pFDHandle = (FaceDetection*)handle;

	if(NULL != pFDHandle && NULL != pFDHandle->detectorAgregator && pFDHandle->detectorAgregator->mainDetector)
	{
		pthread_mutex_lock(&(pFDHandle->interface_lock));

		pFDHandle->detectorAgregator->mainDetector->setMinObjectSize((const cv::Size&)faceSize);

		pthread_mutex_unlock(&(pFDHandle->interface_lock));
	}
	else
	{
		ALOGE("Cannot set face size %d\n", faceSize);
		if(NULL == pFDHandle)
			ALOGE("NULL == pFDHandle !!!\n");
		else if(NULL == pFDHandle->detectorAgregator)
			ALOGE("pFDHandle->detectorAgregator !!!\n");
		else
			ALOGE("pFDHandle->detectorAgregator->mainDetector !!!\n");
	}
}

#ifdef __Android__
JNIEXPORT jobject Java_com_huiti_liverecord_core_VideoEncoder_nativeFaceDetect(JNIEnv *env, jobject thiz,
		jlong handle, jbyteArray yData)
#elif defined __IOS__
int faceDetect(int64_t handle, uint8_t* data, void* rect)
#endif // __Android__
{
	int nRC = 0;
	FaceDetection* pFDHandle = (FaceDetection*)handle;
ALOGE("Eoollo +++++++++++++++++++++ pFDHandle %p", pFDHandle);
#ifdef __Android__
	jintArray intArray = env->NewIntArray(4);
	jbyte* imageGrayData = NULL;
	if(NULL != yData)
		imageGrayData = (jbyte*)env->GetByteArrayElements(yData, 0);

	try
	{
#endif // __Android__

		if(NULL != pFDHandle)
		{
			pthread_mutex_lock(&(pFDHandle->interface_lock));

			if(NULL == imageGrayData)
			{
				ALOGE("Cannot do face detection without data !!!\n");
				nRC = -1;
				pthread_mutex_unlock(&(pFDHandle->interface_lock));
				goto End;
			}

			//pFDHandle->imageGray
			Mat imageGray(pFDHandle->height, pFDHandle->width, CV_8UC1, imageGrayData, pFDHandle->width);

			vector<Rect> RectFaces;

ALOGE("Eoollo +++++++++++++++++++++ pFDHandle %p detectorAgregator %p", pFDHandle, pFDHandle->detectorAgregator);
			if(NULL != pFDHandle->detectorAgregator && NULL != pFDHandle->detectorAgregator->tracker)
			{
				pFDHandle->detectorAgregator->tracker->process(imageGray);
				//pFDHandle->detectorAgregator->tracker->process(*(pFDHandle->imageGray));
				pFDHandle->detectorAgregator->tracker->getObjects(RectFaces);

				int maxIndex = 0, i = 0;
				int maxArea = INT_MIN;

				vector<Rect>::iterator it;
				for(it = RectFaces.begin(); it != RectFaces.end(); it ++)
				{
					int area = it->width * it->height;
ALOGE("Eoollo ######## max %d area %d i %d width %d height %d\n", maxArea, area, i, it->width, it->height);
					if(maxArea < area && it->width > 0 && it->height > 0)
					{
						maxArea = area;
						maxIndex = i;
					}
					i ++;
				}

ALOGE("Eoollo ######## size %d maxIndex %d\n", RectFaces.size(), maxIndex);
				if(maxIndex < RectFaces.size())
				{
#ifdef __Android__
					int nInt[4];
					nInt[0] = RectFaces.at(maxIndex).x;
					nInt[1] = RectFaces.at(maxIndex).y;
					nInt[2] = RectFaces.at(maxIndex).x + RectFaces.at(maxIndex).width;
					nInt[3] = RectFaces.at(maxIndex).y + RectFaces.at(maxIndex).height;
					env->SetIntArrayRegion(intArray, 0, 4, nInt);
#else
					((RECT*)rect)->left = RectFaces[maxIndex].x;
					((RECT*)rect)->top = RectFaces[maxIndex].y;
					((RECT*)rect)->right = RectFaces[maxIndex].x + RectFaces[maxIndex].width;
					((RECT*)rect)->bottom = RectFaces[maxIndex].y + RectFaces[maxIndex].height;
#endif // __Android__
				}
				else
					nRC = -1;
			}
			else
				nRC = -1;

			pthread_mutex_unlock(&(pFDHandle->interface_lock));
		}
#ifdef __Android__
	}
	catch(cv::Exception& e)
	{
		ALOGE("nativeCreateObject caught cv::Exception: %s", e.what());
		//jclass je = env->FindClass("org/opencv/core/CvException");
		//if(!je)
		//	je = env->FindClass("java/lang/Exception");
		//env->ThrowNew(je, e.what());
	}
	catch (...)
	{
		ALOGE("nativeFaceDetect caught unknown exception");
		jclass je = env->FindClass("java/lang/Exception");
		env->ThrowNew(je, "Unknown exception in JNI code nativeFaceDetect");
	}
#endif // __Android__

End:

#ifdef __Android__
	if(NULL != yData && NULL != imageGrayData)
		env->ReleaseByteArrayElements(yData, imageGrayData, 0);
	return intArray;
#else
	return nRC;
#endif // __Android__
}
