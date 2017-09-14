package com.wangyong.demo.pushsdk;

/**
 * Created by wangyong on 2017/8/5.
 */

public class SpeexProcessor {

    private final String TAG = "SpeexProcessor";

    private long process = -1;

    static{
        System.loadLibrary("speex_jni");
    }

    public SpeexProcessor(){};

    public int open(int frameSize, int frameRate, int echoCancellation) {
        this.process = nativeOpen(frameSize, frameRate, echoCancellation);

        return 0;
    }

    public int close() {

        if (0 < process)
            return nativeClose(process);

        return -1;
    }

    public int setDenoiseParameter(int denoise, int noiseSuppress) {

        if (0 < process)
            return nativeSetDenoiseParameter(process, denoise, noiseSuppress);

        return -1;
    }

    public int setAGCParameter(int agc, int level) {

        if (0 < process)
            return nativeSetAGCParameter(process, agc, level);

        return -1;
    }

    public int setVADParameter(int vad, int vadProbStart, int vadProbContinue) {

        if (0 < process)
            return nativeSetVADParameter(process, vad, vadProbStart, vadProbContinue);

        return -1;
    }

    public int process ( byte[] data, int size, byte[] output) {

        if (0 < process)
            return nativeProcess(process, data, size, output);

        return -1;
    }

    private native long nativeOpen(int frameSize, int frameRate, int echoCancellation);
    private native int nativeClose(long process);
    private native int nativeSetDenoiseParameter(long process, int denoise, int noiseSuppress);
    private native int nativeSetAGCParameter(long process, int agc, int level);
    private native int nativeSetVADParameter(long process, int vad, int vadProbStart, int vadProbContinue);
    private native int nativeProcess(long process, byte[] jdata, int size, byte[] joutput);
}
