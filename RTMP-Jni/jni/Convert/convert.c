#ifdef __Android__
#include <jni.h>
#define LOG_TAG "Convert"
#endif // __Android__

#include "convert.h"

#ifdef __IOS__
static void printColorFormat()
{
	ALOGI("AV_PIX_FMT_YUV420P: %d\n", AV_PIX_FMT_YUV420P);
	ALOGI("AV_PIX_FMT_YUVJ420P: %d\n", AV_PIX_FMT_YUVJ420P);
	ALOGI("AV_PIX_FMT_NV12: %d\n", AV_PIX_FMT_NV12);
	ALOGI("AV_PIX_FMT_NV21: %d\n", AV_PIX_FMT_NV21);
	ALOGI("AV_PIX_FMT_YUVA420P: %d\n", AV_PIX_FMT_YUVA420P);
	ALOGI("AV_PIX_FMT_YUVA420P9BE: %d\n", AV_PIX_FMT_YUVA420P9BE);
	ALOGI("AV_PIX_FMT_YUVA420P9LE: %d\n", AV_PIX_FMT_YUVA420P9LE);
	ALOGI("AV_PIX_FMT_YUVA420P10BE: %d\n", AV_PIX_FMT_YUVA420P10BE);
	ALOGI("AV_PIX_FMT_YUVA420P10LE: %d\n", AV_PIX_FMT_YUVA420P10LE);
	ALOGI("AV_PIX_FMT_YUVA420P16BE: %d\n", AV_PIX_FMT_YUVA420P16BE);
	ALOGI("AV_PIX_FMT_YUVA420P16LE: %d\n", AV_PIX_FMT_YUVA420P16LE);
	ALOGI("AV_PIX_FMT_YUV420P9LE: %d\n", AV_PIX_FMT_YUV420P9LE);
	ALOGI("AV_PIX_FMT_YUV420P9BE: %d\n", AV_PIX_FMT_YUV420P9BE);
	ALOGI("AV_PIX_FMT_YUV420P10LE: %d\n", AV_PIX_FMT_YUV420P10LE);
	ALOGI("AV_PIX_FMT_YUV420P10BE: %d\n", AV_PIX_FMT_YUV420P10BE);
	ALOGI("AV_PIX_FMT_YUV420P16LE: %d\n", AV_PIX_FMT_YUV420P16LE);
	ALOGI("AV_PIX_FMT_YUV420P16BE: %d\n", AV_PIX_FMT_YUV420P16BE);
	ALOGI("AV_PIX_FMT_RGB32: %d\n", AV_PIX_FMT_RGB32);
}
#endif

#ifdef __Android__
jint Java_com_huiti_liverecord_jni_RTMPCompound_nativeCompoundInit(JNIEnv *env, jobject thiz,
		jint gameType, jint inputColorType, jint outputColorType, jint width, jint height)
#elif defined __IOS__
int CompoundInit(int gameType, int inputColorType, int outputColorType, int width, int height)
#endif // __Android__
{
#ifdef __IOS__
	printColorFormat();
#endif

	ALOGI("Compound build date %s : %s\n", __DATE__, __TIME__);
	ALOGI("%s:Line %d color type input %d output %d W * H = %d * %d\n", __func__, __LINE__, inputColorType, outputColorType, width, height);

	Uninit();

    pthread_mutex_init(&interface_lock, NULL);
	mGameType = gameType;

	YUV420PVideoData = malloc(avpicture_get_size(AV_PIX_FMT_YUV420P, width, height));
    YUV420PVideoFrame = av_frame_alloc();
    if(NULL == YUV420PVideoData || NULL == YUV420PVideoFrame)
        goto ERROR;
    YUV420PVideoFrame->width = width;
    YUV420PVideoFrame->height = height;
    YUV420PVideoFrame->format = AV_PIX_FMT_YUV420P;
    avpicture_fill((AVPicture *)YUV420PVideoFrame, YUV420PVideoData, AV_PIX_FMT_YUV420P, YUV420PVideoFrame->width, YUV420PVideoFrame->height);

    inputVideoScale = sws_getContext(width, height, inputColorType, width, height, AV_PIX_FMT_YUV420P, SWS_FAST_BILINEAR, NULL, NULL, NULL);
    if(NULL == inputVideoScale)
        goto ERROR;

    inputVideoFrame = av_frame_alloc();
    if(NULL == inputVideoFrame)
        goto ERROR;
    inputVideoFrame->width = width;
    inputVideoFrame->height = height;
    inputVideoFrame->format = inputColorType;

    outputVideoFrame = av_frame_alloc();
    if(NULL == outputVideoFrame)
        goto ERROR;
    outputVideoFrame->width = width;
    outputVideoFrame->height = height;
    outputVideoFrame->format = outputColorType;
 
    outputVideoScale = sws_getContext(width, height, AV_PIX_FMT_YUV420P, width, height, outputColorType, SWS_FAST_BILINEAR, NULL, NULL, NULL);
    if(NULL == outputVideoScale)
        goto ERROR;

	setDefaultRect(gameType, width, height);

	fontPFPath = NULL;
	fontPFSize = 0;
	fontPFAlpha = 1;

	fontMisoBoldPath = NULL;
	fontMisoBoldSize = 0;
	fontMisoBoldAlpha = 0;

    m_nInited = 1;
	return 0;

ERROR:
    Uninit();
    return -2; // ERROR_MEMORY;
}

#ifdef __Android__
jint Java_com_huiti_liverecord_jni_RTMPCompound_nativeCompoundUninit(JNIEnv *env, jobject thiz)
#elif defined __IOS__
int CompoundUninit(void)
#endif // __Android__
{
    int nRC = 0;

	pthread_mutex_lock(&interface_lock);

    ALOGI("%s:Line %d \n", __func__, __LINE__);
    nRC = Uninit();   

	pthread_mutex_unlock(&interface_lock);
	pthread_mutex_destroy(&interface_lock);

    return nRC;
}

#ifdef __Android__
jint Java_com_huiti_liverecord_jni_RTMPCompound_nativeSetLogoRect(JNIEnv *env, jobject thiz, jint left, jint top, jint right, jint bottom)
#elif defined __IOS__
int SetLogoRect(int left, int top, int right, int bottom)
#endif // __Android__
{
	ALOGI("SetLogoRect RECT : %d * %d * %d * %d\n", left, top, bottom, right);

	pthread_mutex_lock(&interface_lock);

	logoRect.left = left;
	logoRect.top = top;
	logoRect.right = right;
	logoRect.bottom = bottom;

	pthread_mutex_unlock(&interface_lock);

	return 0;
}

/*
#ifdef __Android__
jint Java_com_huiti_liverecord_jni_RTMPCompound_nativeSetScoreboardRect(JNIEnv *env, jobject thiz, jint left, jint top, jint right, jint bottom)
#elif defined __IOS__
int SetScoreboardRect(int left, int top, int right, int bottom)
#endif // __Android__
{
	ALOGI("SetScoreboardRect RECT : %d * %d * %d * %d\n", left, top, bottom, right);

	pthread_mutex_lock(&interface_lock);

	scoreboardRect.left = left;
	scoreboardRect.top = top;
	scoreboardRect.right = right;
	scoreboardRect.bottom = bottom;

	pthread_mutex_unlock(&interface_lock);

	return 0;
}
*/

#ifdef __Android__
jint Java_com_huiti_liverecord_jni_RTMPCompound_nativeSetEventRect(JNIEnv *env, jobject thiz, jint left, jint top, jint right, jint bottom)
#elif defined __IOS__
int SetEventRect(int left, int top, int right, int bottom)
#endif // __Android__
{
	ALOGI("SetEventRect RECT : %d * %d * %d * %d\n", left, top, bottom, right);

	pthread_mutex_lock(&interface_lock);

	eventBoard.frameRect.left = left;
	eventBoard.frameRect.top = top;
	eventBoard.frameRect.right = right;
	eventBoard.frameRect.bottom = bottom;

	pthread_mutex_unlock(&interface_lock);

	return 0;
}

