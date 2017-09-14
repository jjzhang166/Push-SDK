#include <string.h>
#include <time.h>
#include <stdlib.h>
#include <sys/time.h>

#ifdef __Android__
#include <jni.h>
#include <android/log.h>
#define LOG_TAG "rtmp-jni"
#endif //__Android__

#include "librtmp-jni.h"
#include "libghttp-jni.h"

enum
{
	FLV_CODECID_H264 = 7,
	FLV_CODECID_AAC = 10,
};

char * put_byte( char *output, uint8_t nVal )
{
	output[0] = nVal;
	return output+1;
}
char * put_be16(char *output, uint16_t nVal )
{
	output[1] = nVal & 0xff;
	output[0] = nVal >> 8;
	return output+2;
}
char * put_be24(char *output,uint32_t nVal )
{
	output[2] = nVal & 0xff;
	output[1] = nVal >> 8;
	output[0] = nVal >> 16;
	return output+3;
}

char * put_be32(char *output, uint32_t nVal )
{
	output[3] = nVal & 0xff;
	output[2] = nVal >> 8;
	output[1] = nVal >> 16;
	output[0] = nVal >> 24;
	return output+4;
}

char *  put_be64( char *output, uint64_t nVal )
{
	output=put_be32( output, nVal >> 32 );
	output=put_be32( output, nVal );
	return output;
}
char * put_amf_string( char *c, const char *str )
{
	uint16_t len = strlen( str );
	c=put_be16( c, len );
	memcpy(c,str,len);
	return c+len;
}
char * put_amf_double( char *c, double d )
{
	*c++ = AMF_NUMBER;  /* type: Number */
	{
		unsigned char *ci, *co;
		ci = (unsigned char *)&d;
		co = (unsigned char *)c;
		co[0] = ci[7];
		co[1] = ci[6];
		co[2] = ci[5];
		co[3] = ci[4];
		co[4] = ci[3];
		co[5] = ci[2];
		co[6] = ci[1];
		co[7] = ci[0];
	}
	return c+8;
}

time_t getSysTime(void)
{
	time_t timeMs;

	timeMs = time(&timeMs);

	return timeMs;
}

int Connect(const char* url)
{
	ALOGE("RTMP Build Date : %s %s\n", __DATE__, __TIME__);
#ifdef __USER_BLOCK__
	if(DATE_AS_INT + 45 < (int)(getSysTime() / 86400))
		needBlocked = true;
	else
		needBlocked = false;
#endif // __USER_BLOCK__

	//memset(&m_sAudioBuffer, 0, sizeof(BufferStruct));
	//memset(&m_sVideoBuffer, 0, sizeof(BufferStruct));
	memset(&m_sMetadata, 0, sizeof(RTMPMetadata));
	memset(&m_sAudioInfo, 0, sizeof(AudioInfo));
	memset(&m_sVideoInfo, 0, sizeof(VideoInfo));
	m_sVideoInfo.nCodecID = FLV_CODECID_H264;
	m_sAudioInfo.nCodecID = FLV_CODECID_AAC;

	m_sVideoInfo.nWidth = 1280;
	m_sVideoInfo.nHeight = 720;
	m_sVideoInfo.nFPS = 15;

	m_sAudioInfo.nChannels = 1;
	m_sAudioInfo.nSampleRate = 44100;
	m_sAudioInfo.nSampleBit = 16;

	m_bAudioMetadataSend = -1;
	m_bVideoMetadataSend = 0;
	m_bStreamMetadataSend = -1;
	m_nSendAudioCount = 0;
	m_nSendVideoCount = 0;
	m_nAudioTimestamp = 0ll;
	m_nVideoTimestamp = 0ll;
	m_nSysTimestamp = getSysTime();
	m_nAbsSysTimeDiff = 0ll;

    m_nLastAudioTimestamp = -1;
    m_nLastVideoTimestamp = -1;

	m_pRtmp = RTMP_Alloc();
	RTMP_Init(m_pRtmp);

	if(RTMP_SetupURL(m_pRtmp, (char*)url) < 0)
	{
		ALOGE("RTMP_SetupURL Error Func %s Line %d url %s\n", __func__, __LINE__, url);
		return -1;
	}
	RTMP_EnableWrite(m_pRtmp);
	if(RTMP_Connect(m_pRtmp, NULL) < 0)
	{
		ALOGE("RTMP_Connect Error Func %s Line %d url %s\n", __func__, __LINE__, url);
		return -1;
	}
	if(RTMP_ConnectStream(m_pRtmp, 0) < 0)
	{
		ALOGE("RTMP_ConnectStream Error Func %s Line %d url %s\n", __func__, __LINE__, url);
		return -1;
	}

    m_nConnected = 1;
	return 0;
}

void Disconnect()
{
	if(NULL != m_pRtmp)
	{
		RTMP_Close(m_pRtmp);
		RTMP_Free(m_pRtmp);
		m_pRtmp = NULL;
	}
	m_nAbsSysTimeDiff = 0;

    m_nConnected = 0;
}

