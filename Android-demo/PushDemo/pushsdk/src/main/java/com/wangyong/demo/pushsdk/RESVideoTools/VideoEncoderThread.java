package com.wangyong.demo.pushsdk.RESVideoTools;

import android.media.MediaCodec;
import android.media.MediaFormat;

import com.wangyong.demo.pushsdk.BasicClasses.CallbackInterfaces;
import com.wangyong.demo.pushsdk.BasicClasses.Constant;
import com.wangyong.demo.pushsdk.BasicClasses.Loging;

import java.nio.ByteBuffer;

/**
 * Created by wangyong on 26/05/16.
 */

public class VideoEncoderThread extends Thread {
    private static final String TAG = "VideoEncoderThread";

    private static final long WAIT_TIME = 5000;
    private MediaCodec.BufferInfo eInfo;
    private long startTime = 0;
    private MediaCodec dstVideoEncoder;
    private final Object syncDstVideoEncoder = new Object();

    private CallbackInterfaces.CapturedDataCallback capturedDataCallback;
    private long startEncodeTimestamp = -1;

    VideoEncoderThread(String name, MediaCodec encoder, CallbackInterfaces.CapturedDataCallback capturedDataCallback) {
        super(name);
        eInfo = new MediaCodec.BufferInfo();
        startTime = 0;
        dstVideoEncoder = encoder;
        this.capturedDataCallback = capturedDataCallback;
        startEncodeTimestamp = -1;
    }

    public void updateMediaCodec(MediaCodec encoder) {
        synchronized (syncDstVideoEncoder) {
            dstVideoEncoder = encoder;
        }
    }

    private boolean shouldQuit = false;

    void quit() {
        shouldQuit = true;
        this.interrupt();
    }

    @Override
    public void run() {
        while (!shouldQuit) {
            synchronized (syncDstVideoEncoder) {
                int eobIndex = MediaCodec.INFO_TRY_AGAIN_LATER;
                try {
                    eobIndex = dstVideoEncoder.dequeueOutputBuffer(eInfo, WAIT_TIME);
                } catch (Exception ignored) {
                }
                switch (eobIndex) {
                    case MediaCodec.INFO_OUTPUT_BUFFERS_CHANGED:
                        Loging.Log(TAG, "MediaCodec.INFO_OUTPUT_BUFFERS_CHANGED");
                        break;
                    case MediaCodec.INFO_TRY_AGAIN_LATER:
                        break;
                    case MediaCodec.INFO_OUTPUT_FORMAT_CHANGED:
                        Loging.Log(TAG, "MediaCodec.INFO_OUTPUT_FORMAT_CHANGED:" + dstVideoEncoder.getOutputFormat().toString());
                        MediaFormat newFormat = dstVideoEncoder.getOutputFormat();
                        if (null != capturedDataCallback) {
                            capturedDataCallback.onCapturedDataUpdate(Constant.AVC_FORMAT, 0, newFormat, 0, eInfo);
                        }
                        break;
                    default:
                        if (startTime == 0) {
                            startTime = eInfo.presentationTimeUs / 1000;
                        }

                        ByteBuffer encodedData = dstVideoEncoder.getOutputBuffers()[eobIndex];

                        if (null != capturedDataCallback && 0 < eInfo.size) {
                            if (0 >= startEncodeTimestamp)
                                startEncodeTimestamp = eInfo.presentationTimeUs;

                            byte[] data = new byte[eInfo.size];
                            encodedData.get(data);
                            encodedData.clear();
                            capturedDataCallback.onCapturedDataUpdate(Constant.AVC, 0, data, eInfo.presentationTimeUs - startEncodeTimestamp, eInfo);
                        }

                        dstVideoEncoder.releaseOutputBuffer(eobIndex, false);
                        break;
                }
            }
            try {
                sleep(5);
            } catch (InterruptedException ignored) {
            }
        }
        eInfo = null;
    }
}