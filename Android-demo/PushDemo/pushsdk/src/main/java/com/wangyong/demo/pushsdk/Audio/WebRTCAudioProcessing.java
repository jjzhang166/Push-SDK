package com.wangyong.demo.pushsdk.Audio;

/**
 * Created by wangyong on 2017/8/10.
 */

public class WebRTCAudioProcessing {
    private final String TAG = "WebRTCAudioProcessing";

    private long handler = 0;


    static{
        System.loadLibrary("webrtc_audio_processing");
        System.loadLibrary("c++_shared");
    }

    public int open(int enableNS, int enableAEC, int aecDelay, int enableAGC, int enableVAD) {
        handler = nativeOpen(enableNS, enableAEC, aecDelay, enableAGC, enableVAD);

        if (0 >= handler)
            return -1;

        return 0;
    }

    public void close() {
        if (0 < handler)
            nativeClose(handler);

        return;
    }

    public int setParameters(int frameSize, int sampleRate, int sampleBit, int channels) {
        if (0 < handler)
            return nativeSetParameters(handler, frameSize, sampleRate, sampleBit, channels);

        return -1;
    }

    public int process(byte[] data) {
        if (0 < handler)
            return nativeProcess(handler, data);

        return -1;
    }

    private native long nativeOpen(int enableNS, int enableAEC, int aecDelay, int enableAGC, int enableVAD);
    private native void nativeClose(long handler);
    private native int nativeSetParameters(long handler, int frameSize, int sampleRate, int sampleBit, int channels);
    private native int nativeProcess(long handler, byte[] data);
}