int SendPacket(unsigned int nPacketType, unsigned char *data, unsigned int size, int64_t nTimestamp)
{
	if(m_pRtmp == NULL)
	{
        m_nConnected = 0;
		return ERROR_DISCONNECT;
	}

#ifdef __USER_BLOCK__
	int random = rand() % 10;
	if(true == needBlocked && 0 == random) {
		return 0;
	}
#endif // __USER_BLOCK__

	RTMPPacket packet;
	RTMPPacket_Reset(&packet);
	RTMPPacket_Alloc(&packet, size);

	packet.m_packetType = nPacketType;
	packet.m_nChannel = 0x04;
	packet.m_headerType = RTMP_PACKET_SIZE_LARGE;
	packet.m_nTimeStamp = nTimestamp;
	packet.m_nInfoField2 = m_pRtmp->m_stream_id;
	packet.m_nBodySize = size;
	memcpy(packet.m_body, data, size);

	int nRet = RTMP_SendPacket(m_pRtmp, &packet, 0);

	RTMPPacket_Free(&packet);

	return TRUE == nRet ? 0 : nRet;
}

int Send_AAC_SPEC(void)
{
#define RTMP_HEAD_SIZE (sizeof(RTMPPacket)+RTMP_MAX_HEADER_SIZE)

    RTMPPacket * packet = NULL;
    unsigned char * body;
    int len = 2;  /*spec data长度,一般是2*/

    packet = (RTMPPacket *)malloc(RTMP_HEAD_SIZE + len + 2);
    memset(packet,0,RTMP_HEAD_SIZE);

    packet->m_body = (char *)packet + RTMP_HEAD_SIZE;
    body = (unsigned char *)packet->m_body;

	/*0 ~ 96000， 1~88200， 2~64000， 3~48000， 4~44100， 5~32000， 6~24000， 7~ 22050， 8~16000*/
	/*但是试验结果表明，当音频采样率小于等于44100时，应该选择3，而当音频采样率为48000时，应该选择2*/
	int sampleRate = 0;
	if(m_sAudioInfo.nSampleRate >= 96000)sampleRate = 0;
	else if(m_sAudioInfo.nSampleRate >= 88200)sampleRate = 1;
	else if(m_sAudioInfo.nSampleRate >= 64000)sampleRate = 2;
	else if(m_sAudioInfo.nSampleRate >= 48000)sampleRate = 3;
	else if(m_sAudioInfo.nSampleRate >= 44100)sampleRate = 4;
	else if(m_sAudioInfo.nSampleRate >= 32000)sampleRate = 5;
	else if(m_sAudioInfo.nSampleRate >= 24000)sampleRate = 6;
	else if(m_sAudioInfo.nSampleRate >= 22050)sampleRate = 7;
	else if(m_sAudioInfo.nSampleRate >= 16000)sampleRate = 8;

    /*AF 00 + AAC RAW data*/
    body[0] = 0xAF;
    body[1] = 0x00;

    body[2] = (0x1 << 4); // 1 ~ 5 : AAC profile type :main = 1, LC = 2, SSR = 3, LTP = 4, HE/SBR = 5;
    body[2] |= ((sampleRate & 0xF) >> 1); // 6 ~ 9 : Sample rate
    body[3] = (sampleRate & 0x1) << 7; // 6 ~ 9 : Sample Rate
    body[3] |= ((m_sAudioInfo.nChannels & 0xF) << 3); // 10 ~ 13 : Channel layout

    //memcpy(&body[2],spec_buf,len); /*spec_buf是AAC sequence header数据*/ 

    packet->m_packetType = RTMP_PACKET_TYPE_AUDIO;
    packet->m_nBodySize = len + 2;
    packet->m_nChannel = 0x04;
    packet->m_nTimeStamp = 0;
    packet->m_hasAbsTimestamp = 0;
    packet->m_headerType = RTMP_PACKET_SIZE_LARGE;
    packet->m_nInfoField2 = m_pRtmp->m_stream_id;

    /*调用发送接口*/  
    return RTMP_SendPacket(m_pRtmp, packet, TRUE);
}