#ifdef __Android__
jint Java_com_huiti_liverecord_jni_RTMPCompound_nativeSetFontPFInfo(JNIEnv *env, jobject thiz, jstring fileString, jint color, jint size, jfloat alpha)
#elif defined __IOS__
int SetFontPFInfo(const char* fontFile, int color, int size, float alpha)
#endif // __Android__
{
    int nRC = 0;
	pthread_mutex_lock(&interface_lock);

    if(0 == m_nInited)
        goto End;

#ifdef __Android__
    jboolean isCopy;
	char* fontFile = NULL;
	if(NULL != fileString)
		fontFile = (char*)(*env)->GetStringUTFChars(env, fileString, &isCopy);

	if(NULL == fileString || NULL == fontFile)
#else
	if(NULL == fontFile)
#endif //__Android__
		goto End;

    ALOGI("%s:Line %d size %d alpha %f fontFile %s \n", __func__, __LINE__, size, alpha, fontFile);

    if(NULL != fontPFPath)
        free(fontPFPath);
    int fontPFPathLen = strlen(fontFile) * sizeof(char);
    fontPFPath = malloc(fontPFPathLen + sizeof(char));
    memset(fontPFPath, 0, fontPFPathLen + sizeof(char));
    memcpy(fontPFPath, fontFile, fontPFPathLen);
    fontPFSize = size;
    fontPFAlpha = alpha;

End:

#ifdef __Android__
	if(NULL != fileString && NULL != fontFile)
		(*env)->ReleaseStringUTFChars (env, fileString, fontFile);
#endif // __Android__

	pthread_mutex_unlock(&interface_lock);

    return nRC;
}

#ifdef __Android__
jint Java_com_huiti_liverecord_jni_RTMPCompound_nativeSetFontMisoBoldInfo(JNIEnv *env, jobject thiz, jstring fileString, jint color, jint size, jfloat alpha)
#elif defined __IOS__
int SetFontMisoBoldInfo(const char* fontFile, int color, int size, float alpha)
#endif // __Android__
{
    int nRC = 0;
	pthread_mutex_lock(&interface_lock);

    if(0 == m_nInited)
        goto End;

#ifdef __Android__
    jboolean isCopy;
	char* fontFile = NULL;
	if(NULL != fileString)
		fontFile = (char*)(*env)->GetStringUTFChars(env, fileString, &isCopy);

	if(NULL == fileString || NULL == fontFile)
#else
	if(NULL == fontFile)
#endif //__Android__
		goto End;

    ALOGI("%s:Line %d size %d alpha %f fontFile %s \n", __func__, __LINE__, size, alpha, fontFile);

    if(NULL != fontMisoBoldPath)
        free(fontMisoBoldPath);
    int fontMisoBoldPathLen = strlen(fontFile) * sizeof(char);
    fontMisoBoldPath = malloc(fontMisoBoldPathLen + sizeof(char));
    memset(fontMisoBoldPath, 0, fontMisoBoldPathLen + sizeof(char));
    memcpy(fontMisoBoldPath, fontFile, fontMisoBoldPathLen);
    fontMisoBoldSize = size;
    fontMisoBoldAlpha = alpha;

End:

#ifdef __Android__
	if(NULL != fileString && NULL != fontFile)
		(*env)->ReleaseStringUTFChars (env, fileString, fontFile);
#endif // __Android__

	pthread_mutex_unlock(&interface_lock);

    return nRC;
}

#ifdef __Android__
jint Java_com_huiti_liverecord_jni_RTMPCompound_nativeSetScoreboardParameter(JNIEnv *env, jobject thiz, jint paramID, jobject p1, jobject p2, jint pSize1, jint pSize2)
#elif defined __IOS__
int SetScoreboardParameter(int paramID, const char* param1, const char* param2, int pSize1, int pSize2)
#endif // __Android__
{
    int nRC = -1;
	pthread_mutex_lock(&interface_lock);

    if(0 == m_nInited)
        goto End;

#ifdef __Android__
    jboolean isCopy;
	char* param1 = NULL;
	char* param2 = NULL;
	if(NULL != p1)
		param1 = (char*)(*env)->GetStringUTFChars(env, p1, &isCopy);
	if(NULL != p2)
		param2 = (char*)(*env)->GetStringUTFChars(env, p2, &isCopy);
#endif //__Android__

    ALOGI("%s:Line %d id %d \n", __func__, __LINE__, paramID);

    switch(paramID)
    {
        case CONVERT_PARAM_ID_TEAM:
        {
            ALOGI("%s:Line %d  %s VS %s size1 %d size2 %d\n", __func__, __LINE__, param1, param2, pSize1, pSize2);
			if(NULL == fontPFPath)
			{
				ALOGE("%s:Line %d NULL == fontPFPath\n", __func__, __LINE__);
				goto End;
			}

			if(NULL != param1 || NULL != param2)
			{
				avfilter_uninit_font();
				nRC = avfilter_set_font(fontPFPath, "Black", AV_PIX_FMT_YUVA420P, fontPFSize, fontPFAlpha);
				if(0 != nRC)
				{
					ALOGE("%s:Line %d nRC %d\n", __func__, __LINE__, nRC);
					goto End;
				}
			}

            if(NULL != param1)
            {
				if(NULL == hostTeam.frame || NULL == hostTeam.originalFrame)
					goto End;

				nRC = avfilter_draw_text(hostTeam.originalFrame, param1,
						hostTeam.textRect.left, hostTeam.textRect.top, hostTeam.textRect.align,
						hostTeam.textRect.width, hostTeam.textRect.height);
				if(0 != nRC)
				{
					ALOGE("%s:Line %d nRC %d\n", __func__, __LINE__, nRC);
					goto End;
				}

				// Keep the team name.
				nRC = av_frame_copy(hostTeam.frame, hostTeam.originalFrame);
				if(0 != nRC)
				{
					ALOGE("%s:Line %d copy host frame error %d\n", __func__, __LINE__, nRC);   
					goto End;
				}
            }

            if(NULL != param2)
            {
				if(NULL == visitingTeam.frame || NULL == visitingTeam.originalFrame)
					goto End;

				nRC = avfilter_draw_text(visitingTeam.originalFrame, param2,
						visitingTeam.textRect.left, visitingTeam.textRect.top, visitingTeam.textRect.align,
						visitingTeam.textRect.width, visitingTeam.textRect.height);
				if(0 != nRC)
				{
					ALOGE("%s:Line %d nRC %d\n", __func__, __LINE__, nRC);
					goto End;
				}

				nRC = av_frame_copy(visitingTeam.frame, visitingTeam.originalFrame);
				if(0 != nRC)
				{
					ALOGE("%s:Line %d copy host frame error %d\n", __func__, __LINE__, nRC);   
					goto End;
				}
            }
            break;
        }
        case CONVERT_PARAM_ID_SCORE:
        {
            ALOGI("%s:Line %d  %s VS %s \n", __func__, __LINE__, param1, param2);

			if(NULL == fontMisoBoldPath)
				goto End;

			if(NULL == param1 && NULL == param2)
				goto End;

			avfilter_uninit_font();
			nRC = avfilter_set_font(fontMisoBoldPath, "White", AV_PIX_FMT_YUVA420P,
					fontMisoBoldSize, fontMisoBoldAlpha);
			if(0 != nRC)
			{
				ALOGE("%s:Line %d nRC %d\n", __func__, __LINE__, nRC);
				goto End;
			}

            if(NULL != param1)
            {
				if(NULL == hostTeam.frame || NULL == hostTeam.originalFrame)
					goto End;

				nRC = av_frame_copy(hostTeam.frame, hostTeam.originalFrame);
				if(0 != nRC)
				{
					ALOGE("%s:Line %d copy host frame error %d\n", __func__, __LINE__, nRC);   
					goto End;
				}
				nRC = avfilter_draw_text(hostTeam.frame, param1,
						hostTeam.scoreRect.left, hostTeam.scoreRect.top, hostTeam.scoreRect.align,
						hostTeam.scoreRect.width, hostTeam.scoreRect.height);
				if(0 != nRC)
				{
					ALOGE("%s:Line %d nRC %d\n", __func__, __LINE__, nRC);
					goto End;
				}
            }

            if(NULL != param2)
            {
				if(NULL == visitingTeam.frame || NULL == visitingTeam.originalFrame)
					goto End;

				nRC = av_frame_copy(visitingTeam.frame, visitingTeam.originalFrame);
				if(0 != nRC)
				{
					ALOGE("%s:Line %d copy host frame error %d\n", __func__, __LINE__, nRC);   
					goto End;
				}

				nRC = avfilter_draw_text(visitingTeam.frame, param2,
						visitingTeam.scoreRect.left, visitingTeam.scoreRect.top, visitingTeam.scoreRect.align,
						visitingTeam.scoreRect.width, visitingTeam.scoreRect.height);
				if(0 != nRC)
				{
					ALOGE("%s:Line %d nRC %d\n", __func__, __LINE__, nRC);
					goto End;
				}
			}

            break;
        }
        case CONVERT_PARAM_ID_TIME:
        {
            ALOGI("%s:Line %d  time %s \n", __func__, __LINE__, param1);

            if(NULL == fontPFPath)
			{
				ALOGE("%s:Line %d NULL == fontPFPath\n", __func__, __LINE__);   
				goto End;
			}

            if(NULL != param1)
            {
				avfilter_uninit_font();
				nRC = avfilter_set_font(fontPFPath, "White", AV_PIX_FMT_YUVA420P,
						fontPFSize, fontPFAlpha);
				if(0 != nRC)
				{
					ALOGE("%s:Line %d nRC %d\n", __func__, __LINE__, nRC);
					goto End;
				}
            }

			if(NULL == timeBoard.frame || NULL == timeBoard.originalFrame)
				goto End;

			nRC = av_frame_copy(timeBoard.frame, timeBoard.originalFrame);
			if(0 != nRC)
			{
				ALOGE("%s:Line %d copy time board frame error %d\n", __func__, __LINE__, nRC);   
				goto End;
			}

			nRC = avfilter_draw_text(timeBoard.frame, param1,
					timeBoard.textRect.left, timeBoard.textRect.top, timeBoard.textRect.align,
					timeBoard.textRect.width, timeBoard.textRect.height);
			if(0 != nRC)
			{
				ALOGE("%s:Line %d nRC %d\n", __func__, __LINE__, nRC);
				goto End;
			}

			break;
        }
        default:
        {
            ALOGE("%s:Line %d unknown param ID %d\n", __func__, __LINE__, paramID);   
            goto End;
        }
    }

End:

#ifdef __Android__
	if(NULL != p1 && NULL != param1)
		(*env)->ReleaseStringUTFChars (env, p1, param1);
	if(NULL != p2 && NULL != param2)
		(*env)->ReleaseStringUTFChars (env, p2, param2);
#endif // __Android__

	pthread_mutex_unlock(&interface_lock);

    ALOGI("Eoollo %s:Line %d nRC %d\n", __func__, __LINE__, nRC);
	return nRC;
}

