LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
#include ../x264/android_x264.mk

LOCAL_SRC_FILES += \
			librtmp-jni.c \
			libghttp-jni.c \
			FileMuxer.c \
			cjson.c \
			Convert/convert.c \

LOCAL_CPPFLAGS += -Wno-format-extra-args -DHAVE_PTHREADS -Wno-multichar
LOCAL_CFLAGS += -D_TEST_LOCAL_FILE -D__Android__ -D_DEBUG_LOG -Wno-backslash-newline-escape -Wno-pointer-sign -Wno-format

THIRDPART:=$(LOCAL_PATH)/../thirdPart/Android/armeabi-v7a
#THIRDPART:=$(LOCAL_PATH)/../thirdPart/Android/arm64-v8a

LOCAL_C_INCLUDES += $(LOCAL_PATH) \
					$(LOCAL_PATH)/../ \
					$(LOCAL_PATH)/../ffmpeg/ffmpeg-2.8.2/ \
					$(LOCAL_PATH)/../ffmpeg/scratch/arm64/ \
					$(LOCAL_PATH)/../libghttp/jni \
					$(LOCAL_PATH)/Convert \


LOCAL_LDLIBS  := -llog -lz $(THIRDPART)/librtmp.so $(THIRDPART)/libghttp.so \
				 $(THIRDPART)/libavformat.a \
				 $(THIRDPART)/libavcodec.a \
				 $(THIRDPART)/libswscale.a \
				 $(THIRDPART)/libavutil.a \
				 $(THIRDPART)/libswresample.a \
				 $(THIRDPART)/libavfilter.a \
				 $(THIRDPART)/libfreetype.a \
				 $(THIRDPART)/libx264.a \
				 $(THIRDPART)/libfdk-aac.a \

LOCAL_PRELINK_MODULE := false

LOCAL_MODULE:= librtmp-jni
LOCAL_MODULE_TAGS := eng
include $(BUILD_SHARED_LIBRARY)
