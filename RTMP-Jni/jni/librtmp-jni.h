#ifdef __Android__
#include "rtmpdump-master/librtmp/rtmp.h"
#elif defined __IOS__
#include "../rtmpdump-ios/librtmp/rtmp.h"
#endif

#include <stdio.h>
#include <pthread.h>
#include "timer.h"

#define BUFFER_SIZE (1024 * 1024 * 10)       //  10M
#define NUM_UNITS_IN_TICK 1001

#ifdef _DEBUG_LOG

#ifdef __Android__
#define PackageName(a) Java_com_wangyong_demo_pushsdk_RTMPSender_##a
#define ALOGD(...)  __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define ALOGI(...)  __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define ALOGE(...)  __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#elif defined __IOS__
#define ALOGD(...) printf(__VA_ARGS__);
#define ALOGI(...) printf(__VA_ARGS__);
#define ALOGE(...) printf(__VA_ARGS__);
#endif // __Android__

#else
#define ALOGD(...)
#define ALOGI(...)
#define ALOGE(...)
#endif

// NALU单元
typedef struct _NaluUnit  
{  
	int type;  
	int size;  
	unsigned char *data;  
}NaluUnit;

typedef struct _RTMPMetadata
{
	// video, must be h264 type
	unsigned int    nWidth;
	unsigned int    nHeight;
	unsigned int    nFrameRate;     // fps
	unsigned int    nVideoDataRate; // bps
	unsigned int    nSpsLen;
	unsigned char   Sps[1024];
	unsigned int    nPpsLen;
	unsigned char   Pps[1024];

	// audio, must be aac type
	//bool            bHasAudio;
	int             bHasAudio;
	unsigned int    nAudioSampleRate;
	unsigned int    nAudioSampleSize;
	unsigned int    nAudioChannels;
	char            pAudioSpecCfg;
	unsigned int    nAudioSpecCfgLen;

} RTMPMetadata,*LPRTMPMetadata;

typedef struct BufferStruct
{
	unsigned int	nSize;
	int64_t			nTimestamp;
	unsigned char	pBuffer[BUFFER_SIZE];
	int				nHeaderSize;
}BufferStruct;

typedef struct AudioInfo
{
	int nCodecID;
	int nChannels;
	int nSampleRate;
	int nSampleBit;
}AudioInfo;

typedef struct VideoInfo
{
	int nCodecID;
	int nWidth;
	int nHeight;
	int nFPS;
	int bMultiSlices;
}VideoInfo;

BufferStruct m_sVideoBuffer;
BufferStruct m_sAudioBuffer;
RTMPMetadata m_sMetadata;
AudioInfo	 m_sAudioInfo;
VideoInfo	 m_sVideoInfo;
int			 m_bAudioMetadataSend;
int			 m_bVideoMetadataSend;
int			 m_bStreamMetadataSend;
int64_t 	 m_nAudioTimestamp;
int64_t 	 m_nVideoTimestamp;
int64_t 	 m_nSysTimestamp;
int			 m_nSendAudioCount;
int			 m_nSendVideoCount;
RTMP* m_pRtmp;
int64_t      m_nAbsSysTimeDiff;
int          m_nConnected;

int64_t     m_nLastAudioTimestamp;
int64_t     m_nLastVideoTimestamp;

pthread_mutex_t rtmp_jni_interface_lock;

// 连接到RTMP Server
int Connect(const char* url);
// 断开连接
void Disconnect();
// 发送Audio MetaData
int SendAudioMetadata(void);
// 发送Video MetaData
int SendVideoMetadata(LPRTMPMetadata lpMetaData);
// 发送AAC数据帧
int SendAACPacket(unsigned char *data, int headerSize, unsigned int size, int64_t nTimeStamp);
// 发送H264数据帧
int SendH264Packet(unsigned char *data,unsigned int size, int headerSize, int bIsKeyFrame, int64_t nTimeStamp);
// 发送H264文件
int SendH264File(const char *pFileName);
// 送缓存中读取一个NALU包
int ReadOneNaluFromBuf(NaluUnit* nalu);
// 发送数据
int SendPacket(unsigned int nPacketType,unsigned char *data,unsigned int size, int64_t nTimestamp);
// Dump数据
void DumpData(unsigned char* pBuffer, int size, int type, int64_t timestamp);
