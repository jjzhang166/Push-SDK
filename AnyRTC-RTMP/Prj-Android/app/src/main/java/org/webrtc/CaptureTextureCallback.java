package org.webrtc;

/**
 * Created by kanli on 12/18/16.
 */

public interface CaptureTextureCallback {
    public class FrameInfo {
        public int texId;
        public int texWidth;
        public int texHeight;
        public float[] transformMatrix;
    }
    void onSurfaceCreated();

    void onSurfaceChanged(int width, int height);

    void onSurfaceDestroyed();

    FrameInfo onDrawFrame(int texId, int texWidth, int texHeight, float[] transformMatrix);
}
