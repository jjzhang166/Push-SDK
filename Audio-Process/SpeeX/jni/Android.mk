LOCAL_PATH := $(call my-dir)  

include $(CLEAR_VARS)  

LOCAL_MODULE    := libspeex_jni

LOCAL_CFLAGS = -DFIXED_POINT -DUSE_KISS_FFT -DEXPORT="" -UHAVE_CONFIG_H -Wno-literal-conversion -D__Android__

LOCAL_C_INCLUDES := $(LOCAL_PATH)/include

LOCAL_C_INCLUDES +=	$(LOCAL_PATH)/../speexdsp-1.2rc3/include \
					$(LOCAL_PATH)/../speex-1.2.0/include \

LOCAL_LDLIBS  := -llog -lz

SPEEX_SRC_FILES :=  \
				   ../speex-1.2.0/libspeex/bits.c \
				   ../speex-1.2.0/libspeex/gain_table_lbr.c \
				   ../speex-1.2.0/libspeex/modes.c \
				   ../speex-1.2.0/libspeex/cb_search.c  \
				   ../speex-1.2.0/libspeex/hexc_10_32_table.c \
				   ../speex-1.2.0/libspeex/modes_wb.c \
				   ../speex-1.2.0/libspeex/exc_10_16_table.c \
				   ../speex-1.2.0/libspeex/hexc_table.c \
				   ../speex-1.2.0/libspeex/nb_celp.c \
				   ../speex-1.2.0/libspeex/exc_10_32_table.c \
				   ../speex-1.2.0/libspeex/high_lsp_tables.c \
				   ../speex-1.2.0/libspeex/quant_lsp.c \
				   ../speex-1.2.0/libspeex/vbr.c \
				   ../speex-1.2.0/libspeex/exc_20_32_table.c \
				   ../speex-1.2.0/libspeex/kiss_fft.c \
				   ../speex-1.2.0/libspeex/sb_celp.c \
				   ../speex-1.2.0/libspeex/vorbis_psy.c \
				   ../speex-1.2.0/libspeex/exc_5_256_table.c \
				   ../speex-1.2.0/libspeex/kiss_fftr.c \
				   ../speex-1.2.0/libspeex/smallft.c \
				   ../speex-1.2.0/libspeex/vq.c \
				   ../speex-1.2.0/libspeex/exc_5_64_table.c \
				   ../speex-1.2.0/libspeex/lpc.c \
				   ../speex-1.2.0/libspeex/speex.c \
				   ../speex-1.2.0/libspeex/window.c \
				   ../speex-1.2.0/libspeex/exc_8_128_table.c \
				   ../speex-1.2.0/libspeex/lsp.c \
				   ../speex-1.2.0/libspeex/speex_callbacks.c \
				   ../speex-1.2.0/libspeex/filters.c \
				   ../speex-1.2.0/libspeex/lsp_tables_nb.c \
				   ../speex-1.2.0/libspeex/speex_header.c \
				   ../speex-1.2.0/libspeex/gain_table.c \
				   ../speex-1.2.0/libspeex/ltp.c \
				   ../speex-1.2.0/libspeex/stereo.c \


SPEEXDSP_SRC_FILES :=  \
				   ../speexdsp-1.2rc3/libspeexdsp/buffer.c \
			   	   ../speexdsp-1.2rc3/libspeexdsp/resample.c \
				   ../speexdsp-1.2rc3/libspeexdsp/fftwrap.c \
				   ../speexdsp-1.2rc3/libspeexdsp/scal.c \
				   ../speexdsp-1.2rc3/libspeexdsp/filterbank.c \
				   ../speexdsp-1.2rc3/libspeexdsp/mdf.c \
				   ../speexdsp-1.2rc3/libspeexdsp/jitter.c \
				   ../speexdsp-1.2rc3/libspeexdsp/preprocess.c \

TEST_SRC_FILES	   := \
				   ../speex-1.2.0/libspeex/testenc.c \
				   ../speex-1.2.0/libspeex/testenc_uwb.c \
				   ../speex-1.2.0/libspeex/testenc_wb.c \
				   ../speexdsp-1.2rc3/libspeexdsp/testecho.c \
			  	   ../speexdsp-1.2rc3/libspeexdsp/testresample.c \
		   		   ../speexdsp-1.2rc3/libspeexdsp/testjitter.c \
				   ../speexdsp-1.2rc3/libspeexdsp/testdenoise.c \

DUPLICATE_FILES    := \
		  		   ../speexdsp-1.2rc3/libspeexdsp/smallft.c \
			 	   ../speexdsp-1.2rc3/libspeexdsp/kiss_fft.c \
			  	   ../speexdsp-1.2rc3/libspeexdsp/kiss_fftr.c \

LOCAL_SRC_FILES := ../speex_jni.c \
				   $(SPEEX_SRC_FILES) \
				   $(SPEEXDSP_SRC_FILES) \

include $(BUILD_SHARED_LIBRARY) 
