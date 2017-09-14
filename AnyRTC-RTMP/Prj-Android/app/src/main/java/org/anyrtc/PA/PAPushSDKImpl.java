package org.anyrtc.PA;

import android.app.Activity;

import org.anyrtc.core.AnyRTMP;
import org.anyrtc.core.RTMPHosterHelper;
import org.anyrtc.core.RTMPHosterKit;
import org.webrtc.EglBase;
import org.webrtc.SurfaceViewRenderer;
import org.webrtc.VideoRenderer;

import static android.hardware.Camera.CameraInfo.*;
import static org.anyrtc.PA.PAPushSDK.PABitRate.*;
import static org.anyrtc.PA.PAPushSDK.PAResolution.*;

/**
 * Created by kanli on 12/6/16.
 */

class PAPushSDKImpl extends PAPushSDK{
    class MyRTMPHosterHelper implements RTMPHosterHelper {
        private PAPushSDKCallbackHandler mHandler;
        public MyRTMPHosterHelper(PAPushSDKCallbackHandler handler) {
            mHandler = handler;
        }
        @Override
        public void OnRtmpStreamOK() {
            mHandler.onMessage(PAEventCode.PA_START, 0, null ,null);
        }

        @Override
        public void OnRtmpStreamReconnecting(int times) {

        }

        @Override
        public void OnRtmpStreamStatus(int delayMs, int netBand) {
            mSpeed = netBand / 1000;
            mHandler.onMessage(PAEventCode.PA_PUSH_SPEED, 0, delayMs, netBand);
        }

        @Override
        public void OnRtmpStreamFailed(int code) {

        }

        @Override
        public void OnRtmpStreamClosed() {

        }
    }
    private Activity mActivity;
    private PAPushSDKCallbackHandler mHandler;
    private RTMPHosterKit mRtmpHosterKit;
    private SurfaceViewRenderer mSurfaceView;
    private VideoRenderer mRenderer = null;
    private String mUrl;
    private EglBase.Context mEglContext;
    private PABitRate mPABitRate = IA_550K;
    private float mSpeed = 0.0f;
    public PAPushSDKImpl(Activity act) {
        mEglContext = AnyRTMP.Inst().Egl().getEglBaseContext();
        mActivity = act;

    }
    @Override
    public String sdkVersion() {
        return "1.0";
    }

    @Override
    public void initPushSDK(PAPushSDKCallbackHandler handler) {
        mHandler = handler;
        mRtmpHosterKit = new RTMPHosterKit(mActivity, new MyRTMPHosterHelper(mHandler));
    }

    @Override
    public void setParam(PAResolution resolution, int fps, int sampleRate, int sampleBit, int channels, PABitRate bitRate) {
        int resolution_new = 0;
        int bitRate_new = 0;
        switch (resolution) {
            case IA_540P:
                resolution_new = 540;
                break;
            case IA_720P:
                resolution_new = 720;
                break;
            case IA_480P:
                resolution_new = 480;
                break;
            default:
                resolution_new = 540;
                break;
        }

        mPABitRate = bitRate;
        switch (bitRate) {
            case IA_450K:
                bitRate_new = 450;
                break;
            case IA_512K:
                bitRate_new = 512;
                break;
            case IA_550K:
                bitRate_new = 550;
                break;
            case IA_700K:
                bitRate_new = 700;
                break;
            case IA_1M:
                bitRate_new = 1024;
                break;
            case IA_1Dot5M:
                bitRate_new = 1536;
                break;
            case IA_2M:
                bitRate_new = 2048;
                break;
            default:
                bitRate_new = 550;
        }

        mRtmpHosterKit.SetAudioParam(sampleRate, sampleBit, channels);
        mRtmpHosterKit.SetVideoParam(resolution_new, fps, bitRate_new);
    }

    @Override
    public void setWindow(SurfaceViewRenderer view) {
        mSurfaceView = view;
        mSurfaceView.init(mEglContext, null);
        mRenderer = new VideoRenderer(mSurfaceView);
    }

    @Override
    public void setPushUrl(String url) {
        mUrl = url;

    }

    @Override
    public void setupDevice() {
        mRtmpHosterKit.SetVideoCapturer(mEglContext, mRenderer.GetRenderPointer(), true);
    }

    @Override
    public void startStreaming() {
        mRtmpHosterKit.StartRtmpStream(mUrl);
    }

    @Override
    public void restartPushStreaming() {
        mRtmpHosterKit.StopRtmpStream();
        mRtmpHosterKit.StartRtmpStream(mUrl);
    }

    @Override
    public void stopStreaming() {
        mRtmpHosterKit.StopRtmpStream();
    }

    @Override
    public void setCameraFront(boolean cameraFront) {
        int cameraId = 0;
        if (cameraFront) {
            cameraId = CAMERA_FACING_BACK;
        } else {
            cameraId = CAMERA_FACING_FRONT;
        }
        mRtmpHosterKit.SwitchCamera(cameraId);

    }

    @Override
    public void setBeautyFace(boolean beautyFace) {
        mRtmpHosterKit.SetBeautyFace(beautyFace);
    }

    @Override
    public void setCameraBeautyFilterWithSmooth(float smooth, float white, float pink) {
        mRtmpHosterKit.SetCameraBeautyFilterWithSmooth(smooth, white, pink);
    }

    @Override
    public void setFocusAtPoint(int x, int y) {
        mRtmpHosterKit.SetFocusAtPoint(x, y, mSurfaceView.getWidth(), mSurfaceView.getHeight());
    }

    @Override
    public void setVolume(int volume) {
        mRtmpHosterKit.SetVolume(volume);
    }

    @Override
    public float getSendSpeed() {
        return mSpeed;
    }

    @Override
    public PABitRate getBitRate() {
        return mPABitRate;
    }

    @Override
    public int getVideoDroppedFrameNum() {
        return 0;
    }

    @Override
    public float getDropdownFrameRate() {
        return 0;
    }

    @Override
    public void setActive(boolean active) {
        if (active) {
            mRtmpHosterKit.StartRtmpStream(mUrl);
        } else {
            mRtmpHosterKit.StopRtmpStream();
        }
    }

    @Override
    public void destroy() {
        mRtmpHosterKit.Clear();
    }
}
