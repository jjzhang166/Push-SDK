package org.anyrtc.PA.filter;

import android.opengl.GLES11Ext;
import android.opengl.GLES20;
import java.nio.FloatBuffer;

/**
 * Created by kanli on 12/20/16.
 */

public class OriginalHardCameraFilter extends OriginalHardVideoFilter {
    private static String FRAGMENTSHADER = "" +
            "#extension GL_OES_EGL_image_external : require\n"+
            "precision mediump float;\n" +
            "varying mediump vec2 vCamTextureCoord;\n" +
            "uniform samplerExternalOES uCamTexture;\n" +
            "void main(){\n" +
            "    vec4  color = texture2D(uCamTexture, vCamTextureCoord);\n" +
            "    gl_FragColor = color;\n" +
            "}";
    public OriginalHardCameraFilter() {
        super(null, FRAGMENTSHADER);
    }
    public OriginalHardCameraFilter(String vertexShaderCode, String fragmentShaderCode) {
        super(vertexShaderCode, fragmentShaderCode);
    }
    @Override
    public void onDraw(int cameraTexture, int targetFrameBuffer, FloatBuffer shapeBuffer, FloatBuffer textrueBuffer) {
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, targetFrameBuffer);
        GLES20.glUseProgram(glProgram);
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, cameraTexture);
        GLES20.glUniform1i(glTextureLoc, 0);
        GLES20.glEnableVertexAttribArray(glCamPostionLoc);
        GLES20.glEnableVertexAttribArray(glCamTextureCoordLoc);
        shapeBuffer.position(0);
        GLES20.glVertexAttribPointer(glCamPostionLoc, 2,
                GLES20.GL_FLOAT, false,
                2 * 4, shapeBuffer);
        textrueBuffer.position(0);
        GLES20.glVertexAttribPointer(glCamTextureCoordLoc, 2,
                GLES20.GL_FLOAT, false,
                2 * 4, textrueBuffer);
        onPreDraw();
        GLES20.glViewport((OUT_WIDTH-IN_WIDTH)/2, (OUT_HEIGHT - IN_HEIGHT)/2, IN_WIDTH, IN_HEIGHT);
        //GLES20.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        //GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
        GLES20.glDrawElements(GLES20.GL_TRIANGLES, drawIndecesBuffer.limit(), GLES20.GL_UNSIGNED_SHORT, drawIndecesBuffer);
        onAfterDraw();
        GLES20.glDisableVertexAttribArray(glCamPostionLoc);
        GLES20.glDisableVertexAttribArray(glCamTextureCoordLoc);
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, 0);
        GLES20.glUseProgram(0);
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0);
    }
}
