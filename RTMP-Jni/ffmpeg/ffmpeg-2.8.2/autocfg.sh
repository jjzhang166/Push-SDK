# !/bin/sh
_target=no
test "$1" && _target="$1"
#--disable-everything \
#  --enable-demuxer=rawvideo \
#  --enable-demuxer=pcm_s16le \
#  --enable-demuxer=pcm_u16le \
 # --enable-demuxer=pcm_f32le \
 # --enable-demuxer=pcm_u8 \
 # --enable-decoder=rawvideo \
 # --enable-decoder=pcm_s16le \
 # --enable-decoder=pcm_u16le \
 # --enable-decoder=pcm_f32le \
 # --enable-decoder=pcm_u8 \
 # --enable-encoder=libx264 \
 # --enable-encoder=libfdk_aac \
 #--disable-optimizations \
 #--enable-libfreetype \
 #--extra-libs=-lfribidi \
 
 _config_simple="configure \
  --enable-gpl \
  --enable-nonfree \
  --enable-version3 \
  --enable-shared \
  --enable-pthreads \
  --enable-memalign-hack \
  --enable-libx264 --enable-libfdk-aac \
  --enable-libfreetype --enable-libfontconfig \
  --enable-runtime-cpudetect \
  --disable-devices \
  --enable-indev=dshow \
  --disable-doc \
  --disable-static \
  --disable-ffserver \
  --disable-w32threads \
  --extra-cflags=-U__STRICT_ANSI__ \
  --extra-cflags=-I/mingw/include \
  --extra-libs="-Wl,--enable-auto-import" \
  --extra-libs=-lexpat --extra-libs=-lfreetype\
  --prefix=/usr/local/ffmpeg_simple"
  
_config_sdebug="configure \
  --enable-debug \
  --enable-gpl \
  --enable-nonfree \
  --enable-version3 \
  --enable-shared \
  --disable-pthreads \
  --enable-memalign-hack \
  --enable-libx264 --enable-libfdk-aac \
  --enable-runtime-cpudetect \
  --disable-devices \
  --enable-indev=dshow \
  --disable-doc \
  --disable-static \
  --disable-ffserver \
  --disable-w32threads \
  --toolchain=msvc \
  --build-suffix=_d \
  --prefix=/usr/local/ffmpeg_simple_d"
  
  
_config_debug="configure \
  --enable-debug \
  --disable-optimizations \
  --enable-gpl \
  --enable-nonfree \
  --enable-version3 \
  --enable-static \
  --enable-pthreads \
  --enable-memalign-hack \
  --enable-libopencore-amrnb --enable-libopencore-amrwb \
  --enable-libx264 --enable-libfdk-aac \
  --enable-runtime-cpudetect \
  --enable-libass \
  --enable-libfreetype \
  --disable-devices \
  --enable-indev=dshow \
  --disable-doc \
  --disable-shared \
  --disable-ffserver \
  --disable-w32threads \
  --extra-cflags=-U__STRICT_ANSI__ \
  --extra-cflags=-I/mingw/include \
  --extra-libs="-Wl,--enable-auto-import" \
  --extra-libs=-L/mingw/lib \
  --extra-libs=-lenca \
  --extra-libs=-liconv \
  --extra-libs=-lexpat \
  --extra-libs=-lfribidi \
  --prefix=/usr/local/ffmpeg_transcli"
  
_config_transcli="configure \
  --enable-gpl \
  --enable-nonfree \
  --enable-version3 \
  --enable-shared \
  --enable-pthreads \
  --enable-memalign-hack \
  --enable-libopencore-amrnb --enable-libopencore-amrwb \
  --enable-libx264 --enable-libfdk-aac \
  --enable-runtime-cpudetect \
  --enable-libass \
  --enable-libfreetype \
  --disable-devices \
  --enable-indev=dshow \
  --disable-doc \
  --disable-static \
  --disable-ffserver \
  --disable-w32threads \
  --extra-cflags=-U__STRICT_ANSI__ \
  --extra-cflags=-I/mingw/include \
  --extra-libs="-Wl,--enable-auto-import" \
  --extra-libs=-L/mingw/lib \
  --extra-libs=-lenca \
  --extra-libs=-liconv \
  --extra-libs=-lexpat \
  --extra-libs=-lfribidi \
  --extra-libs=-ldbghelp \
  --prefix=/usr/local/ffmpeg_transcli"
