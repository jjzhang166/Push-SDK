LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
include OpenCV-android-sdk/sdk/native/jni/OpenCV.mk

LOCAL_CFLAGS += -D__Android__ -D_DEBUG_LOG

LOCAL_SRC_FILES  := faceDetection.cpp
LOCAL_C_INCLUDES += $(LOCAL_PATH)
LOCAL_LDLIBS     += -llog -ldl

LOCAL_MODULE     := faceDetection

include $(BUILD_SHARED_LIBRARY)
