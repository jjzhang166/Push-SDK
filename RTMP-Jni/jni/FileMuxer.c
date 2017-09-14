//
//  FileMuxer.c
//  anchor
//
//  Created by wangyong on 2017/6/14.
//

#include "FileMuxer.h"

static void dumpFileFormat(const char *filename)
{
		int nRC = 0;
		AVFormatContext *ctx = NULL;

		nRC = avformat_open_input(&ctx, filename, 0, 0);
		if (nRC < 0) {
			ALOGE( "Eoollo: Could not open input file : %s.\n", filename);
			goto ERR;
		}

		if ((nRC = avformat_find_stream_info(ctx, 0)) < 0) {
			ALOGE( "Eoollo: Failed to retrieve input stream information\n");
			goto ERR;
		}

		ALOGI("################### Input file information #################### \n");
		av_dump_format(ctx, 0, filename, 0);
		ALOGI("################### Input file information #################### \n");

ERR:
	if(NULL != ctx)
		avformat_close_input(&ctx);
}

#if 0
static void getFileInfo(MuxerHandler* handler)
{
	const char *filename = handler->outputName;
	char in_filename_v[100];
	memset(in_filename_v, 0, sizeof(in_filename_v));
	int i = 0;
	for(i = 0; i < strlen(filename) - 10; i ++)
		in_filename_v[i] = filename[i];
	const char suffix[] = "111.mp4";
	int j = 0;
	for(j = 0; j < sizeof(suffix); j ++)
		in_filename_v[i ++] = suffix[j];
	ALOGI("LEIXIAOHUA: input name %s\n", in_filename_v);


	int ret = 0;
	AVFormatContext *ifmt_ctx_v = NULL;

	if ((ret = avformat_open_input(&ifmt_ctx_v, in_filename_v, 0, 0)) < 0) {
		ALOGI( "LEIXIAOHUA: Could not open input file.\n");
		return;
	}
	if ((ret = avformat_find_stream_info(ifmt_ctx_v, 0)) < 0) {
		ALOGI( "LEIXIAOHUA: Failed to retrieve input stream information\n");
		return;
	}

	ALOGI("=========== LEIXIAOHUA: Input Information==========\n");
	av_dump_format(ifmt_ctx_v, 0, in_filename_v, 0);
	ALOGI("=========== LEIXIAOHUA: ===========================\n");

	for (int i = 0; i < ifmt_ctx_v->nb_streams; i++) {
		//Create output AVStream according to input AVStream
		if(ifmt_ctx_v->streams[i]->codec->codec_type==AVMEDIA_TYPE_VIDEO){
			AVStream *st = ifmt_ctx_v->streams[i];
			handler->input_video_st = st;

			ALOGI("LEIXIAOHUA : codec_id %d bit_rate %d width %d height %d den %d num %d gop_size %d pix_fmt %d NV12 %d\n", st->codec->codec_id,
					st->codec->bit_rate, st->codec->width, st->codec->height, st->time_base.den, st->time_base.num, st->codec->gop_size, st->codec->pix_fmt,
					AV_PIX_FMT_NV12);

			ALOGI("LEIXIAOHUA: video extra data : ");
			if(NULL != st->codec->extradata)
				for(int j = 0; j < st->codec->extradata_size; j++)
					ALOGI("%X ", st->codec->extradata[j]);
			ALOGI("\n");
		} else if(AVMEDIA_TYPE_AUDIO == ifmt_ctx_v->streams[i]->codec->codec_type){
			AVStream *st = ifmt_ctx_v->streams[i];
			handler->input_audio_st = st;

			ALOGI("LEIXIAOHUA : frame_size %d per sample %d\n", st->codec->frame_size, av_get_bits_per_sample(st->codec->codec_id));

			ALOGI("LEIXIAOHUA: codec_type %d AUDIO %d sample_fmt %d bit_rate %d sample_rate %d channels %d layout %lld den %d num %d\n", st->codec->codec_type,
					AVMEDIA_TYPE_AUDIO, st->codec->sample_fmt, st->codec->bit_rate, st->codec->sample_rate, st->codec->channels, st->codec->channel_layout,
					st->time_base.den, st->time_base.num);
			ALOGI("LEIXIAOHUA: audio extra data : ");
			if(NULL != st->codec->extradata)
				for(int j = 0; j < st->codec->extradata_size; j++)
					ALOGI("%X ", st->codec->extradata[j]);
			ALOGI("\n");
		}
	}
}
#endif

