AUDIO_CODING_INCLUDES := \
				. \
				$(LOCAL_PATH)/../webrtc/modules/audio_coding/ \
				$(LOCAL_PATH)/../webrtc/modules/audio_coding/codecs/isac/main/source/ \
				$(LOCAL_PATH)/../webrtc/modules/audio_coding/codecs/isac/main/include/ \

AUDIO_CODING_SOURCE_PATH	:= ../webrtc/modules/audio_coding

AUDIO_CODING_FILES := \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/crc.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/lpc_gain_swb_tables.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/lpc_analysis.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/entropy_coding.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/decode.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/encode.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/lpc_shape_swb16_tables.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/filter_functions.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/fft.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/filterbank_tables.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/filterbanks.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/transform.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/isac.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/intialize.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/bandwidth_estimator.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/decode_bwe.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/arith_routines_logist.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/spectrum_ar_model_tables.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/arith_routines_hist.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/lpc_tables.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/lattice.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/arith_routines.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/pitch_estimator.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/pitch_lag_tables.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/encode_lpc_swb.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/pitch_filter.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/lpc_shape_swb12_tables.c \
				   $(AUDIO_CODING_SOURCE_PATH)/codecs/isac/main/source/pitch_gain_tables.c \
