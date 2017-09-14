package org.anyrtc.PA.filter;

import android.content.Context;
import android.opengl.GLES11;
import android.opengl.GLES11Ext;
import android.opengl.GLES20;

import org.anyrtc.PA.gles.GLESTools;
import org.anyrtc.anyrtmp.R;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;

/**
 * @author hukanli@jk.cn
 * @Description
 * @date 2017_01_25.
 */
public class TowInputGaussianFilterHard extends BaseHardVideoFilter{
    protected int glProgram;
    protected int glCamTextureLoc;
    protected int glCamPostionLoc;
    protected int glCamTextureCoordLoc;
    protected int glImageTextureLoc;
    protected int glImageTextureCoordLoc;

    protected int xStepLoc;
    protected int yStepLoc;
    protected int stepScale;
    protected int beautyLevelLoc;
    protected int brightLevelLoc;
    protected int pinkLevelLoc;
    protected String vertexShader_filter = null;
    protected String fragmentshader_filter = null;

    private int glGaussianMapLoc;
    float[] gaussianMap  = new float[9];
    float sigma_s = 3.0f;

    float beautyLevel = 0.0f;
    float brightLevel = 0.0f;
    float pinkLevel = 0.0f;

    /*
    protected static float texture2Vertices[] = {
            1.0f, 0.0f,
            1.0f, 1.0f,
            0.0f, 1.0f,
            0.0f, 0.0f};
            */
    private static float texture2Vertices[] = {
            0.0f, 1.0f,
            0.0f, 0.0f,
            1.0f, 0.0f,
            1.0f, 1.0f};

    protected FloatBuffer textureImageCoordBuffer;
    protected int imageTexture;
    protected float alpha;

    public TowInputGaussianFilterHard(Context context, int stepScale) {
        vertexShader_filter = GLESTools.readTextFile(
                    context.getResources(), R.raw.vertex_shader_two_input_gaussian);
        fragmentshader_filter = GLESTools.readTextFile(
                    context.getResources(), R.raw.fragment_shader_two_input_gaussian_3);
        this.stepScale = stepScale;
    }

    @Override
    public void onInit(int inWidth, int inHeight, int outWidth, int outHeight) {
        super.onInit(inWidth, inHeight, outWidth, outHeight);
        glProgram = GLESTools.createProgram(vertexShader_filter, fragmentshader_filter);
        GLES20.glUseProgram(glProgram);
        glCamTextureLoc = GLES20.glGetUniformLocation(glProgram, "uCamTexture");
        glImageTextureLoc = GLES20.glGetUniformLocation(glProgram, "uImageTexture");
        glCamPostionLoc = GLES20.glGetAttribLocation(glProgram, "aCamPosition");
        glCamTextureCoordLoc = GLES20.glGetAttribLocation(glProgram, "aCamTextureCoord");
        glImageTextureCoordLoc = GLES20.glGetAttribLocation(glProgram, "aImageTextureCoord");


        textureImageCoordBuffer = ByteBuffer.allocateDirect(4 * texture2Vertices.length).
                order(ByteOrder.nativeOrder()).
                asFloatBuffer();
        textureImageCoordBuffer.put(texture2Vertices);
        textureImageCoordBuffer.position(0);


        xStepLoc = GLES20.glGetUniformLocation(glProgram, "xStep");
        yStepLoc = GLES20.glGetUniformLocation(glProgram, "yStep");
        glGaussianMapLoc = GLES20.glGetUniformLocation(glProgram, "gaussianMap");

        beautyLevelLoc = GLES20.glGetUniformLocation(glProgram, "beautyLevel");
        brightLevelLoc = GLES20.glGetUniformLocation(glProgram, "brightLevel");
        pinkLevelLoc = GLES20.glGetUniformLocation(glProgram, "pinkLevel");
        float sigma_s22 = 2.0f * sigma_s * sigma_s;
        float sum = 0.0f;
        for (int i=0;i<=2;i++) {
            for (int j = 0; j <= 2; j++) {
                float f = (float) Math.exp(-(i * i + j * j) / sigma_s22);
                gaussianMap[i * 3 + j] = f;
            }
        }
        for (int i=-2;i<=2;i++) {
            for (int j=-2;j<=2;j++) {
                float f = gaussianMap[(i>0?i:-i)*3+(j>0?j:-j)];
                sum += f;
            }
        }
        for (int i=0;i<=2;i++) {
            for (int j = 0; j <= 2; j++) {
                gaussianMap[i*3+j] /= sum;
            }
        }

    }
    public void setImageTexture(int imageTexture) {
        this.imageTexture = imageTexture;
    }
    public void setBeautyLevel(float beautyLevel) {
        this.beautyLevel = beautyLevel;
    }
    public void setBrightLevel(float brightLevel) {
        this.brightLevel = brightLevel;
    }
    public void setPinkLevel(float pinkLevel) {
        this.pinkLevel = pinkLevel;
    }

