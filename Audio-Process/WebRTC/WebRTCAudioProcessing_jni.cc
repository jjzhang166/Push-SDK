#include "WebRTCAudioProcessing_jni.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __Android__
jlong PackageName(nativeOpen)(JNIEnv *env, jobject thiz, jint enableNS, jint enableAEC, jint aecDelay, jint enableAGC, jint enableVAD)
#else
long long open(int enableNS, int enableAEC, int aecDelay, int enableAGC, int enableVAD)
#endif
{
	int nRC = kNoError;

ALOGE("%s:Line %d Debug WebRTCAudioProcessing ==============\n", __func__, __LINE__);
	WebRTCAudioProcessing *processor = (WebRTCAudioProcessing*)malloc(sizeof(WebRTCAudioProcessing));
	if(NULL == processor)
	{
		ALOGE("Cannot alloc WebRTCAudioProcessing !!!\n");
		return ERROR_MEMORY;
	}
	memset(processor, 0, sizeof(WebRTCAudioProcessing));
	pthread_mutex_init(&processor->interface_lock, NULL);

	processor->apm = webrtc::AudioProcessing::Create();
	if(NULL == processor->apm)
	{
		ALOGE("AudioProcessing::Create falied !!!\n");
		nRC = ERROR_WEBRTC;
		goto END;
	}

	processor->apm->high_pass_filter()->Enable(true);
	
	if(0 < enableNS)
	{
		nRC = processor->apm->noise_suppression()->Enable(true);	
		if(kNoError != nRC)
		{
			ALOGE("AudioProcessing enable noise suppression failed : %d \n", nRC);
			goto END;
		}

		webrtc::NoiseSuppression::Level level = NSLevelConvert(enableNS);
		processor->apm->noise_suppression()->set_level(level);	

		nRC = processor->apm->voice_detection()->Enable(true);
		if(kNoError != nRC)
		{
			ALOGE("AudioProcessing enable voice detection failed : %d \n", nRC);
			goto END;
		}

		ALOGI("AudioProcessing NS setting level %d \n", enableNS);
	}

	if(0 < enableAEC)
	{
		processor->is_echo_cancel = true;

		webrtc::EchoCancellation *echo_canell = processor->apm->echo_cancellation();
		//webrtc::EchoControlMobile *echo_canell = processor->apm->echo_control_mobile();
		if(NULL == echo_canell)
		{
			ALOGE("AudioProcessing get echo cancellation failed !!!\n");
			nRC = ERROR_WEBRTC;
			goto END;
		}
		nRC = echo_canell->enable_drift_compensation(false);
		nRC |= echo_canell->Enable(true);
		if(kNoError != nRC)
		{
			ALOGE("AudioProcessing enable echo cancellation failed : %d \n", nRC);
			goto END;
		}

		webrtc::EchoCancellation::SuppressionLevel level = AECLevelConvert(enableAEC);
		echo_canell->set_suppression_level(level);

		nRC = processor->apm->set_stream_delay_ms(aecDelay);

		ALOGI("AudioProcessing AEC setting level %d delay %d nRC %d\n", enableAEC, aecDelay, nRC);
	}

	if(0 < enableAGC)
	{
		nRC = processor->apm->gain_control()->Enable(true);
		if(kNoError != nRC)
		{
			ALOGE("AudioProcessing enable gain control failed : %d \n", nRC);
			goto END;
		}
		processor->apm->gain_control()->set_analog_level_limits(0, 255);
	
		webrtc::GainControl::Mode mode = AGCModeConvert(enableAGC);
		nRC = processor->apm->gain_control()->set_mode(mode);

		ALOGI("AudioProcessing AGC setting level %d nRC %d\n", enableAEC, nRC);
	}

ALOGE("%s:Line %d Debug WebRTCAudioProcessing processor %p ==============\n", __func__, __LINE__, processor);
	return (long long)processor;

END:
	innerClose((long long)processor);

	return nRC;
}

#ifdef __Android__
void PackageName(nativeClose)(JNIEnv *env, jobject thiz, jlong nProcessor)
#else
void close(long long nProcessor)
#endif
{
ALOGE("%s:Line %d Debug WebRTCAudioProcessing ==============\n", __func__, __LINE__);
	innerClose(nProcessor);
}

#ifdef __Android__
int PackageName(nativeSetParameters)(JNIEnv *env, jobject thiz, jlong nProcessor,
		jint frameSize, jint sampleRate, jint sampleBit, jint channels)
