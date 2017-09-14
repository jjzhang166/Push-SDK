LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE    := libghttp
LOCAL_C_INCLUDES := $(LOCAL_PATH)
LOCAL_SRC_FILES :=		ghttp.c\
				http_base64.c \
				http_date.c \
		                http_hdrs.c \
				http_req.c \
				http_resp.c \
				http_trans.c \
				http_uri.c

LOCAL_LDLIBS := -llog
include $(BUILD_SHARED_LIBRARY)