#ifdef __Android__
jlong PackageName(nativeInit)(JNIEnv *env, jobject thiz)
#else
long long FileMuxerInit(void)
#endif // __IOS__
{
    MuxerHandler *handler = malloc(sizeof(struct MuxerHandler));
    if(NULL == handler)
		return ERROR_MEMORY;
    memset(handler, 0, sizeof(struct MuxerHandler));
	handler->audioStartPTS = RECORD_INIT_PTS;
	handler->audioStartDTS = RECORD_INIT_PTS;
	handler->videoStartPTS = RECORD_INIT_PTS;
	handler->videoStartDTS = RECORD_INIT_PTS;
	handler->fileHeaderWrited = false;
	handler->videoKeyframeArrived = false;
ALOGI("Eoollo Line %d handler %p\n", __LINE__, handler);

	handler->audioPrePTS = RECORD_INIT_PTS;
	handler->videoPrePTS = RECORD_INIT_PTS;

    pthread_mutex_init(&handler->interface_lock, NULL);

	return (long long)handler;
}

#ifdef __Android__
jint PackageName(nativeUninit)(JNIEnv *env, jobject thiz, jlong nHandler)
#else
int FileMuxerUninit(long long nHandler)
#endif // __IOS__
{
	HANDLER_CHECK_AND_CAST;

ALOGI("Eoollo Line %d handler %p\n", __LINE__, handler);

	pthread_mutex_destroy(&handler->interface_lock);
	free(handler);
	handler = NULL;

	return ERROR_NONE;
}

#ifdef __Android__
jint PackageName(nativeOpen)(JNIEnv *env, jobject thiz, jlong nHandler, jstring jfilename)
#else
int FileMuxerOpen(long long nHandler, const char *filename)
#endif // __IOS__
{
	HANDLER_CHECK_AND_CAST;

	pthread_mutex_lock(&handler->interface_lock);

#ifdef __Android__
	jboolean isCopy;
	char* filename = NULL;
	if(NULL != jfilename)
		filename = (char*)(*env)->GetStringUTFChars(env, jfilename, &isCopy);
	if(NULL == filename)
	{
		ALOGE("Eoollo Cannot get input file name !!!\n");
		goto END;
	}
#endif //__Android__

	AVDictionary* opt = NULL;
    int nRC = ERROR_NONE;

    av_register_all();

	handler->outputName = malloc(strlen(filename));
	memset(handler->outputName, 0, strlen(filename));
	if(NULL != handler->outputName)
	{
		strcpy(handler->outputName, filename);
	}

ALOGI("Eoollo Line %d handler %p file %s output %s\n", __LINE__, handler, filename, handler->outputName);

    avformat_alloc_output_context2(&(handler->oc), NULL, NULL, filename);
    if(NULL == handler->oc || NULL == handler->oc->oformat)
	{
	   ALOGE("Eoollo avformat_alloc_output_context2 failed !\n");
       goto END;
	}

    handler->oc->oformat->audio_codec = handler->audioInfo.codecID;
    handler->oc->oformat->video_codec = handler->videoInfo.codecID;
    handler->fmt = handler->oc->oformat;

	handler->oc->oformat->flags |= AVFMT_GLOBALHEADER;

	handler->video_st = CreateOutputStream(handler, AVMEDIA_TYPE_VIDEO);
	handler->audio_st = CreateOutputStream(handler, AVMEDIA_TYPE_AUDIO);
	if(NULL == handler->audio_st || NULL == handler->video_st)
	{
		ALOGE("Eoollo Could not create audio %p video %p\n", handler->audio_st, handler->video_st);
		nRC = ERROR_FFMPEG_INIT;
		goto END;
	}
	handler->oc->bit_rate = handler->audioInfo.bitrate + handler->videoInfo.bitrate;

	av_dump_format(handler->oc, 0, filename, 1);
    
	if (!(handler->fmt->flags & AVFMT_NOFILE))
	{
		nRC = avio_open(&(handler->oc->pb), filename, AVIO_FLAG_WRITE);
		if (ERROR_NONE > nRC)
		{
		    ALOGE("Eoollo avio_open failed, nRC %d\n", nRC);
			goto END;
		}
	}

	av_dict_set_int(&opt, "video_track_timescale", 1000, 0); // This 1000 assocate with video fps and input packet pts/dts/duration.
	
    nRC = avformat_write_header(handler->oc, &opt);
    if(ERROR_NONE > nRC)
	{
		ALOGE("Eoollo avformat_write_header error : %d\n", nRC);
		goto END;
	}
	handler->fileHeaderWrited = true;

	handler->h264bsfc =  av_bitstream_filter_init("h264_mp4toannexb");
	handler->aacbsfc =  av_bitstream_filter_init("aac_adtstoasc");

END:

#ifdef __Android__
	if(NULL != jfilename && NULL != filename)
		(*env)->ReleaseStringUTFChars (env, jfilename, filename);
#endif // __Android__

	pthread_mutex_unlock(&handler->interface_lock);

    return nRC;
}

