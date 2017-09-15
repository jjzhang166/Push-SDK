package com.wangyong.demo.pushsdk.RESVideoTools;

import android.graphics.Bitmap;
import android.graphics.ImageFormat;
import android.graphics.Rect;
import android.graphics.SurfaceTexture;
import android.hardware.Camera;
import android.media.MediaCodecInfo;

import com.wangyong.demo.pushsdk.BasicClasses.CallbackInterfaces;
import com.wangyong.demo.pushsdk.BasicClasses.Loging;
import com.wangyong.demo.pushsdk.RESVideoTools.Tools.CameraHelper;
import com.wangyong.demo.pushsdk.RESVideoTools.Tools.RESConfig;
import com.wangyong.demo.pushsdk.RESVideoTools.Tools.RESCoreParameters;
import com.wangyong.demo.pushsdk.RESVideoTools.Tools.Size;
import com.wangyong.demo.pushsdk.RESVideoTools.Filters.BaseHardVideoFilter;

import java.io.IOException;
import java.util.List;

/**
 * Created by lake on 16-5-24.
 */
public class RESVideoClient {
    private final static String TAG = "RESVideoClient";

    RESCoreParameters resCoreParameters;
    private final Object syncOp = new Object();
    private Camera camera;
    private SurfaceTexture camTexture;
    private int cameraNum;
    private int currentCameraIndex;
    private RESVideoCore videoCore;
    private boolean isStreaming;
    private boolean isPreviewing;

    public RESVideoClient(RESCoreParameters parameters) {
        resCoreParameters = parameters;
        cameraNum = Camera.getNumberOfCameras();
//        currentCameraIndex = Camera.CameraInfo.CAMERA_FACING_BACK;
        currentCameraIndex = Camera.CameraInfo.CAMERA_FACING_FRONT;
        isStreaming = false;
        isPreviewing = false;
    }

    public boolean prepare() {
        synchronized (syncOp) {

            if (null == (camera = createCamera(currentCameraIndex))) {
                Loging.Log(Loging.LOG_ERROR, TAG, "can not open camera");
                return false;
            }
            Camera.Parameters parameters = camera.getParameters();
            Size targetSize = new Size(resCoreParameters.videoWidth, resCoreParameters.videoHeight);
            CameraHelper.selectCameraPreviewWH(parameters, resCoreParameters, targetSize);
            CameraHelper.selectCameraFpsRange(parameters, resCoreParameters);
            if (resCoreParameters.videoFPS > resCoreParameters.previewMaxFps / 1000) {
                resCoreParameters.videoFPS = resCoreParameters.previewMaxFps / 1000;
            }
            resoveResolution(resCoreParameters, targetSize);
            if (!CameraHelper.selectCameraColorFormat(parameters, resCoreParameters)) {
                Loging.Log(Loging.LOG_ERROR, TAG, "CameraHelper.selectCameraColorFormat,Failed");
                resCoreParameters.dump();
                return false;
            }
            if (!CameraHelper.configCamera(camera, resCoreParameters)) {
                Loging.Log(Loging.LOG_ERROR, TAG, "CameraHelper.configCamera,Failed");
                resCoreParameters.dump();
                return false;
            }
//            switch (resCoreParameters.filterMode) {
//                case RESCoreParameters.FILTER_MODE_SOFT:
//                    videoCore = new RESVideoCore(resCoreParameters);
//                    break;
//                case RESCoreParameters.FILTER_MODE_HARD:
//                    videoCore = new RESVideoCore(resCoreParameters);
//                    break;
//            }

            videoCore = new RESVideoCore(resCoreParameters);

            if (!videoCore.prepare()) {
                return false;
            }
            videoCore.setCurrentCamera(currentCameraIndex);
            prepareVideo();
            return true;
        }
    }

    private Camera createCamera(int cameraId) {
        try {
            camera = Camera.open(cameraId);
            camera.setDisplayOrientation(0);
        } catch (SecurityException e) {
            Loging.trace(TAG, "no permission", e);
            return null;
        } catch (Exception e) {
            Loging.trace(TAG, "camera.open()failed", e);
            return null;
        }
        return camera;
    }

    private boolean prepareVideo() {
        if (resCoreParameters.filterMode == RESCoreParameters.FILTER_MODE_SOFT) {
            camera.addCallbackBuffer(new byte[resCoreParameters.previewBufferSize]);
            camera.addCallbackBuffer(new byte[resCoreParameters.previewBufferSize]);
        }
        return true;
    }