int SendAudioMetadata(void)
{
	char body[1024] = {0};

	char * p = (char *)body;

	if(-1 == m_bStreamMetadataSend)
	{
		p = put_byte(p, AMF_STRING );
		p = put_amf_string(p , "@setDataFrame" );

		p = put_byte( p, AMF_STRING );
		p = put_amf_string( p, "onMetaData" );

		p = put_byte(p, AMF_OBJECT );
		p = put_amf_string( p, "copyright" );
		p = put_byte(p, AMF_STRING );
		p = put_amf_string( p, "WangYong" );

		p = put_amf_string( p, "audiocodecid" );
		p = put_amf_double( p, m_sAudioInfo.nCodecID );

		p = put_amf_string( p, "channels" );
		p = put_amf_double( p, m_sAudioInfo.nChannels );

		p = put_amf_string( p, "samplerate" );
		p = put_amf_double( p, m_sAudioInfo.nSampleRate );

		p = put_amf_string( p, "width");
		p = put_amf_double( p, m_sVideoInfo.nWidth);

		p = put_amf_string( p, "height");
		p = put_amf_double( p, m_sVideoInfo.nHeight);

		p = put_amf_string( p, "framerate" );
		p = put_amf_double( p, m_sVideoInfo.nFPS);

		p = put_amf_string( p, "videocodecid" );
		p = put_amf_double( p, m_sVideoInfo.nCodecID );

		p = put_amf_string( p, "" );
		p = put_byte(p, AMF_OBJECT_END);

		SendPacket(RTMP_PACKET_TYPE_INFO, (unsigned char*)body, p - body, 0);

		m_bStreamMetadataSend = 0;
	}

    return Send_AAC_SPEC();

#if 0
	unsigned char adts_header[11];
	unsigned int size = sizeof(adts_header);

	/*0 ~ 96000， 1~88200， 2~64000， 3~48000， 4~44100， 5~32000， 6~24000， 7~ 22050， 8~16000*/
	/*但是试验结果表明，当音频采样率小于等于44100时，应该选择3，而当音频采样率为48000时，应该选择2*/
	int sampleRate = 0;
	if(m_sAudioInfo.nSampleRate >= 96000)sampleRate = 0;
	else if(m_sAudioInfo.nSampleRate >= 88200)sampleRate = 1;
	else if(m_sAudioInfo.nSampleRate >= 64000)sampleRate = 2;
	else if(m_sAudioInfo.nSampleRate >= 48000)sampleRate = 3;
	else if(m_sAudioInfo.nSampleRate >= 44100)sampleRate = 4;
	else if(m_sAudioInfo.nSampleRate >= 32000)sampleRate = 5;
	else if(m_sAudioInfo.nSampleRate >= 24000)sampleRate = 6;
	else if(m_sAudioInfo.nSampleRate >= 22050)sampleRate = 7;
	else if(m_sAudioInfo.nSampleRate >= 16000)sampleRate = 8;

	memset(adts_header, 0, sizeof(adts_header));

	/* Generate ADTS header */

///////// ADTS_FIXED_HEADER

	/* Sync point over a full byte */
	adts_header[0] = 0xAF;
	adts_header[1] = 0x00;

    adts_header[2] = (0x1 << 4); // 1 ~ 5 : AAC profile type :main = 1, LC = 2, SSR = 3, LTP = 4, HE/SBR = 5;
    adts_header[2] |= ((sampleRate & 0xF) >> 1); // 6 ~ 9 : Sample rate
    adts_header[3] = (sampleRate & 0x1) << 7; // 6 ~ 9 : Sample Rate
    adts_header[3] |= ((m_sAudioInfo.nChannels & 0xF) << 3); // 10 ~ 13 : Channel layout
/*
	adts_header[2] = 0x13;
    adts_header[3] = 0x90;
*/

	adts_header[4] = 0xFF; // 1 ~ 12 : 0xFFF syncword
	adts_header[5] = 0xF1; // 13 : ID. 14 ~ 15 : layer, always "00", 16 : protection_absent

	adts_header[6] = 0x01 << 6; // 17 ~ 18 : profile. main = 1, LC = 2, SSR = 3, LTP = 4, HE/SBR = 5;
	adts_header[6] |= (sampleRate << 2); /* 19 ~ 22 : sampleRate index over next 4 bits */

	/* 23 : private bit*/

	adts_header[6] |= (m_sAudioInfo.nChannels & 0x4) >> 2; /* 24 ~ 26 : channels over last 2 bits */
	adts_header[7] = (m_sAudioInfo.nChannels & 0x3) << 6; /* channels continued over next 2 bits + 4 bits at zero */

	/* 27 : original_copy*/
	/* 28 : home */

//////// ADTS_VARIABLE_HEADER

	/* 29 : copyright_identification_bit */
	/* 30 : copyright_identification_start */

	adts_header[7] |= (size & 0x1800) >> 11; /* 31 ~ 43 : 13 bits for frame size. over last 2 bits */
	adts_header[8] = (size & 0x1FF8) >> 3; /* frame size continued over full byte */
	adts_header[9] = (size & 0x7) << 5; /* frame size continued first 3 bits */

	adts_header[9] |= 0x1F; /* 44 ~ 54 : buffer fullness (0x7FF for VBR) over 5 last bits */	
	adts_header[10] = 0xFC; /* buffer fullness (0x7FF for VBR) continued over 6 first bits + 2 zeros number of raw data blocks */

	adts_header[10] |= 0 & 0x03; // 55 ~ 56 : number_of_raw_data_blocks_in_frame.

	nRC = SendPacket(RTMP_PACKET_TYPE_AUDIO, adts_header, sizeof(adts_header), 0);

	return nRC;
#endif
}

