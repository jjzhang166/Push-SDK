#ifndef __X264_INTERFACE_H__
#define __X264_INTERFACE_H__

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h> // for uint8_t in x264.h
#include <pthread.h>

#include "x264.h"

#define CHECK_CONDITIONS if(NULL == pInterface) return ERROR_POINTER; if(ERROR_NONE > pInterface->mError) return pInterface->mError;

typedef enum {
	ERROR_CODEC = -5,
	ERROR_MEMORY = -4,
	ERROR_POINTER = -3,
	ERROR_PARAMETER = -2,
	ERROR_UNKNOWN = -1,
	ERROR_NONE = 0,
}ERROR_TYPE;

typedef struct X264Interface{
	x264_t			*pHandle;
	x264_param_t 	m_sParam;
	x264_picture_t 	*pInputPic;

	int				mInputColorType;
	int				mHoldFrames;
	int				mError;
}X264Interface;

pthread_mutex_t interface_lock;
X264Interface *pInterface;

#endif // __X264_INTERFACE_H__