#ifdef __Android__
jint PackageName(nativeClose)(JNIEnv *env, jobject thiz, jlong nHandler)
#else
int FileMuxerClose(long long nHandler)
#endif // __IOS__
{
	HANDLER_CHECK_AND_CAST;

	pthread_mutex_lock(&handler->interface_lock);

ALOGI("Eoollo Line %d handler %p\n", __LINE__, handler);
    if(NULL != handler->oc)
    {
		// We can write tailer unless write header successfully
		if(true == handler->fileHeaderWrited)
			av_write_trailer(handler->oc);

        if (NULL != handler->video_st && NULL != handler->video_st->codec)
		{
			if(NULL != handler->video_st->codec->extradata)
			{
				free(handler->video_st->codec->extradata);
				handler->video_st->codec->extradata = NULL;
			}
			avcodec_close(handler->video_st->codec);
		}

		if (NULL != handler->audio_st && NULL != handler->audio_st->codec)
			avcodec_close(handler->audio_st->codec);

		if (NULL != handler->fmt && !(handler->fmt->flags & AVFMT_NOFILE))
			avio_close(handler->oc->pb);

		avformat_free_context(handler->oc);
		handler->oc = NULL;

		if(NULL != handler->spsppsInfo.sps)
			free(handler->spsppsInfo.sps);
		handler->spsppsInfo.sps = NULL;

		if(NULL != handler->spsppsInfo.pps)
			free(handler->spsppsInfo.pps);
		handler->spsppsInfo.pps = NULL;

#if 0 // For get reference information
		if(NULL != handler->input_audio_st && NULL != handler->input_audio_st->codec)
			avcodec_close(handler->input_audio_st->codec);

		if(NULL != handler->input_video_st && NULL != handler->input_video_st->codec)
			avcodec_close(handler->input_video_st->codec);
#endif
	}

	if(NULL != handler->outputName)
	{
#ifndef __Android__
		dumpFileFormat(handler->outputName);
#endif
		free(handler->outputName);
		handler->outputName = NULL;
	}

	memset(handler, 0, sizeof(struct MuxerHandler));
	handler->audioStartPTS = RECORD_INIT_PTS;
	handler->audioStartDTS = RECORD_INIT_PTS;
	handler->videoStartPTS = RECORD_INIT_PTS;
	handler->videoStartDTS = RECORD_INIT_PTS;
	handler->fileHeaderWrited = false;
	handler->videoKeyframeArrived = false;

	handler->audioPrePTS = RECORD_INIT_PTS;
	handler->videoPrePTS = RECORD_INIT_PTS;

#ifdef __Android__
	if(NULL != handler->adts_header)
		handler->adts_header = NULL;
#endif

	pthread_mutex_unlock(&handler->interface_lock);

	return ERROR_NONE;
}

#ifdef __Android__
jint PackageName(nativeSetAudioParameter)(JNIEnv *env, jobject thiz,
		jlong nHandler, jint codecID, jint bitrate, jint samplerate, jint samplebit, jint channels)
#else
int FileMuxerSetAudioParameter(long long nHandler, int codecID, int bitrate, int samplerate, int samplebit, int channels)
#endif // __IOS__
{
	HANDLER_CHECK_AND_CAST;

	pthread_mutex_lock(&handler->interface_lock);

ALOGI("Eoollo Line %d handler %p codecID %d bitrate %d samplerate %d samplebit %d channels %d\n", __LINE__, handler,
						  codecID, bitrate, samplerate, samplebit, channels);
	handler->audioInfo.codecID = codecID;
	handler->audioInfo.bitrate = bitrate;
	handler->audioInfo.samplerate = samplerate;
	handler->audioInfo.samplebit = samplebit;
	handler->audioInfo.channels = channels;

	pthread_mutex_unlock(&handler->interface_lock);

	return ERROR_NONE;
}