int SendVideoMetadata(LPRTMPMetadata lpMetaData)
{
	if(lpMetaData == NULL)
	{
		return ERROR_METADATA;
	}
	char body[1024] = {0};

	char * p = (char *)body;

	if(-1 == m_bStreamMetadataSend)
	{
		p = put_byte(p, AMF_STRING );
		p = put_amf_string(p , "@setDataFrame" );

		p = put_byte( p, AMF_STRING );
		p = put_amf_string( p, "onMetaData" );

		p = put_byte(p, AMF_OBJECT );
		p = put_amf_string( p, "copyright" );
		p = put_byte(p, AMF_STRING );
		p = put_amf_string( p, "WangYong" );

		p = put_amf_string( p, "audiocodecid" );
		p = put_amf_double( p, m_sAudioInfo.nCodecID );

		p = put_amf_string( p, "channels" );
		p = put_amf_double( p, m_sAudioInfo.nChannels );

		p = put_amf_string( p, "samplerate" );
		p = put_amf_double( p, m_sAudioInfo.nSampleRate );

		p = put_amf_string( p, "width");
		p = put_amf_double( p, m_sVideoInfo.nWidth);

		p = put_amf_string( p, "height");
		p = put_amf_double( p, m_sVideoInfo.nHeight);

		p = put_amf_string( p, "framerate" );
		p = put_amf_double( p, m_sVideoInfo.nFPS);

		p = put_amf_string( p, "videocodecid" );
		p = put_amf_double( p, m_sVideoInfo.nCodecID );

		p = put_amf_string( p, "" );
		p = put_byte(p, AMF_OBJECT_END);

		SendPacket(RTMP_PACKET_TYPE_INFO, (unsigned char*)body, p - body, 0);

		m_bStreamMetadataSend = 0;
	}

	int i = 0;
	body[i++] = 0x17; // 1:keyframe  7:AVC
	body[i++] = 0x00; // AVC sequence header

	body[i++] = 0x00;
	body[i++] = 0x00;
	body[i++] = 0x00; // fill in 0;

	// AVCDecoderConfigurationRecord.
	body[i++] = 0x01; // configurationVersion
	body[i++] = lpMetaData->Sps[1]; // AVCProfileIndication
	body[i++] = lpMetaData->Sps[2]; // profile_compatibility
	body[i++] = lpMetaData->Sps[3]; // AVCLevelIndication
	body[i++] = 0xff; // lengthSizeMinusOne

	// sps nums
	body[i++] = 0xE1; //&0x1f
	// sps data length
	body[i++] = lpMetaData->nSpsLen>>8;
	body[i++] = lpMetaData->nSpsLen&0xff;
	// sps data
	memcpy(&body[i], lpMetaData->Sps, lpMetaData->nSpsLen);
	i += lpMetaData->nSpsLen;

	// pps nums
	body[i++] = 0x01; //&0x1f
	// pps data length
	body[i++] = lpMetaData->nPpsLen>>8;
	body[i++] = lpMetaData->nPpsLen&0xff;
	// sps data
	memcpy(&body[i], lpMetaData->Pps, lpMetaData->nPpsLen);
	i += lpMetaData->nPpsLen;

	return SendPacket(RTMP_PACKET_TYPE_VIDEO, (unsigned char*)body, i, 0);
}

int SendAACPacket(unsigned char *data, int headerSize, unsigned int size, int64_t nTimestamp)
{
	//int gap = m_nSysTimestamp + nTimestamp - getSysTime();
	//ALOGE("Eoollo Audio timestamp %lld gap %d curr %lld sys %lld", nTimestamp, gap, getSysTime(), m_nSysTimestamp);
    int nRC = 0;

	if(-1 == m_bAudioMetadataSend)
	{
		nRC = SendAudioMetadata();
        if(TRUE != nRC)
            nRC = SendAudioMetadata();
        if(TRUE == nRC)
            m_bAudioMetadataSend = 0;
		return TRUE == nRC ? 0 : ERROR_METADATA;
	}

    if(nTimestamp <= m_nLastAudioTimestamp)
    {
        ALOGE("Wrong timestamp %lld last %lld\n", nTimestamp, m_nLastAudioTimestamp);
        return ERROR_TIME;
    }
    m_nLastAudioTimestamp = nTimestamp;

#if 1
    int adts_header = sizeof(unsigned char) * 7;
#ifdef __Android__
    adts_header = 0;
#endif // __Android__
    if(NULL != data && size > adts_header)
    {
        unsigned char *body = malloc(size - adts_header + 2);
        body[0] = 0xAF;
        body[1] = 0x01;
        memcpy(&body[2], data + adts_header, size  - adts_header); // Remove ADTS header
        nRC = SendPacket(RTMP_PACKET_TYPE_AUDIO, body, size - adts_header + 2, nTimestamp);
        free(body);
    }
#else
	unsigned char adts_header[7];
	int sampleRate = 0;
	if(m_sAudioInfo.nSampleRate >= 96000)sampleRate = 0;
	else if(m_sAudioInfo.nSampleRate >= 88200)sampleRate = 1;
	else if(m_sAudioInfo.nSampleRate >= 64000)sampleRate = 2;
	else if(m_sAudioInfo.nSampleRate >= 48000)sampleRate = 3;
	else if(m_sAudioInfo.nSampleRate >= 44100)sampleRate = 4;
	else if(m_sAudioInfo.nSampleRate >= 32000)sampleRate = 5;
	else if(m_sAudioInfo.nSampleRate >= 24000)sampleRate = 6;
	else if(m_sAudioInfo.nSampleRate >= 22050)sampleRate = 7;
	else if(m_sAudioInfo.nSampleRate >= 16000)sampleRate = 8;

	memset(adts_header, 0, sizeof(adts_header));
///////// ADTS_FIXED_HEADER

	/* Sync point over a full byte */

	adts_header[0] = 0xFF; // 1 ~ 12 : 0xFFF syncword
	adts_header[1] = 0xF1; // 13 : ID. 14 ~ 15 : layer, always "00", 16 : protection_absent

	adts_header[2] = 0x01 << 6; // 17 ~ 18 : profile. main = 1, LC = 2, SSR = 3, LTP = 4, HE/SBR = 5;
	adts_header[2] |= (sampleRate << 2); /* 19 ~ 22 : sampleRate index over next 4 bits */

	/* 23 : private bit*/

	adts_header[2] |= (m_sAudioInfo.nChannels & 0x4) >> 2; /* 24 ~ 26 : channels over last 2 bits */
	adts_header[3] = (m_sAudioInfo.nChannels & 0x3) << 6; /* channels continued over next 2 bits + 4 bits at zero */

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


	unsigned char header[2] = {0xAF, 0x01};
	unsigned char *body = malloc(size + sizeof(header) + sizeof(adts_header));

	memcpy(body, header, sizeof(header));
	memcpy(body + sizeof(header), adts_header, sizeof(adts_header));
	memcpy(body + sizeof(header) + sizeof(adts_header), data, size);
	nRC = SendPacket(RTMP_PACKET_TYPE_AUDIO, body, size + sizeof(header) + sizeof(adts_header), nTimestamp);
	//ALOGE("Eoollo Line %d Audio timestamp %lld gap %d curr %lld sys %lld nRC %d"
	//		, __LINE__, nTimestamp, gap, getSysTime(), m_nSysTimestamp, nRC);

	free(body);

#endif
	return nRC;
}

