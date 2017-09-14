
BASE_PATH	:= ../webrtc/base
BASE_INCLUDES	:= ../webrtc/base
BASE_SOURCE_FILES	:= \
					   $(BASE_PATH)/logging.cc \
					   $(BASE_PATH)/timeutils.cc \
					   $(BASE_PATH)/stringencode.cc \
					   $(BASE_PATH)/checks.cc \
					   $(BASE_PATH)/criticalsection.cc \
					   $(BASE_PATH)/platform_thread.cc \
					   $(BASE_PATH)/event.cc \
					   $(BASE_PATH)/event_tracer.cc \
					   $(BASE_PATH)/platform_file.cc \
					   $(BASE_PATH)/thread_checker_impl.cc \
					   $(BASE_PATH)/../system_wrappers/source/metrics_default.cc \
					   $(BASE_PATH)/../system_wrappers/source/trace_impl.cc \
					   $(BASE_PATH)/../system_wrappers/source/trace_posix.cc \
					   $(BASE_PATH)/../system_wrappers/source/file_impl.cc \
					   $(BASE_PATH)/../system_wrappers/source/logging.cc \
					   $(BASE_PATH)/../system_wrappers/source/aligned_malloc.cc \


SIGNAL_PROCESSING_PATH		:= ../webrtc/common_audio/signal_processing
SIGNAL_PROCESSING_INCLUDES	:= \
							   $(LOCAL_PATH)/../webrtc/common_audio/signal_processing \
							   $(LOCAL_PATH)/../webrtc/common_audio/signal_processing/include \

SIGNAL_PROCESSING_FILES		:= \
							   $(SIGNAL_PROCESSING_PATH)/auto_corr_to_refl_coef.c \
							   $(SIGNAL_PROCESSING_PATH)/refl_coef_to_lpc.c \
							   $(SIGNAL_PROCESSING_PATH)/resample_fractional.c \
							   $(SIGNAL_PROCESSING_PATH)/resample_by_2_internal.c \
							   $(SIGNAL_PROCESSING_PATH)/resample_48khz.c \
							   $(SIGNAL_PROCESSING_PATH)/randomization_functions.c \
							   $(SIGNAL_PROCESSING_PATH)/min_max_operations_neon.c \
							   $(SIGNAL_PROCESSING_PATH)/downsample_fast_neon.c \
							   $(SIGNAL_PROCESSING_PATH)/cross_correlation_neon.c \
							   $(SIGNAL_PROCESSING_PATH)/division_operations.c \
							   $(SIGNAL_PROCESSING_PATH)/min_max_operations.c \
							   $(SIGNAL_PROCESSING_PATH)/spl_sqrt_floor.c \
							   $(SIGNAL_PROCESSING_PATH)/get_scaling_square.c \
							   $(SIGNAL_PROCESSING_PATH)/energy.c \
							   $(SIGNAL_PROCESSING_PATH)/vector_scaling_operations.c \
							   $(SIGNAL_PROCESSING_PATH)/downsample_fast.c \
							   $(SIGNAL_PROCESSING_PATH)/copy_set_operations.c \
							   $(SIGNAL_PROCESSING_PATH)/cross_correlation.c \
							   $(SIGNAL_PROCESSING_PATH)/spl_init.c \
							   $(SIGNAL_PROCESSING_PATH)/complex_fft.c \
							   $(SIGNAL_PROCESSING_PATH)/complex_bit_reverse.c \
							   $(SIGNAL_PROCESSING_PATH)/real_fft.c \
							   $(SIGNAL_PROCESSING_PATH)/splitting_filter.c \
							   $(SIGNAL_PROCESSING_PATH)/resample.c \
							   $(SIGNAL_PROCESSING_PATH)/resample_by_2.c \
							   $(SIGNAL_PROCESSING_PATH)/dot_product_with_scale.c \
							   $(SIGNAL_PROCESSING_PATH)/spl_sqrt.c \
							   $(SIGNAL_PROCESSING_PATH)/../resampler/resampler.cc \

AUDIO_PROCESSING_UTILITY_OTHER_FILES	:= \
								   $(AUDIO_PROCESSING_UTILITY_PATH)/block_mean_calculator_unittest.cc \
								   $(AUDIO_PROCESSING_UTILITY_PATH)/delay_estimator_unittest.cc \
								   $(AUDIO_PROCESSING_UTILITY_PATH)/ooura_fft_mips.cc \
								   $(AUDIO_PROCESSING_UTILITY_PATH)/ooura_fft_sse2.cc \

COMMON_PATH	:= ../webrtc
COMMON_AUDIO_PATH	:= ../webrtc/common_audio
COMMON_INCLUDES	:= \
				   $(BASE_INCLUDES) \
				   $(SIGNAL_PROCESSING_INCLUDES) \
				   ../webrtc \
				   ../webrtc/common_audio \
				   ../webrtc/common_video \

COMMON_SOURCE_FILES	:= \
					   $(BASE_SOURCE_FILES) \
					   $(SIGNAL_PROCESSING_FILES) \
					   $(COMMON_AUDIO_PATH)/vad/vad_sp.c \
					   $(COMMON_AUDIO_PATH)/vad/vad_gmm.c \
					   $(COMMON_AUDIO_PATH)/vad/vad_filterbank.c \
					   $(COMMON_AUDIO_PATH)/vad/vad_core.c \
					   $(COMMON_AUDIO_PATH)/vad/webrtc_vad.c \
					   $(COMMON_AUDIO_PATH)/fft4g.c \
					   $(COMMON_AUDIO_PATH)/audio_util.cc \
					   $(COMMON_AUDIO_PATH)/wav_header.cc \
					   $(COMMON_AUDIO_PATH)/wav_file.cc \
					   $(COMMON_AUDIO_PATH)/ring_buffer.c \
					   $(COMMON_AUDIO_PATH)/audio_converter.cc \
					   $(COMMON_AUDIO_PATH)/resampler/push_sinc_resampler.cc \
					   $(COMMON_AUDIO_PATH)/resampler/sinc_resampler.cc \
					   $(COMMON_AUDIO_PATH)/channel_buffer.cc \
					   $(COMMON_AUDIO_PATH)/lapped_transform.cc \
					   $(COMMON_AUDIO_PATH)/real_fourier.cc \
					   $(COMMON_AUDIO_PATH)/blocker.cc \
					   $(COMMON_AUDIO_PATH)/window_generator.cc \
					   $(COMMON_AUDIO_PATH)/real_fourier_ooura.cc \
					   $(COMMON_AUDIO_PATH)/audio_ring_buffer.cc \
					   $(COMMON_AUDIO_PATH)/sparse_fir_filter.cc \
					   $(COMMON_AUDIO_PATH)/fir_filter.cc \