    private boolean startVideo() {
        camTexture = new SurfaceTexture(RESConfig.OVERWATCH_TEXTURE_ID);
        camTexture.setOnFrameAvailableListener(new SurfaceTexture.OnFrameAvailableListener() {
            @Override
            public void onFrameAvailable(SurfaceTexture surfaceTexture) {
                synchronized (syncOp) {
                    if (videoCore != null) {
                        videoCore.onFrameAvailable();
                    }
                }
            }
        });
        try {
            camera.setPreviewTexture(camTexture);
        } catch (IOException e) {
            Loging.trace(TAG, " setPreviewTexture ", e);
            camera.release();
            return false;
        }
        camera.startPreview();
        return true;
    }

    public boolean startPreview(SurfaceTexture surfaceTexture, int visualWidth, int visualHeight) {
        synchronized (syncOp) {
            if (!isStreaming && !isPreviewing) {
                if (!startVideo()) {
                    resCoreParameters.dump();
                    Loging.Log(Loging.LOG_ERROR, TAG, "RESVideoClient,start(),failed");
                    return false;
                }
                videoCore.updateCamTexture(camTexture);
            }
            videoCore.startPreview(surfaceTexture, visualWidth, visualHeight);
            isPreviewing = true;
            return true;
        }
    }

    public void updatePreview(int visualWidth, int visualHeight) {
        videoCore.updatePreview(visualWidth, visualHeight);
    }

    public boolean stopPreview(boolean releaseTexture) {
        synchronized (syncOp) {
            if (isPreviewing) {
                videoCore.stopPreview(releaseTexture);
                if (!isStreaming) {
                    camera.stopPreview();
                    videoCore.updateCamTexture(null);
                    camTexture.release();
                }
            }
            isPreviewing = false;
            return true;
        }
    }

    public boolean startStreaming(CallbackInterfaces.CapturedDataCallback capturedDataCallback) {
        synchronized (syncOp) {
            if (!isStreaming && !isPreviewing) {
                if (!startVideo()) {
                    resCoreParameters.dump();
                    Loging.Log(Loging.LOG_ERROR, TAG, "RESVideoClient,start(),failed");
                    return false;
                }
                videoCore.updateCamTexture(camTexture);
            }
            videoCore.startStreaming(capturedDataCallback);
            isStreaming = true;
            return true;
        }
    }

    public boolean stopStreaming() {
        synchronized (syncOp) {
            if (isStreaming) {
                videoCore.stopStreaming();
                if (!isPreviewing) {
                    camera.stopPreview();
                    videoCore.updateCamTexture(null);
                    camTexture.release();
                }
            }
            isStreaming = false;
            return true;
        }
    }


    public boolean destroy() {
        synchronized (syncOp) {
            camera.release();
            videoCore.destroy();
            videoCore = null;
            camera = null;
            return true;
        }
    }

    public boolean swapCamera() {
        synchronized (syncOp) {
            Loging.Log(TAG, "RESClient,swapCamera()");
            camera.stopPreview();
            camera.release();
            camera = null;
            if (null == (camera = createCamera(currentCameraIndex = (++currentCameraIndex) % cameraNum))) {
                Loging.Log(Loging.LOG_ERROR, TAG, "can not swap camera");
                return false;
            }
            videoCore.setCurrentCamera(currentCameraIndex);
            CameraHelper.selectCameraFpsRange(camera.getParameters(), resCoreParameters);
            if (!CameraHelper.configCamera(camera, resCoreParameters)) {
                camera.release();
                return false;
            }
            prepareVideo();
            camTexture.release();
            videoCore.updateCamTexture(null);
            startVideo();
            videoCore.updateCamTexture(camTexture);
            return true;
        }
    }