#ifdef __Android__
jint PackageName(nativeSetVideoParameter)(JNIEnv *env, jobject thiz,
		jlong nHandler, jint codecID, jint bitrate, jint width, jint height, jint fps, jint gopsize)
#else
int FileMuxerSetVideoParameter(long long nHandler, int codecID, int bitrate, int width, int height, int fps, int gopsize)
#endif // __IOS__
{
	HANDLER_CHECK_AND_CAST;

	pthread_mutex_lock(&handler->interface_lock);

ALOGI("Eoollo Line %d handler %p codecID %d bitrate %d width %d height %d fps %d gopsize %d\n", __LINE__, handler,
						  codecID, bitrate, width, height, fps, gopsize);

	handler->videoInfo.codecID = codecID;
	handler->videoInfo.bitrate = bitrate;
	handler->videoInfo.width = width;
	handler->videoInfo.height = height;
	handler->videoInfo.fps = fps;
	handler->videoInfo.gopsize = gopsize;
    
	pthread_mutex_unlock(&handler->interface_lock);

	return ERROR_NONE;
}

#ifdef __Android__
jint PackageName(nativeSetSPSPPS)(JNIEnv *env, jobject thiz,
		jlong nHandler, uint8_t* jsps, uint8_t *jpps, jint spsSize, jint ppsSize)
#else
int FileMuxerSetSPSPPS(long long nHandler, uint8_t* sps, uint8_t *pps, int spsSize, int ppsSize)
#endif // __IOS__
{
	HANDLER_CHECK_AND_CAST;

	pthread_mutex_lock(&handler->interface_lock);

	int nRC = ERROR_NONE;

#ifdef __Android__
ALOGI("Eoollo Line %d handler %p sps %p size %d pps %p size %d\n", __LINE__, handler, jsps, spsSize, jpps, ppsSize);
	jbyte* sps = 0;        
	jbyte* pps = 0;      

	if(NULL != jsps)           
	{
		sps = (jbyte*)(*env)->GetByteArrayElements(env, jsps, 0);
		if (NULL == sps)
		{
			nRC = ERROR_JAVA_ENV;
			ALOGE("Eoollo Line %d get sps data failed !!!", __LINE__);
			goto ERR;
		}
	}

	if(NULL != jpps)
	{
		pps = (jbyte*)(*env)->GetByteArrayElements(env, jpps, 0);
		if (NULL == pps)
		{
			nRC = ERROR_JAVA_ENV;
			ALOGE("Eoollo Line %d get pps data failed !!!", __LINE__);
			goto ERR;
		}
	}
#endif // __Android__

	handler->spsppsInfo.spsLen = spsSize;
	handler->spsppsInfo.ppsLen = ppsSize;
	handler->spsppsInfo.sps = malloc(handler->spsppsInfo.spsLen);
	handler->spsppsInfo.pps = malloc(handler->spsppsInfo.ppsLen);
	if(NULL == handler->spsppsInfo.sps || NULL == handler->spsppsInfo.pps)
	{
		nRC = ERROR_MEMORY;
		ALOGE("Eoollo Line %d alloc sps %p pps %p data failed !!!", __LINE__, handler->spsppsInfo.sps, handler->spsppsInfo.pps);
		goto ERR;
	}

	memset(handler->spsppsInfo.sps, 0, handler->spsppsInfo.spsLen);
	memset(handler->spsppsInfo.pps, 0, handler->spsppsInfo.ppsLen);
	memcpy(handler->spsppsInfo.sps, sps, spsSize);
	memcpy(handler->spsppsInfo.pps, pps, ppsSize);

	handler->video_st->codec->extradata_size = handler->spsppsInfo.spsLen + handler->spsppsInfo.ppsLen;
	handler->video_st->codec->extradata = malloc(handler->video_st->codec->extradata_size);
	if(NULL == handler->video_st->codec->extradata)
	{
		nRC = ERROR_MEMORY;
		ALOGE("Eoollo Line %d alloc extra data failed !!!", __LINE__);
		goto ERR;
	}
	memset(handler->video_st->codec->extradata, 0, handler->video_st->codec->extradata_size);
	memcpy(handler->video_st->codec->extradata, handler->spsppsInfo.pps, handler->spsppsInfo.ppsLen);
	memcpy(handler->video_st->codec->extradata + handler->spsppsInfo.ppsLen, handler->spsppsInfo.sps, handler->spsppsInfo.spsLen);

#if 0
	ALOGE("Audio Extra Data : ");
	for(int i = 0; i < handler->audio_st->codec->extradata_size; i ++)
		ALOGE("%X ", handler->audio_st->codec->extradata[i]);
	ALOGE("\n");

	ALOGE("Video Extra Data : ");
	for(int i = 0; i < handler->video_st->codec->extradata_size; i ++)
		ALOGE("%X ", handler->video_st->codec->extradata[i]);
	ALOGE("\n");
#endif

ERR:
#ifdef __Android__
	if (NULL != jsps && NULL != sps)
		(*env)->ReleaseByteArrayElements(env, jsps, sps, 0);
	if (NULL != jpps && NULL != pps)
		(*env)->ReleaseByteArrayElements(env, jpps, pps, 0);

#endif // __Android__

	pthread_mutex_unlock(&handler->interface_lock);

	ALOGI("Eoollo Line %d set spspps return %d !!!", __LINE__, nRC);
	return nRC;
}