#else
int setParameters(long long nProcessor, int frameSize, int sampleRate, int sampleBit, int channels)
#endif
{
	CHECK_AND_CAST;
	int nRC = kNoError;

	pthread_mutex_lock(&processor->interface_lock);
	
ALOGE("Line %d Debug WebRTCAudioProcessing processor %p size %d rate %d bit %d channels %d ==============\n", __LINE__,
		processor, frameSize, sampleRate, sampleBit, channels);

	processor->frame = new webrtc::AudioFrame();
	if(NULL == processor->frame)
	{
		ALOGE("Cannot new AudioFrame !!!\n");
		nRC = ERROR_MEMORY;
		goto END;
	}

	if(true == processor->apm->echo_cancellation()->is_enabled())
	{
		processor->echo_frame = new webrtc::AudioFrame();
	}

	processor->frame->sample_rate_hz_ = sampleRate;
	processor->frame->num_channels_ = channels;
	processor->frame->samples_per_channel_ = sampleRate / 100;

	processor->processedData = (unsigned char *)malloc(frameSize);
	if(NULL == processor->processedData)
	{
		ALOGE("Cannot alloc processedData !!!\n");
		nRC = ERROR_MEMORY;
		goto END;
	}
	processor->processedSize = 0;

	processor->unProcessedData = (unsigned char *)malloc(processor->frame->samples_per_channel_);
	if(NULL == processor->unProcessedData)
	{
		ALOGE("Cannot alloc unProcessedData !!!\n");
		nRC = ERROR_MEMORY;
		goto END;
	}
	processor->unProcessedSize = 0;

END:
	if(kNoError != nRC)
	{
ALOGE("%s:Line %d Debug WebRTCAudioProcessing ==============\n", __func__, __LINE__);
		if(NULL != processor->frame)
			delete processor->frame;
		if(NULL != processor->echo_frame)
			delete processor->echo_frame;
		if(NULL != processor->unProcessedData)
			free(processor->unProcessedData);
		processor->frame = NULL;
		processor->echo_frame = NULL;
		processor->unProcessedData = NULL;
	}

	pthread_mutex_unlock(&processor->interface_lock);

	return nRC;
}

#ifdef __Android__
int PackageName(nativeProcess)(JNIEnv *env, jobject thiz, jlong nProcessor, jbyteArray jData)
#else
int process(long long nProcessor, uint8_t *data, int bufLen)
#endif
{
	CHECK_AND_CAST;

	int nRC = kNoError;

	pthread_mutex_lock(&processor->interface_lock);

#ifdef __Android__
	int bufLen = 0;
	jbyte* data = NULL;
#endif

	if(NULL == processor->apm)
	{
		ALOGE("AudioProcessing NOT create yet !!!\n");
		nRC = ERROR_OPERATION;
		goto END;
	}

	if(NULL == processor->frame)
	{
		ALOGE("No process frame, please setParameter first !!!\n");
		nRC = ERROR_OPERATION;
		goto END;
	}

#ifdef __Android__
	if (NULL != jData)
	{
		bufLen = env->GetArrayLength(jData);

		data = env->GetByteArrayElements(jData, 0);
		if (NULL == data)
		{
			ALOGE("Cannot get input frame data !!!\n");
			nRC = ERROR_JAVA_ENV;
			goto END;
		}
	}
#endif

	memcpy(processor->frame->data_, data, bufLen);

	nRC = processor->apm->ProcessStream(processor->frame);
	if(kNoError != nRC)
	{
		ALOGE("ProcessStream failed : %d\n", nRC);
		goto END;
	}

	if(NULL !=  processor->apm->echo_cancellation() && true == processor->apm->echo_cancellation()->is_enabled())
	{
		nRC = processor->apm->set_stream_delay_ms(10);
	}

	if(NULL != processor->echo_frame)
	{
	
	}

	memcpy(data, processor->frame->data_, bufLen);

	processor->processedFrameCount ++;

	ALOGE("ProcessStream return : %d\n", nRC);
END:

#ifdef __Android__
	if (NULL != jData && NULL != data)
		env->ReleaseByteArrayElements(jData, data, 0);
#endif

	pthread_mutex_unlock(&processor->interface_lock);

	return nRC;
}

