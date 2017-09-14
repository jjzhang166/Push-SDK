package com.wangyong.demo.pushsdk.BasicClasses;

import android.media.MediaCodec;
import android.media.MediaFormat;

/**
 * Created by wangyong on 2017/7/3.
 */

public interface DataStructure {

    public class EncodedData{
        public byte[] data = null;
        public MediaCodec.BufferInfo bufferInfo = null;
        public MediaFormat format = null;
    }

    public class Data {
        // 0 audio 1 video
        public int type;
        public long idx;
        public byte[] buf;
        // timestamp 微秒
        public long timestamp;
        public int flags;

        public Data(int type, long idx, byte[] buf, long timestamp, int flags) {
            this.type = type;
            this.idx = idx;
            this.buf = buf;
            this.timestamp = timestamp;
            this.flags = flags;
        }
    }
}