#ifdef __Android__
jint PackageName(nativeInputAudioSample)(JNIEnv *env, jobject thiz,
		jlong nHandler, uint8_t *jdata, jint size, jlong pts, jlong dts) 
#else
int FileMuxerInputAudioSample(long long nHandler, uint8_t *data, int size, long long pts, long long dts)
#endif // __IOS__
{
	HANDLER_CHECK_AND_CAST;

	pthread_mutex_lock(&handler->interface_lock);

	int nRC = ERROR_NONE;

	if(false == handler->videoKeyframeArrived)
	{
		ALOGE("Eoollo Drop audio sample, wait for video I frame!\n");
		goto ERR;
	}

	if(RECORD_INIT_PTS == handler->audioStartPTS)
		handler->audioStartPTS = pts;
	if(RECORD_INIT_PTS == handler->audioStartDTS)
		handler->audioStartDTS = dts;
	pts -= handler->audioStartPTS;
	dts -= handler->audioStartDTS;

#ifdef __Android__
	int adts_header = 0;
#endif
	pts = pts / AVSYNC_DRIFT_SCALE;
	dts = dts / AVSYNC_DRIFT_SCALE;

#ifdef __USER_BLOCK__
	int random = rand() % 10;
	if(true == needBlocked && 0 == random)
	{
		//ALOGE("Eoollo muxer drop Audio !!!\n");
		goto ERR;
	}
#endif // __USER_BLOCK__

	if(NULL == handler->audio_st)
	{
		nRC = ERROR_POINTER;
		ALOGE("Eoollo no audio input stream\n");
		goto ERR;
	}

#ifdef __Android__
	uint8_t* adtsData = 0;      
	jbyte* jEnvData = 0;
	jbyte* data = 0;

	if(NULL != jdata)           
	{
		jEnvData = data = (jbyte*)(*env)->GetByteArrayElements(env, jdata, 0);
		if (NULL == data)
		{
			nRC = ERROR_JAVA_ENV;
			ALOGE("Eoollo cannot get audio input data\n");
			goto ERR;
		}
	}

#endif // __Android__

	AVPacket pkt = { 0 };
	av_init_packet(&pkt);
	pkt.data = data;
	pkt.size = size;
#if 1
	if(RECORD_INIT_PTS == handler->audioPrePTS)
	{
		pkt.duration = 20;
		handler->audioPrePTS = pts;
	}
	else
		pkt.duration = pts - handler->audioPrePTS;
	pkt.pts = pts;
	pkt.dts = dts;
	handler->audioPrePTS = pts;
#else
	pkt.pts = av_rescale_q_rnd(pts, handler->audio_st->time_base, handler->audio_st->time_base, (enum AVRounding)(AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));  
	pkt.dts = av_rescale_q_rnd(dts, handler->audio_st->time_base, handler->audio_st->time_base, (enum AVRounding)(AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));  
	pkt.duration = av_rescale_q(pkt.duration, handler->audio_st->time_base, handler->audio_st->time_base);
#endif

	pkt.stream_index = handler->audio_st->index;
	handler->oc->debug = FF_FDEBUG_TS;

	if(NULL != handler->aacbsfc && NULL != handler->audio_st->codec)
		nRC = av_bitstream_filter_filter(handler->aacbsfc, handler->audio_st->codec, NULL, &pkt.data, &pkt.size, pkt.data, pkt.size, 0); 

//ALOGE("Eoollo Line %d AUDIO handler %p pts %lld dts %lld size %d duration %d nRC %d", __LINE__, handler, pkt.pts, pkt.dts, size, pkt.duration, nRC);

	nRC = av_interleaved_write_frame(handler->oc, &pkt);

	if(0 > nRC)
		ALOGE("Eoollo Audio av_interleaved_write_frame error : %d\n", nRC);

ERR:
#ifdef __Android__
	if (NULL != jdata && NULL != jEnvData)
		(*env)->ReleaseByteArrayElements(env, jdata, jEnvData, 0);
	if(NULL != adtsData)
		free(adtsData);
#endif // __Android__

	pthread_mutex_unlock(&handler->interface_lock);

	return nRC;
}