#ifdef __Android__
jint Java_com_huiti_liverecord_jni_RTMPCompound_nativeSetLogoFile(JNIEnv *env, jobject thiz, jstring fileString)
#elif defined __IOS__
int SetLogoFile(const char *logoFile)
#endif // __Android__
{
    int nRC = 0;
	pthread_mutex_lock(&interface_lock);

    if(0 == m_nInited)
        goto End;

#ifdef __Android__
    jboolean isCopy;
	char* logoFile = NULL;
	if(NULL != fileString)
		logoFile = (char*)(*env)->GetStringUTFChars(env, fileString, &isCopy);

	if(NULL == fileString || NULL == logoFile)
		goto End;
#endif //__Android__
    ALOGI("%s:Line %d logo file %s\n", __func__, __LINE__, logoFile);

    if(NULL != logoFrame)
        av_frame_free(&logoFrame);
    logoFrame = av_frame_alloc();

	if(NULL == logoFile || NULL == logoFrame)
		goto End;

	logoFrame->width = logoRect.right - logoRect.left;
	logoFrame->height = logoRect.bottom - logoRect.top;
	logoFrame->format = AV_PIX_FMT_YUVA420P;

	if(NULL == logoData)
		logoData = malloc(avpicture_get_size(AV_PIX_FMT_YUVA420P, logoFrame->width, logoFrame->height));
	avpicture_fill((AVPicture *)logoFrame, logoData, AV_PIX_FMT_YUVA420P, logoFrame->width, logoFrame->height);

	av_frame_get_buffer(logoFrame, 16);

	nRC = decode_picture(logoFile, logoFrame);

	if(0 != nRC)
	{
		if(NULL != logoData)
			free(logoData);
		av_frame_free(&logoFrame);
		logoData = NULL;
		logoFrame = NULL;
	}

End:

#ifdef __Android__
	if(NULL != fileString && NULL != logoFile)
		(*env)->ReleaseStringUTFChars (env, fileString, logoFile);
#endif // __Android__

	pthread_mutex_unlock(&interface_lock);

    ALOGI("Eoollo %s:Line %d nRC %d\n", __func__, __LINE__, nRC);
	return nRC;
}


#ifdef __Android__
jint Java_com_huiti_liverecord_jni_RTMPCompound_nativeSetEventString(JNIEnv *env, jobject thiz, jstring event)
#else
int SetEventString(const char *eventString)
#endif // __Android__
{
    int nRC = 0;
	pthread_mutex_lock(&interface_lock);

    if(0 == m_nInited)
        goto End;

#ifdef __Android__
    jboolean isCopy;
	char* eventString = NULL;
	if(NULL != event)
		eventString = (char*)(*env)->GetStringUTFChars(env, event, &isCopy);

#endif //__Android__
	if(NULL == fontPFPath || NULL == eventString || NULL == eventBoard.frame || NULL == eventBoard.originalFrame)
		goto End;

    ALOGI("%s:Line %d event string %s\n", __func__, __LINE__, eventString);

    nRC = av_frame_copy(eventBoard.frame, eventBoard.originalFrame);

	if(0 != nRC)
	{
        ALOGE("%s:Line %d copy event frame error nRC %d\n", __func__, __LINE__, nRC);
        if(NULL != eventBoard.frameData)
        eventBoard.frameData = NULL;
            free(eventBoard.frameData);
        av_frame_free(&eventBoard.frame);
        eventBoard.frame = NULL;

        if(NULL != eventBoard.originalFrameData)
        eventBoard.originalFrameData = NULL;
            free(eventBoard.originalFrameData);
        av_frame_free(&eventBoard.originalFrame);
        eventBoard.originalFrame = NULL;

		goto End;
	}
    else
    {
        avfilter_uninit_font();
        nRC = avfilter_set_font(fontPFPath, "White", AV_PIX_FMT_YUVA420P, fontPFSize, fontPFAlpha);
        if(0 != nRC)
        {
            ALOGE("%s:Line %d nRC %d\n", __func__, __LINE__, nRC);
			goto End;
        }

        nRC = avfilter_draw_text(eventBoard.frame, eventString, 0, 0, 1,
				eventBoard.frameRect.right - eventBoard.frameRect.left,
				eventBoard.frameRect.bottom - eventBoard.frameRect.top);
        if(0 != nRC)
        {
            ALOGE("%s:Line %d nRC %d\n", __func__, __LINE__, nRC);
			goto End;
        }
    }

End:

#ifdef __Android__
	if(NULL != event && NULL != eventString)
		(*env)->ReleaseStringUTFChars (env, event, eventString);
#endif // __Android__

	pthread_mutex_unlock(&interface_lock);

    ALOGI("Eoollo %s:Line %d nRC %d\n", __func__, __LINE__, nRC);
	return nRC;
}

#ifdef __Android__
jint Java_com_huiti_liverecord_jni_RTMPCompound_nativeSetBackgroundFile(JNIEnv *env, jobject thiz,
		jstring hostString, jstring visitingString, jstring timeString, jstring eventString, jstring staticString)
#else
int SetBackgroundFile(const char *hostFile, const char *visitingFile,
		const char *timeFile, const char *eventFile, const char *staticFile)
