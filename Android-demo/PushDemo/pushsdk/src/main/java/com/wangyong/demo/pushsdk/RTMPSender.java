package com.wangyong.demo.pushsdk;

import com.wangyong.demo.pushsdk.BasicClasses.Loging;

/**
 * Created by wangyong on 2017/7/3.
 */

public class RTMPSender {

    private final String TAG = "RTMPSender";

    static{
        System.loadLibrary("ghttp");
        System.loadLibrary("rtmp");
        System.loadLibrary("rtmp-jni");
    }

    public static final int NO_ERROR = 0; // 正常
    public static final int ERROR_BUFFER = -1;		// APP层发送的buffer错误，长度小于 5
    public static final int ERROR_MEMORY = -2; 	// RTMP 申请不到内存
    public static final int ERROR_NETWORK = -3;	// 网络错误
    public static final int ERROR_HEADER = -4;		// RTMP包头错误
    public static final int ERROR_METADATA = -5;	// Medadata 没有发送

    public int RTMPConnect(String svrUrl, int absoluteTimeMs){

        int ret = nativeConnect(svrUrl);

        if(ret != NO_ERROR) {
            return ret;
        }

        ret = nativeSetAbsoluteTimeMs(absoluteTimeMs);

        if(ret != NO_ERROR){
            nativeDisconnect();
            return ret;
        }

        return ret;
    }
    public void RTMPDisconnect(){

        nativeDisconnect();
    }



    public int RTMPSendData(int type, byte[] buf, long timestamp){
        int ret = nativeSend(buf, type, timestamp);
        return ret;
    }

    public void setAudioInfo(int channels, int sampleRate, int sampleBit){
        nativeSetAudioInfo(channels, sampleRate, sampleBit);
    }

    public void setVideoInfo(int width, int height, int fps){
        nativeSetVideoInfo(width, height, fps);
    }

    private native int nativeSetAudioInfo(int channels, int sampleRate, int sampleBit);
    private native int nativeSetVideoInfo(int width, int height, int fps);
    private native int nativeConnect(String url);
    private native int nativeSetAbsoluteTimeMs(int time);
    private native int nativeDisconnect();
    /** type: 0 audio 1 video */
    private native int nativeSend(byte[] buf, int type, long timestamp);

    // 1 ： enable, 0 : disbale

    private native int nativeNeedDropThisFrame(int type);
    private native long nativeGetSendDataLen();
}
