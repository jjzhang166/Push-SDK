CONFIG := $(shell cat ../x264/config.h)  

X264_PATH := ../x264

SRCS = $(X264_PATH)/x264_interface.c \
	   $(X264_PATH)/common/mc.c \
	   $(X264_PATH)/common/predict.c \
	   $(X264_PATH)/common/pixel.c \
	   $(X264_PATH)/common/macroblock.c \
	   $(X264_PATH)/common/frame.c \
	   $(X264_PATH)/common/dct.c \
	   $(X264_PATH)/common/cpu.c \
	   $(X264_PATH)/common/cabac.c \
	   $(X264_PATH)/common/common.c \
	   $(X264_PATH)/common/osdep.c \
	   $(X264_PATH)/common/rectangle.c \
	   $(X264_PATH)/common/set.c \
	   $(X264_PATH)/common/quant.c \
	   $(X264_PATH)/common/deblock.c \
	   $(X264_PATH)/common/vlc.c \
	   $(X264_PATH)/common/mvpred.c \
	   $(X264_PATH)/common/bitstream.c \
	   $(X264_PATH)/common/arm/mc-c.c \
	   $(X264_PATH)/common/arm/predict-c.c \
	   $(X264_PATH)/encoder/analyse.c \
	   $(X264_PATH)/encoder/me.c \
	   $(X264_PATH)/encoder/ratecontrol.c \
	   $(X264_PATH)/encoder/set.c \
	   $(X264_PATH)/encoder/macroblock.c \
	   $(X264_PATH)/encoder/cabac.c \
	   $(X264_PATH)/encoder/cavlc.c \
	   $(X264_PATH)/encoder/encoder.c \
	   $(X264_PATH)/encoder/lookahead.c \

SRCCLI = $(X264_PATH)/x264.c \
		 $(X264_PATH)/input/input.c \
		 $(X264_PATH)/input/timecode.c \
		 $(X264_PATH)/input/raw.c \
		 $(X264_PATH)/input/y4m.c \
		 $(X264_PATH)/output/raw.c \
		 $(X264_PATH)/output/matroska.c \
		 $(X264_PATH)/output/matroska_ebml.c \
		 $(X264_PATH)/output/flv.c \
		 $(X264_PATH)/output/flv_bytestream.c \
		 $(X264_PATH)/filters/filters.c \
		 $(X264_PATH)/filters/video/video.c \
		 $(X264_PATH)/filters/video/source.c \
		 $(X264_PATH)/filters/video/internal.c \
		 $(X264_PATH)/filters/video/resize.c \
		 $(X264_PATH)/filters/video/cache.c \
		 $(X264_PATH)/filters/video/fix_vfr_pts.c \
		 $(X264_PATH)/filters/video/select_every.c \
		 $(X264_PATH)/filters/video/crop.c \
		 $(X264_PATH)/filters/video/depth.c \

# GPL-only files
ifneq ($(findstring HAVE_GPL 1, $(CONFIG)),)
SRCCLI +=
endif  

# Optional module sources  
ifneq ($(findstring HAVE_AVS 1, $(CONFIG)),)
SRCCLI += $(X264_PATH)/input/avs.c
endif

ifneq ($(findstring HAVE_THREAD 1, $(CONFIG)),)
SRCCLI += $(X264_PATH)/input/thread.c
SRCS   += $(X264_PATH)/common/threadpool.c
endif

ifneq ($(findstring HAVE_WIN32THREAD 1, $(CONFIG)),)
SRCS += $(X264_PATH)/common/win32thread.c
endif

ifneq ($(findstring HAVE_LAVF 1, $(CONFIG)),)
SRCCLI += $(X264_PATH)/input/lavf.c
endif

ifneq ($(findstring HAVE_FFMS 1, $(CONFIG)),)
SRCCLI += $(X264_PATH)/input/ffms.c
endif

ifneq ($(findstring HAVE_GPAC 1, $(CONFIG)),)
SRCCLI += $(X264_PATH)/output/mp4.c
endif

# Visualization sources  
ifneq ($(findstring HAVE_VISUALIZE 1, $(CONFIG)),)
SRCS   += $(X264_PATH)/common/visualize.c $(X264_PATH)/common/display-x11.c
endif

# NEON optims  

ASMSRC += $(X264_PATH)/common/arm/cpu-a.S \
		  $(X264_PATH)/common/arm/pixel-a.S \
		  $(X264_PATH)/common/arm/mc-a.S \
		  $(X264_PATH)/common/arm/dct-a.S \
		  $(X264_PATH)/common/arm/quant-a.S \
		  $(X264_PATH)/common/arm/deblock-a.S \
		  $(X264_PATH)/common/arm/predict-a.S \

## No need get option function
ifneq ($(HAVE_GETOPT_LONG),1)
#SRCCLI += $(X264_PATH)/extras/getopt.c
endif

LOCAL_SRC_FILES += $(SRCS) $(SRCCLI) $(ASMSRC)

LOCAL_C_INCLUDES +=  \
					 $(X264_PATH) \
					 $(X264_PATH)/input \
					 $(X264_PATH)/output \
					 $(X264_PATH)/encoder \
					 $(X264_PATH)/filters \
					 $(X264_PATH)/filters/video \
					 $(X264_PATH)/common \
					 $(X264_PATH)/common/arm \


LOCAL_PRELINK_MODULE := false
LOCAL_CFLAGS+= -std=c99
LOCAL_CFLAGS+= -lpthread -lm
LOCAL_DISABLE_FATAL_LINKER_WARNINGS := true
LOCAL_ARM_MODE:= arm
LOCAL_MODULE_TAGS := optional
