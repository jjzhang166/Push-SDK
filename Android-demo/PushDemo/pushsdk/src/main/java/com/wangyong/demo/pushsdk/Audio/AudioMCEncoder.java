package com.wangyong.demo.pushsdk.Audio;

import android.media.MediaCodec;
import android.media.MediaFormat;
import android.util.Log;

import com.wangyong.demo.pushsdk.BasicClasses.CallbackInterfaces;
import com.wangyong.demo.pushsdk.BasicClasses.DataStructure;
import com.wangyong.demo.pushsdk.BasicClasses.Loging;

import java.nio.ByteBuffer;

/**
 * Created by wangyong on 2017/7/5.
 */

public class AudioMCEncoder {

    private static final String TAG = "AudioMCEncoder";
    private static final int ABITRATE_KBPS = 32;
    private static final String ACODEC = MediaFormat.MIMETYPE_AUDIO_AAC;//"audio/mp4a-latm";

    private long AACOutputCount = 0;

    private int sampleRate = 0, sampleBit = 0, channels = 0, bitRate = 0;
    private MediaCodec encoder = null;
    private boolean started = false;
    private MediaCodec.BufferInfo bufferInfo = null;

    public int init(int sampleRate, int sampleBit, int channels, int bitRate) {

        this.sampleRate = sampleRate;
        this.sampleBit = sampleBit;
        this.channels = channels;
        this.bitRate = bitRate;

        try {
            encoder = MediaCodec.createEncoderByType(ACODEC);
        } catch (Exception e) {
            Loging.Log(Loging.LOG_ERROR, TAG, "create aencoder failed.");
            e.printStackTrace();
            return -1;
        }
        bufferInfo = new MediaCodec.BufferInfo();

        return 0;
    }

    public void start() {
        if (false == started) {
            Loging.Log(Loging.LOG_INFO, TAG, "node start aac encoder");

            MediaFormat audioFormat = MediaFormat.createAudioFormat(ACODEC, sampleRate, channels);
            audioFormat.setInteger(MediaFormat.KEY_BIT_RATE, 1000 * ABITRATE_KBPS);
            audioFormat.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 0);
            audioFormat.setInteger(MediaFormat.KEY_BIT_RATE, bitRate);

            encoder.configure(audioFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE);
            encoder.start();
            started = true;
        }
    }

    public int queueInputBuffer(byte[] data, long pts) throws InterruptedException {
        ByteBuffer[] inBuffers = encoder.getInputBuffers();
        int inBufferIndex = -1;

        int tryTimes = 0;
        while (tryTimes++ < 3) { // Try three times to dequeue input buffer
            inBufferIndex = encoder.dequeueInputBuffer(10); // 10ms
            if (0 <= inBufferIndex)
                break;
        }

        if (inBufferIndex >= 0) {
            ByteBuffer bb = inBuffers[inBufferIndex];
            bb.clear();
            bb.put(data, 0, data.length);
            encoder.queueInputBuffer(inBufferIndex, 0, data.length, pts, 0);
        } else
            return -1; // Drop this input audio PCM

        return 0;
    }

    public Object dequeueOutputBuffer(int timeout) {

        DataStructure.EncodedData encodedData = null;

        ByteBuffer[] outBuffers = encoder.getOutputBuffers();
        int encoderStatus = encoder.dequeueOutputBuffer(bufferInfo, timeout);


        switch (encoderStatus) {
            case MediaCodec.INFO_TRY_AGAIN_LATER:
            case MediaCodec.INFO_OUTPUT_FORMAT_CHANGED:
                return encoder.getOutputFormat();
            case MediaCodec.INFO_OUTPUT_BUFFERS_CHANGED:
                break;
            default:{
                if (encoderStatus < 0) // Other un-caught error.
                    return null;

                encodedData = new DataStructure.EncodedData();

                int outBufferIndex = encoderStatus;
                ByteBuffer bb = outBuffers[outBufferIndex];
                encodedData.data = new byte[bufferInfo.size];
                bb.get(encodedData.data);
                bb.clear();
                encodedData.bufferInfo = bufferInfo;

                AACOutputCount ++;

                encoder.releaseOutputBuffer(outBufferIndex, false);

                break;
            }
        }

        return encodedData;
    }

    public void stop() {
        if (encoder != null && true == started) {
            encoder.stop();
            started = false;
        }
    }

    public void destroy() {
        if (null != encoder) {
            if (true == started)
                encoder.stop();
            encoder.release();
        }
        setDefaultParameters();
    }

    /******************* Private ********************/

    private void setDefaultParameters() {
        AACOutputCount = sampleRate = sampleBit = channels = bitRate = 0;

        encoder = null;
        bufferInfo = null;
    }
}
