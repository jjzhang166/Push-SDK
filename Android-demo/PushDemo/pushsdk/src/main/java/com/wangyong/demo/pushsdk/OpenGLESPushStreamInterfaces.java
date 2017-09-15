package com.wangyong.demo.pushsdk;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Rect;
import android.graphics.SurfaceTexture;
import android.opengl.GLSurfaceView;

import com.wangyong.demo.pushsdk.BasicClasses.CallbackInterfaces;
import com.wangyong.demo.pushsdk.BasicClasses.Loging;

/**
 * Created by wangyong on 2017/7/5.
 */

public class OpenGLESPushStreamInterfaces {
    private String TAG = "PushStreamInterfaces";

    private String pushUrl = null;

    private RESPushStreamManager pushStreamManager = null;

    public OpenGLESPushStreamInterfaces(Context context, int rotation, int width, int height, int fps, int bitrate, int sampleRate, int sampleBit, int channels, int audioBitrate) {
        pushStreamManager = new RESPushStreamManager(context, rotation, width, height, fps, bitrate, sampleRate, sampleBit, channels, audioBitrate);
    }

    public void init(String uri) {
        Loging.Log(TAG, "init");

        this.pushUrl = uri;

        pushStreamManager.init(pushUrl);
    }

    public void startPreview(SurfaceTexture surfaceTexture, int screenWidth, int screenHeight) {
        if (null != pushStreamManager)
            pushStreamManager.startPreview(surfaceTexture, screenWidth, screenHeight);
    }

    public void stopPreview(boolean destorySurfaceView) {
        if (null != pushStreamManager)
            pushStreamManager.stopPreview(destorySurfaceView);
    }

    public void updatePreview(int w, int h) {
        if (null != pushStreamManager)
            pushStreamManager.updatePreview(w, h);
    }

    public int startPushStream() {
        Loging.Log(TAG, "startPushStream");

        int nRC = pushStreamManager.pushStreamStart();

        return nRC;
    }

    public int stopPushStream() {
        Loging.Log(TAG, "stopPushStream");

        if (null == pushStreamManager)
            return -1;

        pushStreamManager.pushStreamStop();

        return 0;
    }

    public int restartPushStream() {
        Loging.Log(TAG, "restartPushStream");

        stopPushStream();

        return startPushStream();
    }

    public void addVideoIcon(Bitmap bitmap, Rect rect) {
      if (null != pushStreamManager)
            pushStreamManager.addVideoIcon(bitmap, rect);
    }

    public void updateIcon(Bitmap bitmap, Rect rect) {
        if (null != pushStreamManager)
            pushStreamManager.updateIcon(bitmap, rect);
    }

    public void removeIcon(int index) {
        if (null != pushStreamManager)
            pushStreamManager.removeIcon(index);
    }

    public void setFilterType(int filter) {
        if (null != pushStreamManager)
            pushStreamManager.setFilterType(filter);
    }

    public void denoise(boolean denoise) {
        if (null != pushStreamManager)
            pushStreamManager.denoise(denoise);
    }

    public void setBeautyLevel(int smooth, int white, int pink) {
        if (null != pushStreamManager)
            pushStreamManager.setBeautyLevel(smooth, white, pink);
    }

    public void startWonderfulfileMuxer(String filePath) {
        if (null != pushStreamManager)
            pushStreamManager.startWonderfulfileMuxer(filePath);
    }

    public void stopWonderfulfileMuxer() {
        if (null != pushStreamManager)
            pushStreamManager.stopWonderfulfileMuxer();
    }

    public void setPushSDKCallback(CallbackInterfaces.PushSDKCallback callback, int interval) {
        if (null != pushStreamManager)
            pushStreamManager.setPushSDKCallback(callback, interval);
    }

    public void destroy() {

        if (null != pushStreamManager)
            pushStreamManager.destroy();
        setDefaultParameters();
    }

    /********************* Private *********************/

    private void setDefaultParameters() {
        pushStreamManager = null;
    }
}
