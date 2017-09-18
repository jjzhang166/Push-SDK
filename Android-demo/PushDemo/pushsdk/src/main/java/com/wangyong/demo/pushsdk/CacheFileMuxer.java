package com.wangyong.demo.pushsdk;

import android.media.MediaCodec;
import android.media.MediaFormat;

import com.wangyong.demo.pushsdk.BasicClasses.Constant;
import com.wangyong.demo.pushsdk.BasicClasses.DataQueue;
import com.wangyong.demo.pushsdk.BasicClasses.DataStructure;
import com.wangyong.demo.pushsdk.BasicClasses.Loging;

/**
 * Created by wangyong on 2017/9/18.
 */

public class CacheFileMuxer {
    private static final String TAG = "CacheFileMuxer";

    private AndroidMediaMuxer androidMediaMuxer = null;
    private boolean writing = false;

    private DataQueue aacDataQueue = null;
    private DataQueue avcDataQueue = null;

    private long avcStartTimestamp = 0;
    private long avcCurrentTimestamp = 0;

    private int cachedDuration = 0;
    private int totalDuration = 0;
    private int gopMax = 0;

    public CacheFileMuxer(String name) {
        aacDataQueue = new DataQueue("CacheAACDataQueue");
        avcDataQueue = new DataQueue("CacheAVCDataQueue");
        androidMediaMuxer = new AndroidMediaMuxer(name);
    }

    public void setCachedDuration(int cachedDuration, int totalDuration, int gop) {
        this.cachedDuration = cachedDuration;
        this.totalDuration = totalDuration;
        this.gopMax = gop * 1200;
    }

    public int intputCacheData(DataStructure.Data data) {
        if (Constant.AAC == data.type && null != aacDataQueue) {

            aacDataQueue.addTailer(data);

        } else if (Constant.AVC  == data.type && null != avcDataQueue) {

            if (0 == avcStartTimestamp)
                avcStartTimestamp = data.timestamp;
            avcCurrentTimestamp = data.timestamp;

            avcDataQueue.addTailer(data);

            if (false == writing && avcCurrentTimestamp - avcStartTimestamp > cachedDuration + gopMax)
                dropCachedData(avcStartTimestamp + gopMax);
        } else {
            Loging.Log(Loging.LOG_ERROR, TAG, "inputCacheData type " + data.type + " AAC queue " + aacDataQueue + " AVC queue " + avcDataQueue);
            return -1;
        }
        return 0;
    }

    public int startMux(MediaFormat audioMediaFormat, MediaFormat videoMediaFormat) {
        if (null == androidMediaMuxer || null == aacDataQueue || null == avcDataQueue) {
            Loging.Log(Loging.LOG_ERROR, TAG, "startMux failed androidMediaMuxer " + androidMediaMuxer + " AAC queue " + aacDataQueue + " AVC qu");
            return -1;
        }

        if (null == audioMediaFormat || null == videoMediaFormat) {
            Loging.Log(Loging.LOG_ERROR, TAG, "startMux failed audioMediaForma " + audioMediaFormat + " videoMediaFormat " + videoMediaFormat);
            return -1;
        }

        androidMediaMuxer.addTrack(true, audioMediaFormat);
        androidMediaMuxer.addTrack(false, videoMediaFormat);

        new Thread(new Runnable() {
            @Override
            public void run() {
                boolean bAudio = false;
                long audioTimestamp = 0;
                long videoTimestamp = 0;
                long writeStartTimestamp = 0;

                DataStructure.Data data = null;

                androidMediaMuxer.start();
                writing = true;

                while (true) {
                    data = (DataStructure.Data)aacDataQueue.peek();
                    audioTimestamp = data.timestamp;
                    data = (DataStructure.Data)avcDataQueue.peek();
                    videoTimestamp = avcStartTimestamp = data.timestamp;

                    if (0 == writeStartTimestamp)
                        writeStartTimestamp = videoTimestamp;

                    if (videoTimestamp - writeStartTimestamp >= totalDuration && 0 != (data.flags & MediaCodec.BUFFER_FLAG_KEY_FRAME))
                        break;

                    if (audioTimestamp <= videoTimestamp) {
                        data = aacDataQueue.removeHeader();
                        bAudio = true;
                    } else {
                        data = avcDataQueue.removeHeader();
                    }

                    androidMediaMuxer.writeData(bAudio, data.buf, data.format);
                }

                androidMediaMuxer.stop();
                writing = false;
            }
        }).start();

        return 0;
    }

    private void dropCachedData(long endTimestamp) {
        DataStructure.Data data = null;
        while (null != avcDataQueue) {
            data = (DataStructure.Data) avcDataQueue.peek();
            if (null != data && data.timestamp < endTimestamp) {

                if (data.timestamp > avcStartTimestamp  && 0 != (data.flags & MediaCodec.BUFFER_FLAG_KEY_FRAME)) {
                    // We only drop ONE GOP.
                    avcStartTimestamp = data.timestamp;
                    break;
                }

                data = avcDataQueue.removeHeader();
                if (null != data)
                    avcStartTimestamp = data.timestamp;
            } else if (null == data) {
                break;
            }
        }

        // Drop AAC data
        if (null != aacDataQueue) {
            data = (DataStructure.Data) aacDataQueue.peek();
            while (null != data) {
                if (data.timestamp < avcStartTimestamp)
                    data = aacDataQueue.removeHeader();
                else
                    break;
                data = (DataStructure.Data) aacDataQueue.peek();
            }
        }
    }
}