int ParserSPSPPS(unsigned char *data, unsigned int size, int headerSize)
{
	int spsIndex = 0, ppsIndex = 0, i = 0;

	while(i < size - 4)
	{
		if(0 == (data[i] & 0xff) && 0 == (data[i + 1] & 0xff) && 0 == (data[i + 2] & 0xff) && 1 == (data[i + 3] & 0xff))
		{
			if(7 == (data[i + 4] & 0x1f))
				spsIndex = i + 4;
			else if(8 == (data[i + 4] & 0x1f))
				ppsIndex = i + 4;
		}
		i++;
	}

	if(spsIndex > 0 && ppsIndex > 0)
	{
		if(spsIndex < ppsIndex)
		{
			memcpy(m_sMetadata.Sps, data + headerSize, ppsIndex - spsIndex - headerSize);
			m_sMetadata.nSpsLen = ppsIndex - spsIndex - headerSize;

			memcpy(m_sMetadata.Pps, data + ppsIndex, size - ppsIndex);
			m_sMetadata.nPpsLen = size - ppsIndex;
		}
		else
		{
			memcpy(m_sMetadata.Pps, data + headerSize, spsIndex - ppsIndex - headerSize);
			m_sMetadata.nPpsLen = spsIndex - ppsIndex - headerSize;

			memcpy(m_sMetadata.Sps, data + spsIndex, size - spsIndex);
			m_sMetadata.nSpsLen = size - spsIndex;
		}
	}
	else if(spsIndex > 0)
	{
		memcpy(m_sMetadata.Sps, data + headerSize, size - headerSize);
		m_sMetadata.nSpsLen = size - headerSize;
	}
	else if(ppsIndex > 0)
	{
		memcpy(m_sMetadata.Pps, data + headerSize, size - headerSize);
		m_sMetadata.nPpsLen = size - headerSize;
	}

#if 0 // Force Add VUI
	if(m_sMetadata.nSpsLen > 10)
	{
		unsigned char *Sps = (unsigned char*)malloc(m_sMetadata.nSpsLen + sizeof(int) * 2 - 1);
		memset(Sps, 0, sizeof(int) * 2 + m_sMetadata.nSpsLen - 1);
		if(NULL != Sps)
		{
			int num_units_in_tick = NUM_UNITS_IN_TICK;
			int time_scale = NUM_UNITS_IN_TICK * 2 * m_sMetadata.nFrameRate;
			int nRC = AddVUI2SPS(m_sMetadata.Sps + 1, m_sMetadata.nSpsLen - 1, num_units_in_tick, time_scale, &Sps);

////////////////
ALOGE("%s:Line %d tick %d scale %d\n", __func__, __LINE__, num_units_in_tick, time_scale);
FILE *fd = fopen("/sdcard/111/outputSPS.data", "w+");
if(NULL != fd)
{
	fwrite(Sps, m_sMetadata.nSpsLen + sizeof(int) * 2 - 1, 1, fd);
	fclose(fd);
}
else
	ALOGE("Eoollo Cannot open outputSPS.data : %s\n", strerror(errno));
////////////////

			if(0 == nRC)
			{
				m_sMetadata.nSpsLen += ((sizeof(int) * 2));
				memcpy(&m_sMetadata.Sps[1], Sps, m_sMetadata.nSpsLen - 1);
			}
		}

		if(NULL != Sps)
			free(Sps);
		Sps = NULL;
	}
#endif // Force Add VUI

	return 0;
}