#endif // __Android__
{
    int nRC = -1;
	pthread_mutex_lock(&interface_lock);

    if(0 == m_nInited)
        goto End;

#ifdef __Android__
    jboolean isCopy;
	char* hostFile = NULL;
	char* visitingFile = NULL;
	char* timeFile = NULL;
	char* eventFile = NULL;
	char* staticFile = NULL;

	if(NULL != hostString)
		hostFile = (char*)(*env)->GetStringUTFChars(env, hostString, &isCopy);
	if(NULL != visitingString)
		visitingFile = (char*)(*env)->GetStringUTFChars(env, visitingString, &isCopy);
	if(NULL != timeString)
		timeFile = (char*)(*env)->GetStringUTFChars(env, timeString, &isCopy);
	if(NULL != eventString)
		eventFile = (char*)(*env)->GetStringUTFChars(env, eventString, &isCopy);
	if(NULL != staticString)
		staticFile = (char*)(*env)->GetStringUTFChars(env, staticString, &isCopy);

#endif //__Android__
    ALOGI("%s:Line %d host: %s visiting: %s time: %s static: %s\n", __func__, __LINE__,
			hostFile, visitingFile, timeFile, staticFile);

	if(NULL == hostFile || NULL == visitingFile || NULL == timeFile || NULL == eventFile)
        goto End;

	nRC = fillPasterFrame(hostFile, &hostTeam);
	if(0 != nRC)
	{
		ALOGE("%s:Line %d nRC %d\n", __func__, __LINE__, nRC);
		goto End;
	}

	nRC = fillPasterFrame(visitingFile, &visitingTeam);
	if(0 != nRC)
	{
		ALOGE("%s:Line %d nRC %d\n", __func__, __LINE__, nRC);
		goto End;
	}

	nRC = fillPasterFrame(timeFile, &timeBoard);
	if(0 != nRC)
	{
		ALOGE("%s:Line %d nRC %d\n", __func__, __LINE__, nRC);
		goto End;
	}

	nRC = fillPasterFrame(eventFile, &eventBoard);
	if(0 != nRC)
	{
		ALOGE("%s:Line %d nRC %d\n", __func__, __LINE__, nRC);
		goto End;
	}

	if(NULL != staticFile)
	{
		if(NULL != staticFrame)
			av_frame_free(&staticFrame);
		if(NULL != staticFrameData)
			free(staticFrameData);
		staticFrame = av_frame_alloc();
		if(NULL == staticFrame)
		{
			ALOGE("%s:Line %d nRC %d\n", __func__, __LINE__, nRC);
			goto End;
		}

		staticFrame->width = staticFrameRect.right - staticFrameRect.left;
		staticFrame->height = staticFrameRect.bottom - staticFrameRect.top;
		staticFrame->format = AV_PIX_FMT_YUVA420P;
		staticFrameData = malloc(avpicture_get_size(AV_PIX_FMT_YUVA420P, staticFrame->width, staticFrame->height));
		if(NULL == staticFrameData)
			goto End;
		avpicture_fill((AVPicture *)staticFrame, staticFrameData, AV_PIX_FMT_YUVA420P,
				staticFrame->width, staticFrame->height);
		av_frame_get_buffer(staticFrame, 16);

		nRC = decode_picture(staticFile, staticFrame);
		if(0 != nRC)
		{
			ALOGE("%s:Line %d nRC %d\n", __func__, __LINE__, nRC);
			goto End;
		}
	}
	nRC = 0;

End:

#ifdef __Android__
	if(NULL != hostString && NULL != hostFile)
		(*env)->ReleaseStringUTFChars (env, hostString, hostFile);
	if(NULL != visitingString && NULL != visitingFile)
		(*env)->ReleaseStringUTFChars (env, visitingString, visitingFile);
	if(NULL != timeString && NULL != timeFile)
		(*env)->ReleaseStringUTFChars (env, timeString, timeFile);
	if(NULL != eventString && NULL != eventFile)
		(*env)->ReleaseStringUTFChars (env, eventString, eventFile);
	if(NULL != staticString && NULL != staticFile)
		(*env)->ReleaseStringUTFChars (env, staticString, staticFile);
#endif // __Android__

	if(0 != nRC)
	{
		if(NULL != staticFrameData)
			free(staticFrameData);
		if(NULL != staticFrame)
			av_frame_free(&staticFrame);
		staticFrameData = NULL;
		staticFrame = NULL;
	}

	pthread_mutex_unlock(&interface_lock);

    ALOGI("Eoollo %s:Line %d nRC %d\n", __func__, __LINE__, nRC);
	return nRC;
}

#ifdef __Android__
jint Java_com_huiti_liverecord_jni_RTMPCompound_nativeCompound(JNIEnv *env, jobject thiz, jint hasScoreboard, jint hasEvent, jbyteArray video, jbyteArray dst)
#elif defined __IOS__
int Compound(int hasScoreboard, int hasEvent, uint8_t *videoBuf, uint8_t *dstBuf)
#endif // __Android__
{
	int nRC = 0;

	pthread_mutex_lock(&interface_lock);

    if(0 == m_nInited)
        goto ERROR;

#ifdef __Android__
	jbyte* dstBuf = 0;
	jbyte* videoBuf = 0;
	jbyte* buttonBuf = 0;

	if(NULL != dst)
	{
		dstBuf = (jbyte*)(*env)->GetByteArrayElements(env, dst, 0);
		if (NULL == dstBuf)
			goto ERROR;
	}

	if(NULL != video)
	{
		videoBuf = (jbyte*)(*env)->GetByteArrayElements(env, video, 0);
		if (NULL == videoBuf)
			goto ERROR;
	}
#endif // __Android__

    int iOSAlign = 0;
    int iOSEventOffset = 0;
#ifdef __IOS__
    iOSAlign = 32;
    if(1 == hasEvent && NULL != eventBoard.frame)
        iOSEventOffset = eventBoard.frame->width - 64;
#endif

	if(NULL == inputVideoFrame || NULL == YUV420PVideoFrame||NULL == inputVideoScale || NULL == outputVideoScale)
        goto ERROR;

    avpicture_fill((AVPicture *)inputVideoFrame, videoBuf, inputVideoFrame->format,
			inputVideoFrame->width, inputVideoFrame->height);
    avpicture_fill((AVPicture *)outputVideoFrame, dstBuf, outputVideoFrame->format,
			outputVideoFrame->width, outputVideoFrame->height);

    sws_scale(inputVideoScale, (const uint8_t * const *)inputVideoFrame->data, inputVideoFrame->linesize, 0,
            YUV420PVideoFrame->height, YUV420PVideoFrame->data, YUV420PVideoFrame->linesize);

    if(NULL != logoFrame)
		nRC = blend_image(YUV420PVideoFrame, logoFrame, logoRect.left, logoRect.top);
		//nRC = blend_image(YUV420PVideoFrame, logoFrame, logoRect.left - iOSAlign, logoRect.top);
    if(0 != nRC)
        goto ERROR;

    if(1 == hasScoreboard)
	{
		if(NULL == hostTeam.frame || NULL == timeBoard.frame || NULL == visitingTeam.frame)
			goto ERROR;

		nRC = blend_image(YUV420PVideoFrame, hostTeam.frame,
				hostTeam.frameRect.left - iOSAlign, hostTeam.frameRect.top);
		if(0 != nRC)
			goto ERROR;

		if(NULL != staticFrame)
		{
			nRC = blend_image(YUV420PVideoFrame, staticFrame,
					staticFrameRect.left - iOSAlign, staticFrameRect.top);
			if(0 != nRC)
				goto ERROR;
		}

		// NOTE : Because of UI design issue, we should blend time board before visiting team.
		nRC = blend_image(YUV420PVideoFrame, timeBoard.frame,
				timeBoard.frameRect.left - iOSAlign, timeBoard.frameRect.top);
		if(0 != nRC)
			goto ERROR;

		nRC = blend_image(YUV420PVideoFrame, visitingTeam.frame,
				visitingTeam.frameRect.left - iOSAlign, visitingTeam.frameRect.top);
		if(0 != nRC)
			goto ERROR;
	}

    if(1 == hasEvent && NULL != eventBoard.frame)
		nRC = blend_image(YUV420PVideoFrame, eventBoard.frame,
				eventBoard.frameRect.left - iOSEventOffset, eventBoard.frameRect.top);
    if(0 != nRC)
        goto ERROR;

    sws_scale(outputVideoScale, (const uint8_t * const *)YUV420PVideoFrame->data, YUV420PVideoFrame->linesize, 0,
            outputVideoFrame->height, outputVideoFrame->data, outputVideoFrame->linesize);
ERROR:

#ifdef __Android__
	if (NULL != dst && NULL != dstBuf)
		//(*env)->ReleaseByteArrayElements(env, dst, dstBuf, JNI_COMMIT);
		(*env)->ReleaseByteArrayElements(env, dst, dstBuf, 0);
	if (NULL != video && NULL != videoBuf)
		(*env)->ReleaseByteArrayElements(env, video, videoBuf, 0);
#endif // __Android__

    if(0 != nRC)
        ALOGE("%s Error return %d !!!\n", __func__, nRC);
	pthread_mutex_unlock(&interface_lock);

	return nRC;
}

