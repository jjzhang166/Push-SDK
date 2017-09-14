package com.wangyong.demo.pushsdk.BasicClasses;

import android.media.MediaCodec;

/**
 * Created by wangyong on 2017/6/30.
 */

public interface CallbackInterfaces {

    interface CapturedDataCallback {
        void onCapturedDataUpdate(int type, long index, Object data, long timestamp, MediaCodec.BufferInfo info);
    }

    interface ThreadBaseInterface {
        int RunLoop(int id);
    }

    interface PushSDKCallback {
        int onPushSDKCallback(int type, long info, long param1, long param2);
    }
}