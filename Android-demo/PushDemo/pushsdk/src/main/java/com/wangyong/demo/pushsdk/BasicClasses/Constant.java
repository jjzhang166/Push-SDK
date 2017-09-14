package com.wangyong.demo.pushsdk.BasicClasses;

/**
 * Created by wangyong on 2017/6/30.
 */

public interface Constant {

    public static final int PCM = 0;
    public static final int AAC = 1;
    public static final int YUV = 2;
    public static final int AVC = 3;
    public static final int AVC_FORMAT = 4;

    public static final int CAMERA_THREAD_ID = 0;
    public static final int AUDIO_RECORDER_THREAD_ID = 1;
    public static final int AUDIO_ENCODER_THREAD_ID = 2;
    public static final int VIDEO_ENCODER_INPUT_THREAD_ID = 3;
    public static final int VIDEO_ENCODER_OUTPUT_THREAD_ID = 4;
    public static final int RTMP_SENDER_THREAD_ID = 5;
    public static final int INFO_COLLECT_THREAD_ID = 6;

    public static final int THREAD_RUN_STATUS_IDLE= 20;
    public static final int THREAD_RUN_STATUS_NORMAL = 21;
    public static final int THREAD_RUN_STATUS_DELAY = 22;

    /* PUSH SPEED bps */
    public static final int INFO_UPDATE_PUSH_SPEED = 50;
    public static final int INFO_UPDATE_PUSH_AUDIO_CAPTURE_FPS = 51;
    public static final int INFO_UPDATE_PUSH_AUDIO_ENCODED_FPS = 52;
    public static final int INFO_UPDATE_PUSH_AUDIO_FPS = 53;
    public static final int INFO_UPDATE_PUSH_VIDEO_FPS = 54;
    public static final int INFO_UPDATE_PUSH_VIDEO_CAPTURE_FPS = 55;
    public static final int INFO_UPDATE_PUSH_VIDEO_ENCODED_FPS = 56;
    public static final int INFO_UPDATE_PUSH_AUDIO_CAPTURE_BLOCK = 57;
    public static final int INFO_UPDATE_PUSH_AUDIO_ENCODER_BLOCK = 58;
    public static final int INFO_UPDATE_PUSH_VIDEO_CAPTURE_BLOCK = 59;
    public static final int INFO_UPDATE_PUSH_VIDEO_ENCODER_BLOCK = 60;
    public static final int INFO_UPDATE_RTMP_PUSH_RETURN = 61;

    public static final int AV_CODEC_ID_AAC = 86018;
    public static final int AV_CODEC_ID_H264 = 28;
}