#ifdef __Android__
int PackageName(nativeProcess_back)(JNIEnv *env, jobject thiz, jlong nProcessor, jbyteArray jData)
#else
int process(long long nProcessor, uint8_t *data, int bufLen)
#endif
{
	CHECK_AND_CAST;

ALOGE("%s:Line %d Debug WebRTCAudioProcessing processor %p ==============\n", __func__, __LINE__, processor);
	
	int nRC = kNoError;
	int processedDataSize = 0, loopTimes = 0, needSavedSize = 0;
	bool frameCompleted = false;

	pthread_mutex_lock(&processor->interface_lock);

#ifdef __Android__
	int bufLen = 0;
	jbyte* data = NULL;
#endif

	if(NULL == processor->apm)
	{
		ALOGE("AudioProcessing NOT create yet !!!\n");
		nRC = ERROR_OPERATION;
		goto END;
	}

	if(NULL == processor->frame)
	{
		ALOGE("No process frame, please setParameter first !!!\n");
		nRC = ERROR_OPERATION;
		goto END;
	}

#ifdef __Android__
	if (NULL != jData)
	{
		bufLen = env->GetArrayLength(jData);

		data = env->GetByteArrayElements(jData, 0);
		if (NULL == data)
		{
			ALOGE("Cannot get input frame data !!!\n");
			nRC = ERROR_JAVA_ENV;
			goto END;
		}
	}
#endif

	do {
		if(NULL != processor->unProcessedData && 0 < processor->unProcessedSize)
		{
			memcpy(processor->frame->data_, processor->unProcessedData, processor->unProcessedSize);
		}

		memcpy(processor->frame->data_ + processor->unProcessedSize,
				data + processedDataSize,
				processor->frame->samples_per_channel_ - processor->unProcessedSize);

		nRC = processor->apm->ProcessStream(processor->frame);
		if(kNoError != nRC)
		{
			ALOGE("ProcessStream failed : %d\n", nRC);
			goto END;
		}
		if(NULL !=  processor->apm->echo_cancellation() && true == processor->apm->echo_cancellation()->is_enabled())
		{
			nRC = processor->apm->set_stream_delay_ms(10);
		}

		processedDataSize = processor->frame->samples_per_channel_ * (1 + loopTimes) - processor->unProcessedSize;

ALOGE("Debug WebRTCAudioProcessing bufLen %d this processed %d saved processed %d unProcessed %d\n",
		bufLen, processedDataSize, processor->processedSize, processor->unProcessedSize);

		processor->unProcessedSize = 0;

		if(bufLen == processor->processedSize + processor->frame->samples_per_channel_)
		{
			memcpy(data, processor->processedData, processor->processedSize);
			memcpy(data + processor->processedSize, processor->frame->data_, processor->frame->samples_per_channel_);
			processor->processedSize = 0;

			frameCompleted = true;
		}
		else if(bufLen < processor->processedSize + processor->frame->samples_per_channel_)
		{
			memcpy(data, processor->processedData, processor->processedSize);
			memcpy(data + processor->processedSize,
					processor->frame->data_,
					processor->frame->samples_per_channel_ + processor->processedSize - bufLen);

			needSavedSize = processor->frame->samples_per_channel_ + processor->processedSize - bufLen;

			memcpy(processor->processedData,
					processor->frame->data_ + processor->frame->samples_per_channel_ - needSavedSize,
					needSavedSize);
			processor->processedSize = needSavedSize;

			loopTimes = 0;
			frameCompleted = true;
		}
		else
		{
			memcpy(processor->processedData + processor->processedSize + loopTimes * processor->frame->samples_per_channel_,
					processor->frame->data_, processor->frame->samples_per_channel_);
			processor->processedSize += processor->frame->samples_per_channel_;
		}

		loopTimes += 1;

	} while (bufLen - processedDataSize > processor->frame->samples_per_channel_);

	if(processor->processedSize == bufLen)
	{
		memcpy(data, processor->processedData, processor->processedSize);
		processor->processedSize = 0;
		frameCompleted = true;
	}

	if(bufLen > processedDataSize && NULL != processor->unProcessedData)
	{
		memcpy(processor->unProcessedData, data + processedDataSize, bufLen - processedDataSize);
		processor->unProcessedSize = bufLen - processedDataSize;
	}

	if(NULL != processor->echo_frame)
	{
	
	}

	processor->processedFrameCount ++;
END:

#ifdef __Android__
	if (NULL != jData && NULL != data)
		env->ReleaseByteArrayElements(jData, data, 0);
#endif

	pthread_mutex_unlock(&processor->interface_lock);

	if(true == frameCompleted)
		return 1;

	return nRC;
}

////////////// Private /////////////////

static int innerClose(long long nProcessor)
{
	CHECK_AND_CAST;

	pthread_mutex_lock(&processor->interface_lock);

	delete processor->apm;
	processor->apm = NULL;

	if(NULL != processor->unProcessedData)
		free(processor->unProcessedData);
	processor->unProcessedData = NULL;
	processor->unProcessedSize = 0;

	pthread_mutex_unlock(&processor->interface_lock);
	pthread_mutex_destroy(&processor->interface_lock);

	free(processor);
	processor = NULL;

	return 0;
}

static webrtc::NoiseSuppression::Level NSLevelConvert(int level)
{
	if(1 >= level)
		return webrtc::NoiseSuppression::kLow;
	else if(2 >= level)
		return webrtc::NoiseSuppression::kModerate;
	else if(3 >= level)
		return webrtc::NoiseSuppression::kHigh;
	else if(4 >= level)
		return webrtc::NoiseSuppression::kVeryHigh;

	return webrtc::NoiseSuppression::kVeryHigh;
}

static webrtc::EchoCancellation::SuppressionLevel AECLevelConvert(int level)
{
	if(1 >= level)
		return webrtc::EchoCancellation::kLowSuppression;
	else if(2 >= level)
		return webrtc::EchoCancellation::kModerateSuppression;
	else if(3 >= level)
		return webrtc::EchoCancellation::kHighSuppression;

	return webrtc::EchoCancellation::kHighSuppression;
}
	
static webrtc::GainControl::Mode AGCModeConvert(int mode)
{
	if(1 >= mode)
		return webrtc::GainControl::kAdaptiveAnalog;
	else if(2 >= mode)
		return webrtc::GainControl::kAdaptiveDigital;
	else if(3 >= mode)
		return webrtc::GainControl::kFixedDigital;

	return webrtc::GainControl::kFixedDigital;
}

#ifdef __cplusplus
}
#endif