static int Uninit(void)
{
	int nRC = 0;

	if(NULL != logoData)
		free(logoData);
	logoData = NULL;
	if(NULL != logoFrame)
		av_frame_free(&logoFrame);
	logoFrame = NULL;
        
	freePasterStruct(&hostTeam);
	freePasterStruct(&visitingTeam);
	freePasterStruct(&timeBoard);
	freePasterStruct(&eventBoard);

	if(NULL != inputVideoFrame)
		av_frame_free(&inputVideoFrame);
	inputVideoFrame = NULL;

	if(NULL != YUV420PVideoData)
        free(YUV420PVideoData);
	YUV420PVideoData = NULL;
	if(NULL != YUV420PVideoFrame)
		av_frame_free(&YUV420PVideoFrame);
	YUV420PVideoFrame = NULL;

	if(NULL != outputVideoFrame)
		av_frame_free(&outputVideoFrame);
	outputVideoFrame = NULL;

	if(NULL != fontPFPath)
		free(fontPFPath);
    fontPFPath = NULL;

    if(NULL != fontMisoBoldPath)
        free(fontMisoBoldPath);
    fontMisoBoldPath = NULL;

	if(NULL != scoreboardScale)
		sws_freeContext(scoreboardScale);
	scoreboardScale = NULL;

	if(NULL != eventScale)
		sws_freeContext(eventScale);
	eventScale = NULL;

	if(NULL != inputVideoScale)
		sws_freeContext(inputVideoScale);
	inputVideoScale = NULL;

	if(NULL != outputVideoScale)
		sws_freeContext(outputVideoScale);
	outputVideoScale = NULL;

    avfilter_uninit_font();

    m_nInited = 0;

	return nRC;
}

static int decode_picture(const char* picfile, AVFrame* logoFrame)
{
	int ret = 0;
	int decodeRet = -1;
	unsigned int i;
	AVCodecContext *codecCtx = NULL;
	int videoIdx = -1;
	AVPacket packet;
	AVFormatContext* fmtCtx = NULL;
	AVFrame* pFrame = NULL;

	av_register_all();

	fmtCtx = avformat_alloc_context();
	if ((ret = avformat_open_input(&fmtCtx, picfile, NULL, NULL)) < 0)
	{
		ALOGE("Cannot open input file:%s. ret %d\n", picfile, ret);
		goto ErrTag;
	}

	if ((ret = avformat_find_stream_info(fmtCtx, NULL)) < 0) {
		ALOGE("Cannot find stream information. ret %d\n", ret);
		goto ErrTag;
	}

	for (i = 0; i < fmtCtx->nb_streams; i++)
	{
		codecCtx = fmtCtx->streams[i]->codec;
		if (codecCtx->codec_type == AVMEDIA_TYPE_VIDEO)
		{
			/* Open decoder */
			AVCodec* pcodec = avcodec_find_decoder(codecCtx->codec_id);
			if(!pcodec)
			{
				ALOGE("Cannot find codec:%d.\n", codecCtx->codec_id);
				goto ErrTag;
			}

			ret = avcodec_open2(codecCtx, pcodec, NULL);
			if (ret < 0)
			{
				ALOGE("Failed to open decoder for video. ret %d\n", ret);
				goto ErrTag;
			}
			videoIdx = i;
			break;
		}
	}

	if (videoIdx < 0)
		goto ErrTag;

	if ((ret = av_read_frame(fmtCtx, &packet)) < 0)
	{
		ALOGE("Read frame failed. ret %d\n", ret);
		goto ErrTag;
	}

	int gotFrame = 0;
	pFrame = av_frame_alloc();
	if (!pFrame)
	{
		ALOGE("alloc_frame failed. ret %d\n", ret);
		goto ErrTag;
	}

	ret = avcodec_decode_video2(codecCtx, pFrame, &gotFrame, &packet);
	if (ret >= 0)
	{
		if(!gotFrame)
		{
			av_free_packet(&packet);
			packet.data = NULL;
			packet.size = 0;
			ret = avcodec_decode_video2(codecCtx, pFrame, &gotFrame, &packet);
		}
		if(gotFrame)
			decodeRet = 0;
	}

	if(!gotFrame)
	{
		ALOGE("Decode video frame failed:code:%d, gotFrame:%d.\n", ret, gotFrame);
		goto ErrTag;
	}

	int w = codecCtx->width, h = codecCtx->height;
	if(logoFrame->width == 0 || logoFrame->height == 0)
	{
		logoFrame->width = w;
		logoFrame->height = h;
	}

	struct SwsContext* pLogoSwScale = sws_getContext(w, h, codecCtx->pix_fmt,
			logoFrame->width, logoFrame->height, AV_PIX_FMT_YUVA420P, SWS_FAST_BILINEAR, NULL, NULL, NULL);

	sws_scale(pLogoSwScale, (const uint8_t * const *)pFrame->data, pFrame->linesize,
			0, h, logoFrame->data, logoFrame->linesize);

	sws_freeContext(pLogoSwScale);

	ALOGI("Complete getting picture frame.\n");

ErrTag:

	av_free_packet(&packet);
	if(pFrame) av_frame_free(&pFrame);
	if(fmtCtx)
	{
		if (videoIdx >= 0 && codecCtx)
			avcodec_close(codecCtx);

		avformat_close_input(&fmtCtx);
	}

	return decodeRet;
}

/**
 * Blend image in src to destination buffer dst at position (x, y).
 */
static int blend_image(AVFrame *dst, const AVFrame *src, int x, int y)
{
	const int src_w = src->width;
	const int src_h = src->height;
	const int dst_w = dst->width;
	const int dst_h = dst->height;

	if (x >= dst_w || x + src_w < 0 || y >= dst_h || y + src_h < 0)
		return -1; /* no intersection */

	if(x % 2 != 0)
		x -= 1;
	if(y % 2 != 0)
		y -= 1;

	int i, j;

	for(i=0; i<src_h; ++i)
	{
		if(i+y >= dst_h)
			break;

		uint8_t* pSrcY = src->data[0] + i * src->linesize[0];
		uint8_t* pDstY = dst->data[0] + ((i + y) * dst->linesize[0] + x);
		uint8_t* pSrcU = src->data[1] + (i >> 1) * src->linesize[1];
		uint8_t* pDstU = dst->data[1] + (((i + y) >> 1) * dst->linesize[1] + (x >> 1));
		uint8_t* pSrcV = src->data[2] + (i >> 1) * src->linesize[2];
		uint8_t* pDstV = dst->data[2] + (((i + y) >> 1) * dst->linesize[2] + (x >> 1));
		uint8_t* pSrcA = src->data[3] + i * src->linesize[3];

		j = 0;

		while(j < src_w)
		{
			if(j+x >= dst_w)
				break;

			uint8_t alpha = *pSrcA++;

			if(alpha != 255) // alpha
			{
				uint8_t curY = *pDstY;
				uint8_t mainAlpha = 255 - alpha;

				*pDstY = FAST_DIV255(curY * mainAlpha + (*pSrcY) * alpha);
				pDstY++;
				pSrcY++;

				if(0 == i % 2 && 0 == j % 2)
				{
					uint8_t curU = *pDstU;
					uint8_t curV = *pDstV;
					*pDstU = FAST_DIV255(curU*mainAlpha + (*pSrcU) * alpha);
					*pDstV = FAST_DIV255(curV*mainAlpha + (*pSrcV) * alpha);
					pDstU++; pSrcU++;
					pDstV++; pSrcV++;
				}
			}
			else
			{
				*pDstY++ = *pSrcY++;
				if(0 == i % 2 && 0 == j % 2)
				{
					*pDstU++ = *pSrcU++;
					*pDstV++ = *pSrcV++;
				}
			}
			++j;
		}
	}

	return 0;
}