    public boolean toggleFlashLight() {
        synchronized (syncOp) {
            try {
                Camera.Parameters parameters = camera.getParameters();
                List<String> flashModes = parameters.getSupportedFlashModes();
                String flashMode = parameters.getFlashMode();
                if (!Camera.Parameters.FLASH_MODE_TORCH.equals(flashMode)) {
                    if (flashModes.contains(Camera.Parameters.FLASH_MODE_TORCH)) {
                        parameters.setFlashMode(Camera.Parameters.FLASH_MODE_TORCH);
                        camera.setParameters(parameters);
                        return true;
                    }
                } else if (!Camera.Parameters.FLASH_MODE_OFF.equals(flashMode)) {
                    if (flashModes.contains(Camera.Parameters.FLASH_MODE_OFF)) {
                        parameters.setFlashMode(Camera.Parameters.FLASH_MODE_OFF);
                        camera.setParameters(parameters);
                        return true;
                    }
                }
            } catch (Exception e) {
                Loging.Log(TAG, "toggleFlashLight,failed" + e.getMessage());
                return false;
            }
            return false;
        }
    }

    public boolean setZoomByPercent(float targetPercent) {
        synchronized (syncOp) {
            targetPercent = Math.min(Math.max(0f, targetPercent), 1f);
            Camera.Parameters p = camera.getParameters();
            p.setZoom((int) (p.getMaxZoom() * targetPercent));
            camera.setParameters(p);
            return true;
        }
    }

    public void reSetVideoBitrate(int bitrate) {
        synchronized (syncOp) {
            if (videoCore != null) {
                videoCore.reSetVideoBitrate(bitrate);
            }
        }
    }

    public int getVideoBitrate() {
        synchronized (syncOp) {
            if (videoCore != null) {
                return videoCore.getVideoBitrate();
            } else {
                return 0;
            }
        }
    }

    public void reSetVideoFPS(int fps) {
        synchronized (syncOp) {
            int targetFps;
            if (fps > resCoreParameters.previewMaxFps / 1000) {
                targetFps = resCoreParameters.previewMaxFps / 1000;
            } else {
                targetFps = fps;
            }
            if (videoCore != null) {
                videoCore.reSetVideoFPS(targetFps);
            }
        }
    }

    public boolean reSetVideoSize(Size targetVideoSize) {
        synchronized (syncOp) {
            RESCoreParameters newParameters = new RESCoreParameters();
            newParameters.isPortrait = resCoreParameters.isPortrait;
            newParameters.filterMode = resCoreParameters.filterMode;
            Camera.Parameters parameters = camera.getParameters();
            CameraHelper.selectCameraPreviewWH(parameters, newParameters, targetVideoSize);
            resoveResolution(newParameters, targetVideoSize);
            boolean needRestartCamera = (newParameters.previewVideoHeight != resCoreParameters.previewVideoHeight
                    || newParameters.previewVideoWidth != resCoreParameters.previewVideoWidth);
            if (needRestartCamera) {
                newParameters.previewBufferSize = calculator(resCoreParameters.previewVideoWidth,
                        resCoreParameters.previewVideoHeight, resCoreParameters.previewColorFormat);
                resCoreParameters.previewVideoWidth = newParameters.previewVideoWidth;
                resCoreParameters.previewVideoHeight = newParameters.previewVideoHeight;
                resCoreParameters.previewBufferSize  = newParameters.previewBufferSize;
                if ((isPreviewing || isStreaming)) {
                    Loging.Log(TAG, "RESClient,reSetVideoSize.restartCamera");
                    camera.stopPreview();
                    camera.release();
                    camera = null;
                    if (null == (camera = createCamera(currentCameraIndex))) {
                        Loging.Log(Loging.LOG_ERROR, TAG, "can not createCamera camera");
                        return false;
                    }
                    if (!CameraHelper.configCamera(camera, resCoreParameters)) {
                        camera.release();
                        return false;
                    }
                    prepareVideo();
                    videoCore.updateCamTexture(null);
                    camTexture.release();
                    startVideo();
                    videoCore.updateCamTexture(camTexture);
                }
            }
            videoCore.reSetVideoSize(newParameters);
            return true;
        }
    }

//    public BaseSoftVideoFilter acquireSoftVideoFilter() {
//        if (resCoreParameters.filterMode == RESCoreParameters.FILTER_MODE_SOFT) {
//            return videoCore.acquireVideoFilter();
//        }
//        return null;
//    }

    public void releaseSoftVideoFilter() {
        if (resCoreParameters.filterMode == RESCoreParameters.FILTER_MODE_SOFT) {
            videoCore.releaseVideoFilter();
        }
    }

//    public void setSoftVideoFilter(BaseSoftVideoFilter baseSoftVideoFilter) {
//        if (resCoreParameters.filterMode == RESCoreParameters.FILTER_MODE_SOFT) {
//            videoCore.setVideoFilter(baseSoftVideoFilter);
//        }
//    }