#ifdef __Android__
jint PackageName(nativeInputVideoSample)(JNIEnv *env, jobject thiz,
		jlong nHandler, uint8_t *jdata, jint size, jlong pts, jlong dts, jboolean keyframe)
#else
int FileMuxerInputVideoSample(long long nHandler, uint8_t *data, int size, long long pts, long long dts, bool keyframe)
#endif // __IOS__
{
	HANDLER_CHECK_AND_CAST;

	pthread_mutex_lock(&handler->interface_lock);

	int nRC = ERROR_NONE;
	int metadataLen = 0;
	uint8_t *allocData = NULL;

	if(true == keyframe)
		handler->videoKeyframeArrived = true;
	if(false == handler->videoKeyframeArrived)
	{
		ALOGE("Eoollo Drop video sample, wait for I frame!\n");
		goto ERR;
	}

	if(RECORD_INIT_PTS == handler->videoStartPTS)
		handler->videoStartPTS = pts;
	if(RECORD_INIT_PTS == handler->videoStartDTS)
		handler->videoStartDTS = dts;
	pts -= handler->videoStartPTS;
	dts -= handler->videoStartDTS;
	pts /= 1000;
	dts /= 1000;

#ifdef __USER_BLOCK__
	int random = rand() % 10;
	if(true == needBlocked && 0 == random)
	{
		//ALOGE("Eoollo muxer drop Video !!!\n");
		goto ERR;
	}
#endif // __USER_BLOCK__

	if(NULL == handler->video_st)
	{
		nRC = ERROR_POINTER;
		ALOGE("Eoollo no video input stream\n");
		goto ERR;
	}

#ifdef __Android__
	jbyte* data = 0, *tmpData = 0;
	if(NULL != jdata)           
	{
		data = (jbyte*)(*env)->GetByteArrayElements(env, jdata, 0);
		if (NULL == data)
		{
			nRC = ERROR_JAVA_ENV;
			ALOGE("Eoollo cannot get video input data\n");
			goto ERR;
		}
		tmpData = data;
	}
#endif // __Android__

	AVPacket pkt = { 0 };
	av_init_packet(&pkt);
	pkt.size = size;

	if (true == keyframe && NULL != handler->spsppsInfo.sps && NULL != handler->spsppsInfo.pps)
			metadataLen = handler->spsppsInfo.spsLen + handler->spsppsInfo.ppsLen;

	if(0 < metadataLen) // Add SPS/PPS infront of each key frames
	{
		pkt.size = size +  metadataLen;
		allocData = malloc(pkt.size);
		memcpy(allocData, handler->spsppsInfo.sps, handler->spsppsInfo.spsLen);
		memcpy(allocData + handler->spsppsInfo.spsLen, handler->spsppsInfo.pps, handler->spsppsInfo.ppsLen);
		memcpy(allocData + metadataLen, data, size);
		data = allocData;
	}


	/*
	uint8_t nal_start[] = {0, 0, 0, 1};
	pkt.size = size + metadataLen + sizeof(nal_start);

	allocData = malloc(pkt.size);
	if(NULL == allocData)
	{
		nRC = ERROR_MEMORY;
		goto ERR;
	}
	memset(allocData, 0, pkt.size);

	if(0 < metadataLen) // Add SPS/PPS infront of each key frames
	{	
		memcpy(allocData, handler->spsppsInfo.sps, handler->spsppsInfo.spsLen);
		memcpy(allocData + handler->spsppsInfo.spsLen, handler->spsppsInfo.pps, handler->spsppsInfo.ppsLen);
	}
	//memcpy(allocData + metadataLen, nal_start, sizeof(nal_start));
	allocData[metadataLen] = 0x01;
	allocData[metadataLen + 1] = 0x00;
	allocData[metadataLen + 2] = 0x00;
	allocData[metadataLen + 3] = 0x00;
	memcpy(allocData + metadataLen + sizeof(uint8_t) * 4, data, size);
	memcpy(allocData + metadataLen, data, size);
	*/

	if(true == keyframe)
		pkt.flags |= AV_PKT_FLAG_KEY;

	pkt.data = data;
	pkt.stream_index = handler->video_st->index;

#if 1
	if(RECORD_INIT_PTS == handler->videoPrePTS)
	{
		pkt.duration = 40;
		handler->videoPrePTS = pts;
	}
	else
		pkt.duration = pts - handler->videoPrePTS;

	pkt.pts = pts;
	pkt.dts = dts;
	handler->videoPrePTS = pkt.pts;
#else
	pkt.pts = av_rescale_q_rnd(pts, handler->video_st->time_base, handler->video_st->time_base, (enum AVRounding)(AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));  
	pkt.dts = av_rescale_q_rnd(dts, handler->video_st->time_base, handler->video_st->time_base, (enum AVRounding)(AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));  
	pkt.duration = av_rescale_q(pkt.duration, handler->video_st->time_base, handler->video_st->time_base);
#endif

	if(NULL != handler->h264bsfc && NULL != handler->video_st->codec)
		av_bitstream_filter_filter(handler->h264bsfc, handler->video_st->codec, NULL, &pkt.data, &pkt.size, pkt.data, pkt.size, 0);  

//ALOGE("Eoollo Line %d VIDEO handler %p pts %lld dts %lld size %d duration %d keyframe %d", __LINE__, handler, pkt.pts, pkt.dts, size, pkt.duration, keyframe);

	nRC = av_interleaved_write_frame(handler->oc, &pkt);

	if(0 > nRC)
		ALOGE("Eoollo Video av_interleaved_write_frame error : %d keyframe %d\n", nRC, keyframe);

ERR:
	if(NULL != allocData)
		free(allocData);

#ifdef __Android__
	if (NULL != jdata && NULL != tmpData)
		(*env)->ReleaseByteArrayElements(env, jdata, tmpData, 0);
#endif // __Android__

	pthread_mutex_unlock(&handler->interface_lock);

	return nRC;
}