static void setDefaultRect(int gameType, int width, int height)
{
	int iOSWidthOffset = 0, iOSHeightOffset = 0;
#ifdef __IOS__
	iOSWidthOffset = 62 * DESIGN_WIDTH;
    iOSHeightOffset = 2 * DESIGN_HEIGHT;
#endif // __iOS__

	logoRect.left = 1148 * DESIGN_WIDTH + iOSWidthOffset;
	logoRect.top = 30 *  DESIGN_HEIGHT;
	logoRect.right = 1250 * DESIGN_WIDTH + iOSWidthOffset;
	logoRect.bottom = 70 * DESIGN_HEIGHT;

	eventBoard.frameRect.left = 0;
	eventBoard.frameRect.top = 666 * DESIGN_HEIGHT;
	eventBoard.frameRect.right = width;
	eventBoard.frameRect.bottom = height;

	if(BASKETBALL == gameType)
	{
		hostTeam.frameRect.left = visitingTeam.frameRect.left = timeBoard.frameRect.left = 1052 * DESIGN_WIDTH + iOSWidthOffset;
		hostTeam.frameRect.right = visitingTeam.frameRect.right = timeBoard.frameRect.right = 1250 * DESIGN_WIDTH + iOSWidthOffset;

		hostTeam.frameRect.top = 534 * DESIGN_HEIGHT + iOSHeightOffset;
		hostTeam.frameRect.bottom = 584 * DESIGN_HEIGHT + iOSHeightOffset;

		visitingTeam.frameRect.top = 576 * DESIGN_HEIGHT;
		visitingTeam.frameRect.bottom = 626 * DESIGN_HEIGHT;

		timeBoard.frameRect.top = 618 * DESIGN_HEIGHT;
		timeBoard.frameRect.bottom = 656 * DESIGN_HEIGHT;

		hostTeam.textRect.left = visitingTeam.textRect.left = 0;
		hostTeam.textRect.top = visitingTeam.textRect.top = 7 * DESIGN_HEIGHT - iOSHeightOffset;
		hostTeam.textRect.width = visitingTeam.textRect.width = 148 * DESIGN_WIDTH;
		hostTeam.textRect.height = visitingTeam.textRect.height = 28 * DESIGN_HEIGHT - iOSHeightOffset;

		timeBoard.textRect.left = 0;
		timeBoard.textRect.top = 0;
		timeBoard.textRect.width = 190 * DESIGN_WIDTH; 
		timeBoard.textRect.height = 38 * DESIGN_HEIGHT; 

		hostTeam.scoreRect.left = visitingTeam.scoreRect.left = 148 * DESIGN_WIDTH;
		hostTeam.scoreRect.top = visitingTeam.scoreRect.top = 0 + iOSHeightOffset;
		hostTeam.scoreRect.width = visitingTeam.scoreRect.width = 46 * DESIGN_WIDTH;
		hostTeam.scoreRect.height = visitingTeam.scoreRect.height = 40 * DESIGN_HEIGHT + iOSHeightOffset;
	}
	else if(FOOTBALL == gameType)
	{
		hostTeam.frameRect.left = 30 * DESIGN_WIDTH + 2 * iOSWidthOffset;
		hostTeam.frameRect.top = 30 * DESIGN_HEIGHT;
		hostTeam.frameRect.right = 222 * DESIGN_WIDTH + 2 * iOSWidthOffset;
		hostTeam.frameRect.bottom = 80 * DESIGN_HEIGHT;

		hostTeam.textRect.left = 0;
		hostTeam.textRect.top = 0;
		hostTeam.textRect.width = 152 * DESIGN_WIDTH;
		hostTeam.textRect.height = 40 * DESIGN_HEIGHT;

		hostTeam.scoreRect.left = 142 * DESIGN_WIDTH;
		hostTeam.scoreRect.top = 0;
		hostTeam.scoreRect.width = 50 * DESIGN_WIDTH;
		hostTeam.scoreRect.height = 50 * DESIGN_HEIGHT;

		visitingTeam.frameRect.left = 223 * DESIGN_WIDTH + 2 * iOSWidthOffset;
		visitingTeam.frameRect.top = 30 * DESIGN_HEIGHT;
		visitingTeam.frameRect.right = 415 * DESIGN_WIDTH + 2 * iOSWidthOffset;
		visitingTeam.frameRect.bottom = 80 * DESIGN_HEIGHT;

		visitingTeam.textRect.left = 40 * DESIGN_WIDTH;
		visitingTeam.textRect.top = 0;
		visitingTeam.textRect.width = 152 * DESIGN_WIDTH;
		visitingTeam.textRect.height = 40 * DESIGN_HEIGHT;

		visitingTeam.scoreRect.left = 0;
		visitingTeam.scoreRect.top = 0;
		visitingTeam.scoreRect.width = 50 * DESIGN_WIDTH;
		visitingTeam.scoreRect.height = 50 * DESIGN_HEIGHT;

		timeBoard.frameRect.left = 148 * DESIGN_WIDTH + 2 * iOSWidthOffset; 
		timeBoard.frameRect.top = 76 * DESIGN_HEIGHT;
		timeBoard.frameRect.right = 298 * DESIGN_WIDTH + 2 * iOSWidthOffset;
		timeBoard.frameRect.bottom = 116 * DESIGN_HEIGHT;

		timeBoard.textRect.left = 0; 
		timeBoard.textRect.top = 0; 
		timeBoard.textRect.width = 150 * DESIGN_WIDTH; 
		timeBoard.textRect.height = 25 * DESIGN_HEIGHT; 

		staticFrameRect.left = 222 * DESIGN_WIDTH + 2 * iOSWidthOffset;
		staticFrameRect.top = 36 * DESIGN_HEIGHT;
		staticFrameRect.right = 224 * DESIGN_WIDTH + 2 * iOSWidthOffset;
		staticFrameRect.bottom = 76 * DESIGN_HEIGHT;
	}

	hostTeam.textRect.align = visitingTeam.textRect.align = timeBoard.textRect.align = 1;
	hostTeam.scoreRect.align = visitingTeam.scoreRect.align = 1;

ALOGI("%s:Line %d logo frame rect left %d top %d right %d bottom %d\n", __func__, __LINE__,
		logoRect.left, logoRect.top, logoRect.right, logoRect.bottom);
ALOGI("%s:Line %d event board rect left %d top %d right %d bottom %d\n", __func__, __LINE__,
		eventBoard.frameRect.left, eventBoard.frameRect.top,
		eventBoard.frameRect.right, eventBoard.frameRect.bottom);
ALOGI("%s:Line %d host frame rect left %d top %d right %d bottom %d\n", __func__, __LINE__,
		hostTeam.frameRect.left, hostTeam.frameRect.top, hostTeam.frameRect.right, hostTeam.frameRect.bottom);
ALOGI("%s:Line %d visiting frame rect left %d top %d right %d bottom %d\n", __func__, __LINE__,
		visitingTeam.frameRect.left, visitingTeam.frameRect.top, 
		visitingTeam.frameRect.right, visitingTeam.frameRect.bottom);
ALOGI("%s:Line %d time board rect left %d top %d right %d bottom %d\n", __func__, __LINE__,
		timeBoard.frameRect.left, timeBoard.frameRect.top, timeBoard.frameRect.right, timeBoard.frameRect.bottom);

ALOGI("%s:Line %d host text rect left %d top %d W * H = %d * %d\n", __func__, __LINE__,
		hostTeam.textRect.left, hostTeam.textRect.top, hostTeam.textRect.width, hostTeam.textRect.height);
ALOGI("%s:Line %d visiting text rect left %d top %d W * H = %d * %d\n", __func__, __LINE__,
		visitingTeam.textRect.left, visitingTeam.textRect.top,
		visitingTeam.textRect.width, visitingTeam.textRect.height);

	return;
}

