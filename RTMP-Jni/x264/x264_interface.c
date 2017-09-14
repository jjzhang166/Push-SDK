#include "x264_interface.h"

#ifdef __Android__
#include <jni.h>
#endif // __Android__

jint Java_com_huiti_liverecord_jni_X264Encoder_nativeX264Init(JNIEnv *env, jobject thiz, jint colorType, jint width, jint height, jint fps, jint bitrate)
{
	if(0 >= width || 0 >= height || 0 > colorType)
		return ERROR_PARAMETER;

	pInterface = (X264Interface*)malloc(sizeof(X264Interface));
	if(NULL == pInterface)
		return ERROR_MEMORY;
	memset(pInterface, 0, sizeof(X264Interface));

	x264_param_default(&pInterface->m_sParam);

	pInterface->mInputColorType = colorType;
	pInterface->m_sParam.i_width = width;
	pInterface->m_sParam.i_height = height;
	pInterface->m_sParam.i_fps_num = fps;
	pInterface->m_sParam.i_fps_den = 1;
	pInterface->m_sParam.i_keyint_max = fps * 2; // GOP
	pInterface->m_sParam.rc.b_mb_tree = 0; // realtime encode

	pInterface->m_sParam.rc.f_rf_constant = 25; 
	pInterface->m_sParam.rc.f_rf_constant_max = 45; 
	pInterface->m_sParam.rc.i_rc_method = X264_RC_ABR;//i_rc_method bitrate control，ABR average bitrate
	pInterface->m_sParam.rc.i_vbv_max_bitrate = (int)((bitrate * 1.2) / 1000);
	pInterface->m_sParam.rc.i_bitrate = (int)bitrate / 1000; 

	pthread_mutex_init(&interface_lock, NULL);

	return 0;
}

jint Java_com_huiti_liverecord_jni_X264Encoder_nativeX264Uninit(JNIEnv *env, jobject thiz)
{
	int nRC = 0;

	pthread_mutex_lock(&interface_lock);

	if(NULL != pInterface)
	{
		if(NULL != pInterface->pHandle)
			x264_encoder_close(pInterface->pHandle);
		pInterface->pHandle = NULL;

		free(pInterface);
		pInterface = NULL;
	}

	pthread_mutex_unlock(&interface_lock);
	pthread_mutex_destroy(&interface_lock);

	return nRC;
}

jint Java_com_huiti_liverecord_jni_X264Encoder_nativeX264SetParam(JNIEnv *env, jobject thiz, jint type, jint value)
{
	int nRC = 0;

	CHECK_CONDITIONS;

	pthread_mutex_lock(&interface_lock);

End:
	pthread_mutex_unlock(&interface_lock);

	return nRC;
}

jint Java_com_huiti_liverecord_jni_X264Encoder_nativeX264Start(JNIEnv *env, jobject thiz, jint type, jint value)
{
	int nRC = 0;

	CHECK_CONDITIONS;

	pthread_mutex_lock(&interface_lock);

	x264_param_apply_profile(&(pInterface->m_sParam), x264_profile_names[2]); // high
	pInterface->pHandle = x264_encoder_open(&(pInterface->m_sParam));
	if(NULL == pInterface->pHandle)
	{
		nRC = pInterface->mError = ERROR_CODEC;
		goto End;
	}

	pInterface->pInputPic = (x264_picture_t*)malloc(sizeof(x264_picture_t));
	if(NULL == pInterface->pInputPic)
	{
		nRC = pInterface->mError = ERROR_MEMORY;
		goto End;
	}
	x264_picture_alloc(pInterface->pInputPic, X264_CSP_I420, pInterface->m_sParam.i_width, pInterface->m_sParam.i_height);

	pInterface->pInputPic->img.i_stride[0] = pInterface->m_sParam.i_width;
	pInterface->pInputPic->img.i_stride[0] = pInterface->m_sParam.i_width >> 1;
	pInterface->pInputPic->img.i_stride[0] = pInterface->m_sParam.i_width >> 1;
	pInterface->pInputPic->i_type 		   = pInterface->mInputColorType; // X264_TYPE_AUTO; 
	pInterface->pInputPic->i_qpplus1 	   = 0;

End:
	pthread_mutex_unlock(&interface_lock);

	return nRC;
}

jint Java_com_huiti_liverecord_jni_X264Encoder_nativeX264Stop(JNIEnv *env, jobject thiz)
{
	int nRC = 0;

	CHECK_CONDITIONS;

	pthread_mutex_lock(&interface_lock);

	if(NULL != pInterface->pHandle)
		x264_encoder_close(pInterface->pHandle);
	pInterface->pHandle = NULL;

End:
	pthread_mutex_unlock(&interface_lock);

	return nRC;
}

jint Java_com_huiti_liverecord_jni_X264Encoder_nativeX264Encode(JNIEnv *env, jobject thiz, jbyteArray yuv, jbyteArray dst, jlong pts)
{
	CHECK_CONDITIONS;

	int nRC = 0, mSize = 0;
	int i_nal = 0;
	x264_nal_t *nal = NULL;
	x264_picture_t outputPic;

	pthread_mutex_lock(&interface_lock);

#ifdef __Android__
	jbyte *inputYuv = NULL, *outputAvc = NULL;
	int inputSize = 0, outputSize = 0;
	if(NULL != yuv)
	{
		inputYuv = (jbyte*)(*env)->GetByteArrayElements(env, yuv, 0);
		inputSize = (*env)->GetArrayLength(env, yuv);
	}
	if(NULL != dst)
	{
		outputAvc = (jbyte*)(*env)->GetByteArrayElements(env, dst, 0);
		outputSize = (*env)->GetArrayLength(env, dst);
	}

#endif // __Android__
	
	if(NULL == pInterface->pInputPic || NULL == inputYuv || 0 > inputSize || NULL == outputAvc)
	{
		nRC = ERROR_MEMORY;
		goto End;
	}

	memcpy(pInterface->pInputPic->img.plane[0], inputYuv, (pInterface->m_sParam.i_width >> 1) * pInterface->m_sParam.i_height * 3);
	pInterface->pInputPic->i_pts = pts;

	nRC = x264_encoder_encode(pInterface->pHandle, &nal, &i_nal, pInterface->pInputPic, &outputPic);
	if(0 > nRC)
	{
		nRC = ERROR_CODEC;
		goto End;
	}

End:

#ifdef __Android__
	if(NULL != yuv && NULL != inputYuv)
		(*env)->ReleaseByteArrayElements(env, yuv, inputYuv, 0);
	if(NULL != dst && NULL != outputAvc)
		(*env)->ReleaseByteArrayElements(env, dst, outputAvc, 0);
#endif // __Android__

	pthread_mutex_unlock(&interface_lock);

	return nRC;
}