    public BaseHardVideoFilter acquireHardVideoFilter() {
        if (resCoreParameters.filterMode == RESCoreParameters.FILTER_MODE_HARD) {
            return videoCore.acquireVideoFilter();
        }
        return null;
    }

    public void releaseHardVideoFilter() {
        if (resCoreParameters.filterMode == RESCoreParameters.FILTER_MODE_HARD) {
            videoCore.releaseVideoFilter();
        }
    }

    public void setHardVideoFilter(BaseHardVideoFilter baseHardVideoFilter) {
        if (resCoreParameters.filterMode == RESCoreParameters.FILTER_MODE_HARD) {
            videoCore.setVideoFilter(baseHardVideoFilter);
        }
    }

    public void addVideoIcon(Bitmap bitmap, Rect rect) {
        if (resCoreParameters.filterMode == RESCoreParameters.FILTER_MODE_HARD) {
            videoCore.addVideoIcon(bitmap, rect);
        }
    }

    public void updateIcon(Bitmap bitmap, Rect rect) {
        if (resCoreParameters.filterMode == RESCoreParameters.FILTER_MODE_HARD) {
            videoCore.updateIcon(bitmap, rect);
        }
    }

    public void removeIcon(int index) {
        if (resCoreParameters.filterMode == RESCoreParameters.FILTER_MODE_HARD) {
            videoCore.removeFilter(index);
        }
    }

    public void setBeautyLevel(int smooth, int white, int pink) {
        if (null != videoCore)
            videoCore.setBeautyLevel(smooth, white, pink);
    }

//    public void takeScreenShot(RESScreenShotListener listener) {
//        synchronized (syncOp) {
//            if (videoCore != null) {
//                videoCore.takeScreenShot(listener);
//            }
//        }
//    }
//
//    public void setVideoChangeListener(RESVideoChangeListener listener) {
//        synchronized (syncOp) {
//            if (videoCore != null) {
//                videoCore.setVideoChangeListener(listener);
//            }
//        }
//    }

    public float getDrawFrameRate() {
        synchronized (syncOp) {
            return videoCore == null ? 0 : videoCore.getDrawFrameRate();
        }
    }

    private void resoveResolution(RESCoreParameters resCoreParameters, Size targetVideoSize) {
        if (resCoreParameters.filterMode == RESCoreParameters.FILTER_MODE_SOFT) {
            if (resCoreParameters.isPortrait) {
                resCoreParameters.videoHeight = resCoreParameters.previewVideoWidth;
                resCoreParameters.videoWidth = resCoreParameters.previewVideoHeight;
            } else {
                resCoreParameters.videoWidth = resCoreParameters.previewVideoWidth;
                resCoreParameters.videoHeight = resCoreParameters.previewVideoHeight;
            }
        } else {
            float pw, ph, vw, vh;
            if (resCoreParameters.isPortrait) {
                resCoreParameters.videoHeight = targetVideoSize.getWidth();
                resCoreParameters.videoWidth = targetVideoSize.getHeight();
                pw = resCoreParameters.previewVideoHeight;
                ph = resCoreParameters.previewVideoWidth;
            } else {
                resCoreParameters.videoWidth = targetVideoSize.getWidth();
                resCoreParameters.videoHeight = targetVideoSize.getHeight();
                pw = resCoreParameters.previewVideoWidth;
                ph = resCoreParameters.previewVideoHeight;
            }
            vw = resCoreParameters.videoWidth;
            vh = resCoreParameters.videoHeight;
            float pr = ph / pw, vr = vh / vw;
            if (pr == vr) {
                resCoreParameters.cropRatio = 0.0f;
            } else if (pr > vr) {
                resCoreParameters.cropRatio = (1.0f - vr / pr) / 2.0f;
            } else {
                resCoreParameters.cropRatio = -(1.0f - pr / vr) / 2.0f;
            }
        }
    }

    private int calculator(int width, int height, int colorFormat) {
        switch (colorFormat) {
            case MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420SemiPlanar:
            case MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Planar:
            case ImageFormat.NV21:
            case ImageFormat.YV12:
                return width * height * 3 / 2;
            default:
                return -1;
        }
    }
}