int FixMultiSlice(uint8_t* pBuffer, int bufLen)
{
	if(NULL == pBuffer || bufLen < 4)
		return -1;
	
	int nRC = 0, i = 0, preIndex = 0, size = 0, found = 0;
	uint8_t* startPos = pBuffer;
	while(i < bufLen - 4)
	{
		if(0 == (pBuffer[i] & 0xff) && 0 == (pBuffer[i + 1] & 0xff)
				&& 0 == (pBuffer[i + 2] & 0xff) && 1 == (pBuffer[i + 3] & 0xff))
		{
			if(0 != found)
			{
				size = i - preIndex - 4;

				pBuffer[preIndex++] = size >> 24;
				pBuffer[preIndex++] = size >> 16;
				pBuffer[preIndex++] = size >> 8;
				pBuffer[preIndex++] = size & 0xff;

				startPos += size;
			}
			preIndex = i;
			found = 1;

			if(0 == i)
				m_sVideoInfo.bMultiSlices ++;
			else
				m_sVideoInfo.bMultiSlices = 0;
		}
		i ++;
	}

	if(0 != found)
	{
		size = bufLen - preIndex - 4;
		pBuffer[preIndex++] = size >> 24;
		pBuffer[preIndex++] = size >> 16;
		pBuffer[preIndex++] = size >> 8;
		pBuffer[preIndex++] = size & 0xff;
	}

	return nRC;
}

int SendAbsPacket(int64_t curPos, int64_t nTimestamp)
{
	m_nSysTimestamp = curPos;

	unsigned char timeBuf[32];
	unsigned char strBuf[32];
	memset(timeBuf, 0, sizeof(timeBuf));
	memset(strBuf, 0, sizeof(strBuf));

	time_t ti = getSysTime();

    int msecs = m_nAbsSysTimeDiff % 1000;
	int diffUp = m_nAbsSysTimeDiff / 1000;

    bool negative = m_nAbsSysTimeDiff < 0 ? true : false;

    if(true == negative)
    {
        msecs += 1000;
        diffUp -= 1;
    }
    ti += diffUp;

	struct tm *p = localtime(&ti);

    unsigned char *pStr = timeBuf;
	pStr = (unsigned char *)put_byte((char *)pStr, AMF_STRING );
	sprintf((char *)strBuf, "tm%02d%02d%02d%03d", p->tm_hour, p->tm_min, p->tm_sec, msecs);
	pStr = (unsigned char *)put_amf_string((char *)pStr, (const char*)strBuf );

	return SendPacket(RTMP_PACKET_TYPE_INFO, timeBuf, pStr - timeBuf, nTimestamp + 5);
}