///// **** private **** ///////

static AVStream *CreateOutputStream(MuxerHandler *handler, int streamType)
{

	if(NULL == handler)
		return NULL;

	AVStream *st = NULL;

#if 0
	AVStream* in_stream = AVMEDIA_TYPE_AUDIO == streamType ? handler->input_audio_st : handler->input_video_st;
	st = avformat_new_stream(handler->oc, in_stream->codec->codec);
	st->id = handler->oc->nb_streams - 1;
	avcodec_copy_context(st->codec, in_stream->codec);
	st->codec->codec_tag = 0;
#else
	int codec_id = AVMEDIA_TYPE_AUDIO == streamType ? handler->audioInfo.codecID : handler->videoInfo.codecID;

	AVCodec *codec = avcodec_find_encoder(codec_id);
	if (NULL == codec)
	{
		ALOGE("Line %d Eoollo Could not find encoder id %d for '%s'\n", __LINE__, codec_id, avcodec_get_name(codec_id));
		return NULL;
	}
	
	st = avformat_new_stream(handler->oc, codec);
	if (NULL == st || NULL == st->codec)
	{
		ALOGE("Eoollo Could not allocate stream\n");
		return NULL;
	}

	st->id = handler->oc->nb_streams - 1;

	switch (streamType)
	{
		case AVMEDIA_TYPE_AUDIO:
			st->codec->sample_fmt		= AV_SAMPLE_FMT_FLTP;
			st->codec->channels			= handler->audioInfo.channels;
			st->codec->bit_rate			= handler->audioInfo.bitrate;
			st->codec->sample_rate		= handler->audioInfo.samplerate;
			st->codec->frame_size		= 2048; // Accroding encoder setting

			break;
	case AVMEDIA_TYPE_VIDEO:
			st->codec->pix_fmt  = AV_PIX_FMT_YUV420P;
			st->codec->gop_size = 12; /* emit one intra frame every twelve frames at most */
			st->codec->codec_id = handler->videoInfo.codecID;
			st->codec->bit_rate = handler->videoInfo.bitrate;
			st->codec->width    = handler->videoInfo.width;
			st->codec->height   = handler->videoInfo.height;

			st->codec->time_base.num = 1;
			st->codec->time_base.den = (int)handler->videoInfo.fps;

			break;
	default:
			break;
	}
#endif

#if 1
	if (handler->oc->oformat->flags & AVFMT_GLOBALHEADER)
		st->codec->flags |= CODEC_FLAG_GLOBAL_HEADER;
#endif

	return st;
}

