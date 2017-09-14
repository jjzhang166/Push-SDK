package org.webrtc;

/**
 * Created by kanli on 12/18/16.
 */

public class CaptureFilterObserver implements VideoCapturer.CapturerObserver {
    final private VideoCapturer.CapturerObserver mCapturerObserver;
    final private SurfaceTextureHelper mHelper;
    final private CaptureTextureCallback mCaptureTextureCallback;
    public CaptureFilterObserver(VideoCapturer.CapturerObserver capturerObserver, SurfaceTextureHelper helper, CaptureTextureCallback captureTextureCallback) {
        mCapturerObserver = capturerObserver;
        mHelper = helper;
        mCaptureTextureCallback = captureTextureCallback;
    }
    @Override
    public void onCapturerStarted(boolean success) {
        if (success) {
            mCaptureTextureCallback.onSurfaceCreated();
        } else {
            mCaptureTextureCallback.onSurfaceDestroyed();
        }
        mCapturerObserver.onCapturerStarted(success);
    }

    @Override
    public void onByteBufferFrameCaptured(byte[] data, int width, int height, int rotation, long timeStamp) {
        mCapturerObserver.onByteBufferFrameCaptured(data, width, height, rotation, timeStamp);
    }

    @Override
    public void onTextureFrameCaptured(int width, int height, int oesTextureId, float[] transformMatrix, int rotation, long timestamp) {
        CaptureTextureCallback.FrameInfo frameInfo = mCaptureTextureCallback.onDrawFrame(oesTextureId, width, height, transformMatrix);
        mCapturerObserver.onTextureFrameCaptured(frameInfo.texWidth, frameInfo.texHeight, frameInfo.texId, frameInfo.transformMatrix, rotation, timestamp);
    }

    @Override
    public void onOutputFormatRequest(int width, int height, int framerate) {
        mCaptureTextureCallback.onSurfaceChanged(width, height);
        mCapturerObserver.onOutputFormatRequest(width, height, framerate);
    }
}
