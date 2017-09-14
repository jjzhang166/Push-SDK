#include "speex_jni.h"

#ifdef __Android__
jlong PackageName(nativeOpen)(JNIEnv *env, jobject thiz, jint frameSize, jint frameRate, jint echoCancellation)
#elif defined __IOS__
long long SpeexProcessor_open(int frameSize, int frameRate, int echoCancellation);
#endif 
{
	SpeexProcessor *processor = (SpeexProcessor*)malloc(sizeof(SpeexProcessor));
	if(NULL == processor)
	{
		ALOGE("Cannot alloc struct : SpeexProcessor!\n");
		return ERROR_MEMORY;
	}
	memset(processor, 0, sizeof(SpeexProcessor));
	pthread_mutex_init(&processor->interface_lock, NULL);

	processor->preprocess_state = speex_preprocess_state_init(frameSize, frameRate);

	if(0 < echoCancellation)
		processor->echo_state = speex_echo_state_init(frameSize, echoCancellation);

	return (long long)processor;
}

#ifdef __Android__
jint PackageName(nativeClose)(JNIEnv *env, jobject thiz, jlong nProcessor)
#elif defined __IOS__
int SpeexProcessor_close(long nProcessor)
#endif
{
	CHECK_AND_CAST;

	pthread_mutex_lock(&processor->interface_lock);

	if(NULL != processor->preprocess_state)
		speex_preprocess_state_destroy(processor->preprocess_state);
	if(NULL != processor->echo_state)
		speex_echo_state_destroy(processor->echo_state);

	pthread_mutex_unlock(&processor->interface_lock);
	pthread_mutex_destroy(&processor->interface_lock);

	free(processor);
	processor = NULL;

	return ERROR_NONE;
}  

#ifdef __Android__
jint PackageName(nativeSetDenoiseParameter) (JNIEnv *env, jobject thiz, jlong nProcessor, jint denoise, jint noiseSuppress)
#elif defined __IOS__
int SpeexProcessor_setDenoiseParameter (long nProcessor, int denoise, int noiseSuppress)
#endif
{
	CHECK_AND_CAST;

	int nRC = ERROR_NONE;

	pthread_mutex_lock(&processor->interface_lock);

	if(NULL != processor->preprocess_state)
	{
		speex_preprocess_ctl(processor->preprocess_state, SPEEX_PREPROCESS_SET_DENOISE, &denoise);
		speex_preprocess_ctl(processor->preprocess_state, SPEEX_PREPROCESS_SET_NOISE_SUPPRESS, &noiseSuppress);
	}
	else
	{
		ALOGE("%s:Line %d Preprocess state is NULL!\n", __func__, __LINE__);
		nRC = ERROR_POINTER;
	}

	pthread_mutex_unlock(&processor->interface_lock);

	 return nRC;
}  

#ifdef __Android__
jint PackageName(nativeSetAGCParameter) (JNIEnv *env, jobject thiz, jlong nProcessor, jint agc, jint level)
#elif defined __IOS__
int SpeexProcessor_setAGCParameter(long nProcessor, int agc, int level)
#endif
{
	CHECK_AND_CAST;

	int nRC = ERROR_NONE;

	pthread_mutex_lock(&processor->interface_lock);

	if(NULL != processor->preprocess_state)
	{
		speex_preprocess_ctl(processor->preprocess_state, SPEEX_PREPROCESS_SET_AGC, &agc);
		speex_preprocess_ctl(processor->preprocess_state, SPEEX_PREPROCESS_SET_AGC_LEVEL, &level);
	}
	else
	{
		ALOGE("%s:Line %d Preprocess state is NULL!\n", __func__, __LINE__);
		nRC = ERROR_POINTER;
	}

	pthread_mutex_unlock(&processor->interface_lock);

	 return nRC;
}

#ifdef __Android__
jint PackageName(nativeSetVADParameter) (JNIEnv *env, jobject thiz, jlong nProcessor, jint vad, jint vadProbStart, jint vadProbContinue)
#elif defined __IOS__
int SpeexProcessor_setVADParameter (long nProcessor, int vad, int vadProbStart, int vadProbContinue)
#endif
{
	CHECK_AND_CAST;

	int nRC = ERROR_NONE;

	pthread_mutex_lock(&processor->interface_lock);

	if(NULL != processor->preprocess_state)
	{
		//静音检测
		speex_preprocess_ctl(processor->preprocess_state, SPEEX_PREPROCESS_SET_VAD, &vad);

		//Set probability required for the VAD to go from silence to voice
		speex_preprocess_ctl(processor->preprocess_state, SPEEX_PREPROCESS_SET_PROB_START , &vadProbStart);

	   	//Set probability required for the VAD to stay in the voice state (integer percent)
		speex_preprocess_ctl(processor->preprocess_state, SPEEX_PREPROCESS_SET_PROB_CONTINUE, &vadProbContinue);
	}
	else
	{
		ALOGE("%s:Line %d Preprocess state is NULL!\n", __func__, __LINE__);
		nRC = ERROR_POINTER;
	}

	pthread_mutex_unlock(&processor->interface_lock);

	 return nRC;
}

#ifdef __Android__
jint PackageName(nativeProcess) (JNIEnv *env, jobject thiz, jlong nProcessor, jbyteArray jdata, jint size, jbyteArray joutput)
#elif defined __IOS__
int SpeexProcessor_process(long nProcessor, uint8_t *data, int size, uint8_t *output)
#endif
{
	CHECK_AND_CAST;

	int nRC = ERROR_NONE;
	jbyte *data = NULL, *output = NULL;

#ifdef __Android__
	if (NULL != jdata)
	{
		data = (jbyte*)(*env)->GetByteArrayElements(env, jdata, 0);
		if (NULL == data)
		{
			nRC = ERROR_JAVA_ENV;
			goto END;
		}
	}

	if (NULL != joutput)
	{
		output = (jbyte*)(*env)->GetByteArrayElements(env, joutput, 0);
		if (NULL == output)
		{
			nRC = ERROR_JAVA_ENV;
			goto END;
		}
	}
#endif // __Android__

	pthread_mutex_lock(&processor->interface_lock);

	speex_preprocess_run(processor->preprocess_state, (spx_int16_t*)(data));
	memcpy(output, data, size);

	pthread_mutex_unlock(&processor->interface_lock);

END:

#ifdef __Android__
	if(NULL != jdata && NULL != data)
		(*env)->ReleaseByteArrayElements(env, jdata, data, 0);
	if(NULL != joutput && NULL != output)
		(*env)->ReleaseByteArrayElements(env, joutput, output, 0);
#endif // __Android__

	return nRC;
}