#ifdef __Android__
static int generateADTSHeader(MuxerHandler *handler, int size)
{
	if (NULL == handler)
	{
		ALOGE("Eoollo generateADTSHeader with NULL handler !!!");
		return -1;
	}

	if(NULL == handler->adts_header)
		handler->adts_header = (uint8_t*)malloc(7 * sizeof(uint8_t));

	uint8_t *adts_header = handler->adts_header;
	if(NULL == adts_header)
	{
		ALOGE("Eoollo generateADTSHeader alloc adts header failed !!!");
		return -1;
	}

	int sampleRate = 0;
	if(handler->audioInfo.samplerate >= 96000)sampleRate = 0;
	else if(handler->audioInfo.samplerate >= 88200)sampleRate = 1;
	else if(handler->audioInfo.samplerate >= 64000)sampleRate = 2;
	else if(handler->audioInfo.samplerate >= 48000)sampleRate = 3;
	else if(handler->audioInfo.samplerate >= 44100)sampleRate = 4;
	else if(handler->audioInfo.samplerate >= 32000)sampleRate = 5;
	else if(handler->audioInfo.samplerate >= 24000)sampleRate = 6;
	else if(handler->audioInfo.samplerate >= 22050)sampleRate = 7;
	else if(handler->audioInfo.samplerate >= 16000)sampleRate = 8;

///////// ADTS_FIXED_HEADER

	/* Sync point over a full byte */

	adts_header[0] = 0xFF; // 1 ~ 12 : 0xFFF syncword
	adts_header[1] = 0xF1; // 13 : ID. 14 ~ 15 : layer, always "00", 16 : protection_absent

	adts_header[2] = 0x01 << 6; // 17 ~ 18 : profile. main = 1, LC = 2, SSR = 3, LTP = 4, HE/SBR = 5;
	adts_header[2] |= (sampleRate << 2); /* 19 ~ 22 : sampleRate index over next 4 bits */

	/* 23 : private bit*/

	adts_header[2] |= (handler->audioInfo.channels & 0x4) >> 2; /* 24 ~ 26 : channels over last 2 bits */
	adts_header[3] = (handler->audioInfo.channels & 0x3) << 6; /* channels continued over next 2 bits + 4 bits at zero */

	/* 27 : original_copy*/
	/* 28 : home */

	//////// ADTS_VARIABLE_HEADER

	/* 29 : copyright_identification_bit */
	/* 30 : copyright_identification_start */

	adts_header[3] |= (size & 0x1800) >> 11; /* 31 ~ 43 : 13 bits for frame size. over last 2 bits */
	adts_header[4] = (size & 0x1FF8) >> 3; /* frame size continued over full byte */
	adts_header[5] = (size & 0x7) << 5; /* frame size continued first 3 bits */

	adts_header[5] |= 0x1F; /* 44 ~ 54 : buffer fullness (0x7FF for VBR) over 5 last bits */    
	adts_header[6] = 0xFC; /* buffer fullness (0x7FF for VBR) continued over 6 first bits + 2 zeros number of raw data blocks */

	adts_header[6] |= 0 & 0x03; // 55 ~ 56 : number_of_raw_data_blocks_in_frame.

	return 0;
}
#endif // __Android__
