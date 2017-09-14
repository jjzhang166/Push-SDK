LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

include jni/common.mk
include jni/audio_coding.mk
include jni/audio_processing.mk

LOCAL_ARM_NEON  := true
LOCAL_MODULE    := webrtc_audio_processing

LOCAL_LDLIBS	:= -lm -llog

JNI_FLAGS		:= \
				   -D__Android__ \
				   -Wno-int-conversion \
				   
LOCAL_CFLAGS	:= \
				   $(JNI_FLAGS) \
				   -DWEBRTC_NS_FLOAT \
				   -DWEBRTC_ANDROID \
				   -DWEBRTC_LINUX \
				   -Wno-asm-operand-widths \
				   -Wno-implicit-function-declaration \
				   -DWEBRTC_POSIX \
				   -DDCHECK_ALWAYS_ON=1 \
				   -DWEBRTC_APM_DEBUG_DUMP=0 \
				   -DWEBRTC_INTELLIGIBILITY_ENHANCER=1 \

LOCAL_CXXFLAGS	:= \
				   -std=c++11 \
				   -stdlib=libc++ \
				   -stdlib=libstdc++ \
				   -frtti -fexceptions \

LOCAL_CPPFLAGS	:= \

LOCAL_C_INCLUDES:= \
				   . \
				   $(AUDIO_CODING_INCLUDES) \
				   $(SIGNAL_PROCESSING_INCLUDES) \
				   $(AUDIO_PROCESSING_INCLUDES) \

LOCAL_SRC_FILES := \
				   $(AUDIO_CODING_FILES) \
				   $(COMMON_SOURCE_FILES) \
				   $(AUDIO_PROCESSING_SOURCE_FILES) \
				   ../WebRTCAudioProcessing_jni.cc \
				
include $(BUILD_SHARED_LIBRARY)