    protected void onPreDraw() {
        GLES20.glUniform1f(xStepLoc, (float) (stepScale / IN_WIDTH));
        GLES20.glUniform1f(yStepLoc, (float) (stepScale / IN_HEIGHT));
        GLES20.glUniform1f(beautyLevelLoc, beautyLevel);
        GLES20.glUniform1f(brightLevelLoc, brightLevel);
        GLES20.glUniform1f(pinkLevelLoc, pinkLevel);
        GLES20.glUniformMatrix3fv(glGaussianMapLoc, 1, false, gaussianMap, 0);
    }
    protected void onPostDraw() {

    }

    @Override
    public void onDraw(int cameraTexture, int targetFrameBuffer, FloatBuffer shapeBuffer, FloatBuffer textrueBuffer) {
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, targetFrameBuffer);
        GLES20.glUseProgram(glProgram);
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, cameraTexture);
        GLES20.glUniform1i(glCamTextureLoc, 0);
        GLES20.glActiveTexture(GLES20.GL_TEXTURE1);
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, imageTexture);
        GLES20.glUniform1i(glImageTextureLoc, 1);
        GLES20.glEnableVertexAttribArray(glCamPostionLoc);
        GLES20.glEnableVertexAttribArray(glCamTextureCoordLoc);
        GLES20.glEnableVertexAttribArray(glImageTextureCoordLoc);
        shapeBuffer.position(0);
        GLES20.glVertexAttribPointer(glCamPostionLoc, 2,
                GLES20.GL_FLOAT, false,
                2 * 4, shapeBuffer);
        textrueBuffer.position(0);
        GLES20.glVertexAttribPointer(glCamTextureCoordLoc, 2,
                GLES20.GL_FLOAT, false,
                2 * 4, textrueBuffer);
        textureImageCoordBuffer.position(0);
        GLES20.glVertexAttribPointer(glImageTextureCoordLoc, 2,
                GLES20.GL_FLOAT, false,
                2 * 4, textureImageCoordBuffer);
        onPreDraw();
        GLES20.glViewport((OUT_WIDTH-IN_WIDTH)/2, (OUT_HEIGHT - IN_HEIGHT)/2, IN_WIDTH, IN_HEIGHT);
        //GLES20.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        //GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
        GLES20.glDrawElements(GLES20.GL_TRIANGLES, drawIndecesBuffer.limit(), GLES20.GL_UNSIGNED_SHORT, drawIndecesBuffer);
        GLES20.glDisableVertexAttribArray(glCamPostionLoc);
        GLES20.glDisableVertexAttribArray(glCamTextureCoordLoc);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, 0);
        GLES20.glUseProgram(0);
        GLES20.glBindFramebuffer(GLES20.GL_TEXTURE_2D, 0);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        GLES20.glDeleteProgram(glProgram);
        textureImageCoordBuffer.clear();
    }

}
