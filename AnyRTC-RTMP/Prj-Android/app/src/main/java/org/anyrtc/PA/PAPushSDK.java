package org.anyrtc.PA;
import android.app.Activity;

import org.webrtc.SurfaceViewRenderer;

import java.net.FileNameMap;

/**
 * Created by kanli on 12/6/16.
 */

public abstract class PAPushSDK {
    static public PAPushSDK createPushSDK(Activity activity){
        return new PAPushSDKImpl(activity);
    }
    abstract public String sdkVersion();
    abstract public void initPushSDK(PAPushSDKCallbackHandler handler);
    abstract public void setParam(PAResolution resolution, int fps, int sampleRate, int sampleBit, int channels, PABitRate bitRate);
    abstract public void setWindow(SurfaceViewRenderer view);
    abstract public void setPushUrl(String url);
    abstract public void setupDevice();
    abstract public void startStreaming();
    abstract public void restartPushStreaming();
    abstract public void stopStreaming();
    abstract public void setCameraFront(boolean cameraFront);
    abstract public void setBeautyFace(boolean beautyFace);
    abstract public void setCameraBeautyFilterWithSmooth(float smooth, float white, float pink);
    abstract public void setFocusAtPoint(int x, int y);
    abstract public void setVolume(int volume);
    abstract public float getSendSpeed();
    abstract public PABitRate getBitRate();
    abstract public int getVideoDroppedFrameNum();
    abstract public float getDropdownFrameRate();
    abstract public void setActive(boolean active);
    abstract public void destroy();

    public interface PAPushSDKCallbackHandler {
        public void onMessage(final int resultId, final int resultCode, final Object reserved1, final Object reserved2);
    }

    public enum PAResolution {
        IA_720P,
        IA_540P,
        IA_480P,
    }

    public enum  PABitRate {
        IA_450K,
        IA_512K,
        IA_550K,
        IA_700K,
        IA_1M,
        IA_1Dot5M,
        IA_2M,

    }

    public class PAEventCode {
        final public static int PA_START = 1;
        final public static int PA_PUSH_STREAM = 2;
        final public static int PA_STOP = 3;
        final public static int PA_OTHER = 4;
        final public static int PA_PUSH_SPEED = 5;
        final public static int PA_VIDEO_AUTHOR_FAIL = 6;
        final public static int PA_AUDIO_AUTHOR_FAIL = 7;
        final public static int PA_PUSH_EXCEPTION = 8;
    }
}