int SendH264Packet(unsigned char *data, unsigned int size, int headerSize, int bIsKeyFrame, int64_t nTimestamp)
{
	//ALOGI("Eoollo Func %s Line %d data %p size %d headerSize %d send %d keyframe %d", __func__, __LINE__, data, size, headerSize, m_bVideoMetadataSend, bIsKeyFrame);

    int nRC = 0;
	int64_t curPos = getSysTime();
	if(curPos - m_nSysTimestamp > 0)
		SendAbsPacket(curPos, nTimestamp);

	if(NULL != data && 321 != m_bVideoMetadataSend)
	{
		ALOGI("Eoollo Func %s Line %d send times %d size %d header size %d data & 0x1f = %d\n",
                __func__, __LINE__, m_bVideoMetadataSend, size, headerSize, (data[headerSize] & 0x1f));

        m_bVideoMetadataSend ++;
        if(m_bVideoMetadataSend > 2)
            return ERROR_METADATA;

		m_sMetadata.nWidth = m_sVideoInfo.nWidth;
		m_sMetadata.nHeight = m_sVideoInfo.nHeight;
		m_sMetadata.nFrameRate = m_sVideoInfo.nFPS;

		if(7 == (int)(data[headerSize] & 0x1f) || 8 == (int)(data[headerSize] & 0x1f))
			ParserSPSPPS(data, size, headerSize);

		if(m_sMetadata.nSpsLen > 0 && m_sMetadata.nPpsLen > 0)
		{
			nRC = SendVideoMetadata(&m_sMetadata);
            if(0 != nRC)
                nRC = SendVideoMetadata(&m_sMetadata);
            if(0 == nRC)
                m_bVideoMetadataSend = 321;
            else
                ALOGE("Error send video metadata %d !!!\n", nRC);
		}

		return nRC;
	}

	if(data == NULL)
		return ERROR_BUFFER;

	if(321 != m_bVideoMetadataSend)
		return ERROR_METADATA;

    if(nTimestamp <= m_nLastVideoTimestamp)
    {
        ALOGE("Wrong timestamp %lld last %lld\n", nTimestamp, m_nLastVideoTimestamp);
        return ERROR_TIME;
    }
    m_nLastVideoTimestamp = nTimestamp;


	int extroSize = 0;
	if(0 == bIsKeyFrame)
		extroSize = m_sMetadata.nSpsLen + m_sMetadata.nPpsLen + 8;

	unsigned char *body = malloc(size + 9 + extroSize);

	int i = 0;
	if(0 == bIsKeyFrame)
	{
		body[i++] = 0x17;// 1:Iframe  7:AVC
	}
	else
	{
		body[i++] = 0x27;// 2:Pframe  7:AVC
	}

	body[i++] = 0x01;// AVC NALU
	body[i++] = 0x00;
	body[i++] = 0x00;
	body[i++] = 0x00;

	if(0 == bIsKeyFrame)
	{
		body[i++] = m_sMetadata.nSpsLen >> 24;
		body[i++] = m_sMetadata.nSpsLen >> 16;
		body[i++] = m_sMetadata.nSpsLen >> 8;
		body[i++] = m_sMetadata.nSpsLen & 0xff;
		memcpy(&body[i], m_sMetadata.Sps, m_sMetadata.nSpsLen);
		i += m_sMetadata.nSpsLen;

		body[i++] = m_sMetadata.nPpsLen >> 24;
		body[i++] = m_sMetadata.nPpsLen >> 16;
		body[i++] = m_sMetadata.nPpsLen >> 8;
		body[i++] = m_sMetadata.nPpsLen & 0xff;
		memcpy(&body[i], m_sMetadata.Pps, m_sMetadata.nPpsLen);
		i += m_sMetadata.nPpsLen;
	}

#ifdef __IOS__
	// NALU size
	body[i++] = (size - headerSize)>>24;
	body[i++] = (size - headerSize)>>16;
	body[i++] = (size - headerSize)>>8;
	body[i++] = (size - headerSize)&0xff;
#else // Only Android has multi-slice frames
	if(5 >= m_sVideoInfo.bMultiSlices)
	{
		FixMultiSlice(data, size);
		headerSize = 0;
	}
	else
	{
		body[i++] = (size - headerSize)>>24;
		body[i++] = (size - headerSize)>>16;
		body[i++] = (size - headerSize)>>8;
		body[i++] = (size - headerSize)&0xff;
	}
#endif
	// NALU data

	memcpy(&body[i], data + headerSize, size - headerSize);

	//int gap = m_nSysTimestamp + m_nVideoTimestamp - getSysTime();
	//ALOGE("Eoollo Video timestamp %lld gap %d curr %lld sys %lld", m_nVideoTimestamp, gap, getSysTime(), m_nSysTimestamp);

	nRC = SendPacket(RTMP_PACKET_TYPE_VIDEO, body, i + size - headerSize, nTimestamp);
	//ALOGE("Eoollo Line %d Video timestamp %lld bRet %d", __LINE__, nTimestamp, nRC);

	free(body);

	return nRC;
}

#ifdef __Android__
jint PackageName(nativeSetAbsoluteTimeMs)(JNIEnv *env, jobject thiz, jint time)
#elif defined __IOS__
int setAbsoluteTimeMs(int time)
#endif // __Android__
{
	pthread_mutex_lock(&rtmp_jni_interface_lock);

	m_nAbsSysTimeDiff = time;

	ALOGI("%s: Line %d absolute time %d\n", __func__, __LINE__, time);

	pthread_mutex_unlock(&rtmp_jni_interface_lock);

	return 0;
}

#ifdef __Android__
jint PackageName(nativeConnect)(JNIEnv *env, jobject thiz, jstring jurl)
#elif defined __IOS__
int rtmpConnect(const char *url)
#endif // __Android__
{
	Disconnect();

	pthread_mutex_init(&rtmp_jni_interface_lock, NULL);
	pthread_mutex_lock(&rtmp_jni_interface_lock);

#ifdef __Android__
	jboolean isCopy;
    if(NULL == jurl)
    {
        pthread_mutex_unlock(&rtmp_jni_interface_lock);
        return ERROR_BUFFER;
    }
	const char *url = (*env)->GetStringUTFChars(env, jurl, &isCopy);
    if(NULL == url)
    {
        pthread_mutex_unlock(&rtmp_jni_interface_lock);
        return ERROR_BUFFER;
    }
#endif //__Android__

	int nRC = Connect(url);

	ALOGI("Func %s Line %d %s return %d\n", __func__, __LINE__, url, nRC);

#ifdef __Android__
    if(NULL != jurl && NULL != url)
        (*env)->ReleaseStringUTFChars (env, jurl, url);
#endif // __Android__

	pthread_mutex_unlock(&rtmp_jni_interface_lock);

	return 0 == nRC ? 0 : ERROR_NETWORK;
}

#ifdef __Android__
jint PackageName(nativeDisconnect)(JNIEnv *env, jobject thiz)
#elif defined __IOS__
int rtmpDisconnect()
#endif // __Android__
{
	pthread_mutex_lock(&rtmp_jni_interface_lock);

	Disconnect();

	pthread_mutex_unlock(&rtmp_jni_interface_lock);
	pthread_mutex_destroy(&rtmp_jni_interface_lock);
	return 0;
}

