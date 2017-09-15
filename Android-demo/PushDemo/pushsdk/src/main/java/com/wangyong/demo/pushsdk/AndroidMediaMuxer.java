package com.wangyong.demo.pushsdk;

import android.media.MediaCodec;
import android.media.MediaFormat;
import android.media.MediaMuxer;

import java.io.IOException;
import java.nio.ByteBuffer;

/**
 * Created by wangyong on 2017/9/12.
 */

public class AndroidMediaMuxer {

    private static final String TAG = "AndroidMediaMuxer";

    private MediaMuxer mediaMuxer = null;
    private int audioStreamIndex = -1, videoSteamIndex = -1;
    private long audioStartTime = -1, videoStartTime = -1;

    private boolean dataWrote = false;

    public AndroidMediaMuxer(String outputFile) {
        try {
            mediaMuxer = new MediaMuxer(outputFile, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void start() {
        if (null != mediaMuxer)
            mediaMuxer.start();
    }

    public void stop() {
        if (null != mediaMuxer) {
            // stop() throws an exception if you haven't fed it any data.  Keep track
            // of frames submitted, and don't call stop() if we haven't written anything.

            if (true == dataWrote)
                mediaMuxer.stop();
            dataWrote = false;
        }
    }

    public void destroy() {
        if (null != mediaMuxer) {
            if (true == dataWrote)
                mediaMuxer.stop();

            mediaMuxer.release();
            mediaMuxer = null;
            audioStreamIndex = videoSteamIndex = -1;
            audioStartTime = videoStartTime = -1;
            dataWrote = false;
        }
    }

    public int addTrack(boolean audio, MediaFormat format) {
        if (null == mediaMuxer)
            return -1;

        int trackIndex = mediaMuxer.addTrack(format);
        if (0 > trackIndex)
            return trackIndex;

        if (true == audio)
            audioStreamIndex = trackIndex;
        else
            videoSteamIndex = trackIndex;

        return 0;
    }

    public int writeData(boolean audio, byte[] data, MediaCodec.BufferInfo info) {

        if (null == mediaMuxer || null == data)
            return -1;

        if (true == audio && 0 > audioStreamIndex)
            return -1;
        if (false == audio && 0 > videoSteamIndex)
            return -1;

        int trackIndex = -1;
        if (true == audio){
            trackIndex = audioStreamIndex;

            if (0 > audioStartTime)
                audioStartTime = info.presentationTimeUs;

            info.presentationTimeUs = info.presentationTimeUs - audioStartTime;
        } else {
            trackIndex = videoSteamIndex;

            if (0 > videoStartTime)
                videoStartTime = info.presentationTimeUs;

            info.presentationTimeUs = info.presentationTimeUs - videoStartTime;
        }

        mediaMuxer.writeSampleData(trackIndex, ByteBuffer.wrap(data), info);
        dataWrote = true;

        return -1;
    }
}