#--disable-stripping \

#--disable-protocols \
#
_config_show="configure \
  --enable-gpl \
  --enable-nonfree \
  --enable-version3 \
  --enable-shared \
  --enable-pthreads \
  --enable-memalign-hack \
  --enable-runtime-cpudetect \
  --enable-librtmp \
  --enable-libx264 \
  --enable-libfdk-aac \
  --disable-muxers \
  --disable-bsfs \
  --disable-parsers \
  --disable-demuxers \
  --disable-devices \
  --enable-muxer=flv \
  --enable-muxer=mp4 \
  --enable-muxer=rawvideo \
  --enable-indev=dshow \
  --disable-protocols \
  --enable-protocol=librtmp \
  --enable-protocol=librtmps \
  --enable-protocol=librtmpe \
  --enable-protocol=http \
  --enable-protocol=file \
  --enable-protocol=pipe \
  --enable-protocol=md5 \
  --disable-encoders \
  --enable-encoder=rawvideo \
  --enable-encoder=libx264 \
  --enable-encoder=libfdk_aac \
  --disable-decoders \
  --enable-decoder=rawvideo \
  --enable-decoder=pcm_s16le \
  --enable-decoder=pcm_u16le \
  --enable-decoder=pcm_f32le \
  --enable-decoder=pcm_u8 \
  --disable-filter=ass --disable-filter=bbox \
  --disable-filter=blackdetect --disable-filter=blackframe \
  --disable-filter=blend --disable-filter=boxblur \
  --disable-filter=cropdetect --disable-filter=curves \
  --disable-filter=delogo --disable-filter=deshake \
  --disable-filter=haldclut --disable-filter=hflip \
  --disable-filter=histeq --disable-filter=histogram \
  --disable-filter=hqdn3d --disable-filter=mp \
  --disable-filter=noise --disable-filter=mpdecimate \
  --disable-filter=overlay --disable-filter=pad \
  --disable-filter=owdenoise --disable-filter=pp \
  --disable-filter=removelogo --disable-filter=rotate \
  --disable-postproc \
  --disable-doc \
  --disable-static \
  --disable-ffserver \
  --disable-ffprobe \
  --enable-ffmpeg \
  --disable-w32threads \
  --disable-optimizations \
  --extra-cflags=-U__STRICT_ANSI__ \
  --extra-cflags=-I/mingw/include \
  --extra-libs=-L/mingw/lib \
  --prefix=/usr/local/ffmpeg_show"

 
_config_lite="configure \
  --disable-ffmpeg \
  --disable-static \
  --disable-devices \
  --disable-avdevice \
  --disable-ffserver \
  --disable-muxers \
  --disable-encoders \
  --disable-filters \
  --disable-avfilter \
  --disable-swresample \
  --disable-swscale \
  --disable-postproc \
  --disable-bsfs \
  --disable-indevs \
  --disable-outdevs \
  --disable-debug \
  --enable-shared \
  --enable-muxer=rawvideo \
  --enable-muxer=wav \
  --enable-pthreads \
  --disable-w32threads \
  --extra-cflags=-U__STRICT_ANSI__ \
  --extra-cflags=-I/mingw/include \
  --prefix=/usr/local/ffmpeg_lite"

_config=$_config_transcli
if test $_target = lite; then
	_config=$_config_lite
elif test $_target = show; then
    _config=$_config_show 
elif test $_target = debug; then
    _config=$_config_debug
elif test $_target = simple; then
	_config=$_config_simple
elif test $_target = sdebug; then
	_config=$_config_sdebug
fi
./$_config