static int fillPasterFrame(const char* picfile, PasterStruct* paster)
{
	if(NULL == paster)
		return -1;

	int nRC = 0;

    if(NULL != paster->frame)
        av_frame_free(&paster->frame);
	if(NULL != paster->frameData)
        free(paster->frameData);
    if(NULL != paster->originalFrame)
        av_frame_free(&paster->originalFrame);
	if(NULL != paster->originalFrameData)
        free(paster->originalFrameData);

    paster->frame = av_frame_alloc();
	paster->originalFrame = av_frame_alloc();

	if(NULL == paster->frame || NULL == paster->originalFrame)
	{
		ALOGE("%s:Line %d frame %p original %p nRC %d\n", __func__, __LINE__,
				paster->frame, paster->originalFrame, nRC);
		goto End;
	}

ALOGE("%s:Line %d left %d top %d right %d bottom %d\n", __func__, __LINE__, paster->frameRect.left, paster->frameRect.top, paster->frameRect.right, paster->frameRect.bottom);

	paster->originalFrame->width = paster->frame->width = paster->frameRect.right - paster->frameRect.left;
	paster->originalFrame->height = paster->frame->height = paster->frameRect.bottom - paster->frameRect.top;
	paster->originalFrame->format = paster->frame->format = AV_PIX_FMT_YUVA420P;

    paster->frameData = malloc(avpicture_get_size(AV_PIX_FMT_YUVA420P,
				paster->frame->width, paster->frame->height));
	paster->originalFrameData = malloc(avpicture_get_size(AV_PIX_FMT_YUVA420P,
				paster->originalFrame->width, paster->originalFrame->height));

	avpicture_fill((AVPicture *)paster->frame, paster->frameData, AV_PIX_FMT_YUVA420P,
			paster->frame->width, paster->frame->height);
	avpicture_fill((AVPicture *)paster->originalFrame, paster->originalFrameData, AV_PIX_FMT_YUVA420P,
			paster->originalFrame->width, paster->originalFrame->height);

	av_frame_get_buffer(paster->frame, 16);
	av_frame_get_buffer(paster->originalFrame, 16);

	nRC = decode_picture(picfile, paster->frame);
	if(0 != nRC)
	{
		ALOGE("%s:Line %d nRC %d\n", __func__, __LINE__, nRC);
		goto End;
	}

ALOGE("%s:Line %d src W * H = %d * %d format %d \n", __func__, __LINE__,
		paster->frame->width, paster->frame->height, paster->frame->format);
ALOGE("%s:Line %d dst W * H = %d * %d format %d \n", __func__, __LINE__, 
		paster->originalFrame->width, paster->originalFrame->height, paster->originalFrame->format);

	nRC = av_frame_copy(paster->originalFrame, paster->frame);
	if(0 != nRC)
		ALOGE("%s:Line %d nRC %d\n", __func__, __LINE__, nRC);

End:
	if(0 != nRC)
	{
		if(NULL != paster->frameData)
			free(paster->frameData);
		av_frame_free(&paster->frame);
		paster->frameData = NULL;
		paster->frame = NULL;

		if(NULL != paster->originalFrameData)
			free(paster->originalFrameData);
		av_frame_free(&paster->originalFrame);
		paster->originalFrameData = NULL;
		paster->originalFrame = NULL;
	}

	ALOGE("%s:Line %d nRC %d\n", __func__, __LINE__, nRC);
	return nRC;
}

#ifndef __IOS__
static inline int decode_vui(GetBitContext *gb, SPS *sps, int *timing_index)
{
    int aspect_ratio_info_present_flag;
    unsigned int aspect_ratio_idc;

    aspect_ratio_info_present_flag = get_bits1(gb);

    if (aspect_ratio_info_present_flag)
	{
        aspect_ratio_idc = get_bits(gb, 8);
        if (aspect_ratio_idc == EXTENDED_SAR)
		{
            sps->sar.num = get_bits(gb, 16);
            sps->sar.den = get_bits(gb, 16);
        }
		else if (aspect_ratio_idc >= FF_ARRAY_ELEMS(ff_h264_pixel_aspect))
		{
            return -1;
        }
    }
	else
	{
        sps->sar.num = sps->sar.den = 0;
    }

    if (get_bits1(gb))      /* overscan_info_present_flag */
        get_bits1(gb);      /* overscan_appropriate_flag */

    sps->video_signal_type_present_flag = get_bits1(gb);
    if (sps->video_signal_type_present_flag) {
        get_bits(gb, 3);                 /* video_format */
        sps->full_range = get_bits1(gb); /* video_full_range_flag */

        sps->colour_description_present_flag = get_bits1(gb);
        if (sps->colour_description_present_flag) {
            sps->color_primaries = get_bits(gb, 8); /* colour_primaries */
            sps->color_trc       = get_bits(gb, 8); /* transfer_characteristics */
            sps->colorspace      = get_bits(gb, 8); /* matrix_coefficients */
            if (sps->color_primaries >= AVCOL_PRI_NB)
                sps->color_primaries = AVCOL_PRI_UNSPECIFIED;
            if (sps->color_trc >= AVCOL_TRC_NB)
                sps->color_trc = AVCOL_TRC_UNSPECIFIED;
            if (sps->colorspace >= AVCOL_SPC_NB)
                sps->colorspace = AVCOL_SPC_UNSPECIFIED;
        }
    }

    /* chroma_location_info_present_flag */
    if (get_bits1(gb)) {
        /* chroma_sample_location_type_top_field */
        get_ue_golomb(gb);
        get_ue_golomb(gb);  /* chroma_sample_location_type_bottom_field */
    }

    if (show_bits1(gb) && get_bits_left(gb) < 10) {
        return 0;
    }

	*timing_index = gb->index;

    sps->timing_info_present_flag = get_bits1(gb);
    if (sps->timing_info_present_flag) {
        unsigned num_units_in_tick = get_bits_long(gb, 32);
        unsigned time_scale        = get_bits_long(gb, 32);
        if (!num_units_in_tick || !time_scale) {
            sps->timing_info_present_flag = 0;
        } else {
            sps->num_units_in_tick = num_units_in_tick;
            sps->time_scale = time_scale;
        }
        sps->fixed_frame_rate_flag = get_bits1(gb);
    }
    return 0;
}