#ifdef __Android__
void PackageName(nativeSetAudioInfo)(JNIEnv *env, jobject thiz, jint channels,jint sampleRate, jint sampleBit)
#elif defined __IOS__
void rtmpSetAudioInfo(int channels, int sampleRate, int sampleBit)
#endif
{
	pthread_mutex_lock(&rtmp_jni_interface_lock);

	m_sAudioInfo.nChannels = channels;
	m_sAudioInfo.nSampleRate = sampleRate;
	m_sAudioInfo.nSampleBit = sampleBit;

	ALOGI("Func %s Line %d channels %d sampleRate %d sampleBit %d\n", __func__, __LINE__, channels, sampleRate, sampleBit);
	pthread_mutex_unlock(&rtmp_jni_interface_lock);
}

#ifdef __Android__
void PackageName(nativeSetVideoInfo)(JNIEnv *env, jobject thiz, jint width, jint height, jint fps)
#elif defined __IOS__
void rtmpSetVideoInfo(int width, int height, int fps)
#endif
{
	pthread_mutex_lock(&rtmp_jni_interface_lock);

	m_sVideoInfo.nWidth = width;
	m_sVideoInfo.nHeight = height;
	m_sVideoInfo.nFPS = fps;
	ALOGI("Func %s Line %d width %d height %d fps %d\n", __func__, __LINE__, width, height, fps);

	pthread_mutex_unlock(&rtmp_jni_interface_lock);
}

#ifdef __Android__
jint PackageName(nativeSend)(JNIEnv *env, jobject thiz, jbyteArray buf, jint type, jlong timestamp)
#elif defined __IOS__
int rtmpSend(uint8_t *pBuffer, int bufLen, int type, int64_t timestamp)
#endif
{
	pthread_mutex_lock(&rtmp_jni_interface_lock);

    if(0 == m_nConnected)
    {
        pthread_mutex_unlock(&rtmp_jni_interface_lock);
        return ERROR_DISCONNECT;
    }

	int nRC = 0;
	timestamp = timestamp / 1000;

#ifdef __Android__
	int bufLen  = 0;
	jbyte* pBuffer = 0;

	if (NULL != buf)
	{
		bufLen = (*env)->GetArrayLength(env, buf);
		pBuffer = (jbyte*)(*env)->GetByteArrayElements(env, buf, 0);
		if (NULL == pBuffer)
		{
			pthread_mutex_unlock(&rtmp_jni_interface_lock);
			return ERROR_MEMORY;
		}
	}
#endif // __Android__

#if defined _DEBUG_LOG && defined __Android__
//DumpData(pBuffer, bufLen, type, timestamp);
#endif
//ALOGI("Eoollo Func %s Line %d %s buffer %p size %d timestamp %lld\n", __func__, __LINE__, 0 == type ? "AUDIO" : "VIDEO", pBuffer, bufLen, timestamp);

	if(0 == type) // Audio AAC
	{ 
		nRC = SendAACPacket(pBuffer, 0, bufLen, timestamp);
	}
	else if(1 == type) // Video AVC
	{
		if(5 > bufLen)
		{
			ALOGE("Incomplete buffer, size %d\n", bufLen);
			nRC = ERROR_BUFFER;
            goto End;
		}

		int bKeyframe = 5 == (int)(pBuffer[4] & 0x1F) ? 0 : -1;
#ifdef __IOS__ // Ignore SEI packet
        if(6 != (int)(pBuffer[4] & 0x1F))
#endif // __IOS__
		nRC = SendH264Packet(pBuffer, bufLen, 4, bKeyframe, timestamp);
	}

End:

#ifdef __Android__
	if (NULL != buf && NULL != pBuffer)
		(*env)->ReleaseByteArrayElements(env, buf, pBuffer, 0);
#endif

	pthread_mutex_unlock(&rtmp_jni_interface_lock);

//ALOGI("Eoollo Func %s Line %d return %d\n", __func__, __LINE__, nRC);
	return nRC;
}

#ifdef __Android__
void JNI_OnUnload(JavaVM* vm, void* reserved)
{
	Disconnect();
}
#endif // __Android__

#if defined _DEBUG_LOG && defined __Android__
void DumpData(unsigned char * pBuffer, int size, int type, int64_t timestamp)
{
	static int audioCount = 0;
	static int videoCount = 0;
	char name[50];
	memset(name, 0, sizeof(name[50]));

	if(0 == type)
	{
		audioCount ++;
		sprintf(name, "/sdcard/Dump/%d_RTMP_Audio_%d_%lld.aac", audioCount, size, timestamp);
	}
	else if(1 == type)
	{
		videoCount ++;
		sprintf(name, "/sdcard/Dump/%d_RTMP_Video_%d_%lld.264", videoCount, size, timestamp);
	}

	FILE * fd = fopen(name, "w+");
	if(NULL != fd)
	{
		fwrite(pBuffer, size, 1, fd);
		fclose(fd);
		fd = NULL;
	}
	else
		ALOGE("Eoollo Cannot open %s : %s", name, strerror(errno));
}
#endif