static int AddVUI2SPS(uint8_t *inputSPS, int inputSize, int num_units_in_tick, int time_scale, uint8_t **outputSPS)
{
	int nRC = -1;
    int profile_idc, level_idc, constraint_set_flags = 0;
    unsigned int sps_id;
    int i, log2_max_frame_num_minus4;
	int sps_size = 0;
	int vui_index = 0, timing_index = 0;
	unsigned char *sps_data = NULL;

    SPS *sps = av_mallocz(sizeof(SPS));
	GetBitContext *gb = (GetBitContext *)malloc(sizeof(GetBitContext));

    if (NULL == sps || NULL == gb)
		goto fail;

	gb->buffer = inputSPS;
	gb->buffer_end = gb->buffer + inputSize * sizeof(uint8_t);
	gb->index = 0;
    gb->size_in_bits = inputSize * sizeof(uint8_t) * 8;
	gb->size_in_bits_plus8 = gb->size_in_bits + 8;

    profile_idc           = get_bits(gb, 8);
    constraint_set_flags |= get_bits1(gb) << 0;   // constraint_set0_flag
    constraint_set_flags |= get_bits1(gb) << 1;   // constraint_set1_flag
    constraint_set_flags |= get_bits1(gb) << 2;   // constraint_set2_flag
    constraint_set_flags |= get_bits1(gb) << 3;   // constraint_set3_flag
    constraint_set_flags |= get_bits1(gb) << 4;   // constraint_set4_flag
    constraint_set_flags |= get_bits1(gb) << 5;   // constraint_set5_flag
    skip_bits(gb, 2);                             // reserved_zero_2bits
    level_idc = get_bits(gb, 8);
    sps_id    = get_ue_golomb_31(gb);

    if (sps_id >= MAX_SPS_COUNT)
		goto fail;

	sps_size = gb->buffer_end - gb->buffer;
	sps_data = (unsigned char*)malloc(sps_size);
	if(NULL == sps_data)
		goto fail;
	memcpy(sps_data, gb->buffer, sps_size); 

    sps->sps_id               = sps_id;
    sps->time_offset_length   = 24;
    sps->profile_idc          = profile_idc;
    sps->constraint_set_flags = constraint_set_flags;
    sps->level_idc            = level_idc;
    sps->full_range           = -1;

    memset(sps->scaling_matrix4, 16, sizeof(sps->scaling_matrix4));
    memset(sps->scaling_matrix8, 16, sizeof(sps->scaling_matrix8));
    sps->scaling_matrix_present = 0;
    sps->colorspace = 2; //AVCOL_SPC_UNSPECIFIED

    if (sps->profile_idc == 100 ||  // High profile
        sps->profile_idc == 110 ||  // High10 profile
        sps->profile_idc == 122 ||  // High422 profile
        sps->profile_idc == 244 ||  // High444 Predictive profile
        sps->profile_idc ==  44 ||  // Cavlc444 profile
        sps->profile_idc ==  83 ||  // Scalable Constrained High profile (SVC)
        sps->profile_idc ==  86 ||  // Scalable High Intra profile (SVC)
        sps->profile_idc == 118 ||  // Stereo High profile (MVC)
        sps->profile_idc == 128 ||  // Multiview High profile (MVC)
        sps->profile_idc == 138 ||  // Multiview Depth High profile (MVCD)
        sps->profile_idc == 144) {  // old High444 profile
        sps->chroma_format_idc = get_ue_golomb_31(gb);
        if (sps->chroma_format_idc > 3U) {
            goto fail;
        } else if (sps->chroma_format_idc == 3) {
            sps->residual_color_transform_flag = get_bits1(gb);
            if (sps->residual_color_transform_flag) {
                goto fail;
            }
        }
        sps->bit_depth_luma   = get_ue_golomb(gb) + 8;
        sps->bit_depth_chroma = get_ue_golomb(gb) + 8;
        if (sps->bit_depth_chroma != sps->bit_depth_luma) {
            goto fail;
        }
        if (sps->bit_depth_luma   < 8 || sps->bit_depth_luma   > 14 ||
            sps->bit_depth_chroma < 8 || sps->bit_depth_chroma > 14) {
            goto fail;
        }
        sps->transform_bypass = get_bits1(gb);
    } else {
        sps->chroma_format_idc = 1;
        sps->bit_depth_luma    = 8;
        sps->bit_depth_chroma  = 8;
    }

    log2_max_frame_num_minus4 = get_ue_golomb(gb);
    if (log2_max_frame_num_minus4 < MIN_LOG2_MAX_FRAME_NUM - 4 ||
        log2_max_frame_num_minus4 > MAX_LOG2_MAX_FRAME_NUM - 4) {
        goto fail;
    }
    sps->log2_max_frame_num = log2_max_frame_num_minus4 + 4;

    sps->poc_type = get_ue_golomb_31(gb);

    if (sps->poc_type == 0) { // FIXME #define
        unsigned t = get_ue_golomb(gb);
        if (t>12) {
            goto fail;
        }
        sps->log2_max_poc_lsb = t + 4;
    } else if (sps->poc_type == 1) { // FIXME #define
        sps->delta_pic_order_always_zero_flag = get_bits1(gb);
        sps->offset_for_non_ref_pic           = get_se_golomb(gb);
        sps->offset_for_top_to_bottom_field   = get_se_golomb(gb);
        sps->poc_cycle_length                 = get_ue_golomb(gb);

        if ((unsigned)sps->poc_cycle_length >= FF_ARRAY_ELEMS(sps->offset_for_ref_frame)) {
            goto fail;
        }

        for (i = 0; i < sps->poc_cycle_length; i++)
            sps->offset_for_ref_frame[i] = get_se_golomb(gb);
    } else if (sps->poc_type != 2) {
        goto fail;
    }

    sps->ref_frame_count = get_ue_golomb_31(gb);
    if (sps->ref_frame_count > H264_MAX_PICTURE_COUNT - 2 || sps->ref_frame_count > 16U) {
        goto fail;
    }
    sps->gaps_in_frame_num_allowed_flag = get_bits1(gb);
    sps->mb_width                       = get_ue_golomb(gb) + 1;
    sps->mb_height                      = get_ue_golomb(gb) + 1;

    sps->frame_mbs_only_flag = get_bits1(gb);
    if (!sps->frame_mbs_only_flag)
        sps->mb_aff = get_bits1(gb);
    else
        sps->mb_aff = 0;

    sps->direct_8x8_inference_flag = get_bits1(gb);

    sps->crop = get_bits1(gb);

	vui_index = gb->index;

    sps->vui_parameters_present_flag = get_bits1(gb) || 1;
    if (sps->vui_parameters_present_flag) {
        int ret = decode_vui(gb, sps, &timing_index);
        if (ret < 0)
            goto fail;
    }

#if 1 // Modify the output sps
	if(vui_index > 0 && timing_index > 0)
	{
		int i = 0, j = 0, k = 0, remainder = 0, mask = 0, keepedIndex = 0, inputRem = 0;;
		while(i <= timing_index)
		{
			j = i / 8;
			remainder = i % 8;
			mask = ((1 << (7 - remainder)) & sps_data[j]) > 0 ? 1 : 0;

			if(i == vui_index)
			{
				(*outputSPS)[j] |= (1 << (7 - remainder));
			}
			else if(i < timing_index)
			{
				(*outputSPS)[j] |= (mask << (7 - remainder));
			}
			if(i == timing_index)
			{
				(*outputSPS)[j] |= (1 << (7 - remainder));

				keepedIndex = j;
				inputRem = remainder;

				k = 0;
				while(k < 32)
				{
					i ++;
					remainder = i % 8;
					if(0 == (i % 8)) j ++;

					mask = ((1 << (31 - k)) & num_units_in_tick) > 0 ? 1 : 0;

					(*outputSPS)[j] |= (mask << (7 - remainder));
					k ++;
				}

				k = 0;
				while(k < 32)
				{
					i ++;
					remainder = i % 8;
					if(0 == (i % 8)) j ++;

					mask = ((1 << (31 - k)) & time_scale) > 0 ? 1 : 0;

					(*outputSPS)[j] |= (mask << (7 - remainder));
					k ++;
				}
				break;
			}

			i ++;
		}

		while(keepedIndex < inputSize)
		{
			i ++;
			remainder = i % 8;
			if(0 == i % 8) { keepedIndex ++; j ++; }

			mask = ((1 << (7 - remainder)) & sps_data[keepedIndex]) > 0 ? 1 : 0;
			(*outputSPS)[j] |= (mask << (7 - remainder));
		}

		nRC = 0;
	}
#endif

fail:
	if(NULL != sps)
		av_free(sps);
	sps = NULL;
	if(NULL != gb)
		free(gb);
	gb = NULL;

    return nRC;
}
#endif

static void freePasterStruct(PasterStruct *paster)
{
	if(NULL == paster)
		return;

	if(NULL != paster->frameData)
		free(paster->frameData);
	if(NULL != paster->frame)
		free(paster->frame);
	if(NULL != paster->originalFrameData)
		free(paster->originalFrameData);
	if(NULL != paster->originalFrame)
		free(paster->originalFrame);
	if(NULL != paster->textRect.data)
		free(paster->textRect.data);

	memset(paster, 0, sizeof(PasterStruct));

	return;
}
