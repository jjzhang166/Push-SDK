package org.anyrtc.PA.filter;

import java.util.Arrays;

/**
 * Created by kanli on 12/22/16.
 */

public class HSBHardVideoFilter extends ColorMatrixHardVideoFilter {
    private float[][] mMatrix = new float[4][4];
    private static final float RLUM = (0.299f);
    private static final float GLUM = (0.587f);
    private static final float BLUM = (0.114f);
    @Override
    public void onInit(int inWidth, int inHeight, int outWidth, int outHeight) {
        super.onInit(inWidth, inHeight, outWidth, outHeight);
        reset();
    }
    public void reset() {
        mMatrix = identmat();
        updateColorMatrix();
    }
    /** Add a hue rotation to the filter.
     The hue rotation is in the range [-360, 360] with 0 being no-change.
     Note that this adjustment is additive, so use the reset method if you need to.
     */
    public void rotateHue(float h) {
        mMatrix = huerotatemat(mMatrix, h);
        updateColorMatrix();
    }

    /** Add a saturation adjustment to the filter.
     The saturation adjustment is in the range [0.0, 2.0] with 1.0 being no-change.
     Note that this adjustment is additive, so use the reset method if you need to.
     */
    public void adjustSaturation(float s) {
        mMatrix = saturatemat(mMatrix, s);
        updateColorMatrix();
    }

    /** Add a brightness adjustment to the filter.
     The brightness adjustment is in the range [0.0, 2.0] with 1.0 being no-change.
     Note that this adjustment is additive, so use the reset method if you need to.
     */
    public void adjustBrightness(float b) {
        mMatrix = cscalemat(mMatrix, b, b, b);
        updateColorMatrix();
    }

    private void updateColorMatrix() {
        synchronized (mColorMatrix) {
            int x = 0, y = 0;
            for (y = 0; y < 4; y++) {
                for (x = 0; x < 4; x++) {
                    mColorMatrix[y * 4 + x] = mMatrix[y][x];
                }
            }
        }
    }
    private static float[][] identmat() {
        float[][] mat = new float[4][4];
        Arrays.fill(mat[0], 0.0f);
        Arrays.fill(mat[1], 0.0f);
        Arrays.fill(mat[2], 0.0f);
        Arrays.fill(mat[3], 0.0f);
        mat[0][0] = 1.0f;
        mat[1][1] = 1.0f;
        mat[2][2] = 1.0f;
        mat[3][3] = 1.0f;
        return mat;
    }

    private static float[] xformpnt(
            float [][] matrix,
            float x, float y, float z
            ) {
        float tx, ty, tz;
        tx = x*matrix[0][0] + y*matrix[1][0] + z*matrix[2][0] + matrix[3][0];
        ty = x*matrix[0][1] + y*matrix[1][1] + z*matrix[2][1] + matrix[3][1];
        tz = x*matrix[0][2] + y*matrix[1][2] + z*matrix[2][2] + matrix[3][2];
        return new float[] {tx, ty, tz};
    }
    private float[][] cscalemat(
            float[][] matrix,
            float rscale, float gscale, float bscale
    ) {
        float[][] mmat = new float[4][4];
        mmat[0][0] = rscale;
        mmat[0][1] = 0.0f;
        mmat[0][2] = 0.0f;
        mmat[0][3] = 0.0f;

        mmat[1][0] = 0.0f;
        mmat[1][1] = gscale;
        mmat[1][2] = 0.0f;
        mmat[1][3] = 0.0f;


        mmat[2][0] = 0.0f;
        mmat[2][1] = 0.0f;
        mmat[2][2] = bscale;
        mmat[2][3] = 0.0f;

        mmat[3][0] = 0.0f;
        mmat[3][1] = 0.0f;
        mmat[3][2] = 0.0f;
        mmat[3][3] = 1.0f;
        return matrixmult(matrix, mmat);
    }

    private static float[][] matrixmult(
        float [][] a, float [][] b
    ) {
        int x, y;
        float[][] temp = new float[4][4];

        for(y=0; y<4 ; y++)
            for(x=0 ; x<4 ; x++) {
                temp[y][x] = b[y][0] * a[0][x]
                        + b[y][1] * a[1][x]
                        + b[y][2] * a[2][x]
                        + b[y][3] * a[3][x];
            }
        return temp;
    }
    private static float[][] saturatemat(
        float[][] mat,
        float sat
    ) {
        float[][] mmat = new float[4][4];
        float a, b, c, d, e, f, g, h, i;
        float rwgt, gwgt, bwgt;

        rwgt = RLUM;
        gwgt = GLUM;
        bwgt = BLUM;

        a = (1.0f-sat)*rwgt + sat;
        b = (1.0f-sat)*rwgt;
        c = (1.0f-sat)*rwgt;
        d = (1.0f-sat)*gwgt;
        e = (1.0f-sat)*gwgt + sat;
        f = (1.0f-sat)*gwgt;
        g = (1.0f-sat)*bwgt;
        h = (1.0f-sat)*bwgt;
        i = (1.0f-sat)*bwgt + sat;
        mmat[0][0] = a;
        mmat[0][1] = b;
        mmat[0][2] = c;
        mmat[0][3] = 0.0f;

        mmat[1][0] = d;
        mmat[1][1] = e;
        mmat[1][2] = f;
        mmat[1][3] = 0.0f;

        mmat[2][0] = g;
        mmat[2][1] = h;
        mmat[2][2] = i;
        mmat[2][3] = 0.0f;

        mmat[3][0] = 0.0f;
        mmat[3][1] = 0.0f;
        mmat[3][2] = 0.0f;
        mmat[3][3] = 1.0f;
        return matrixmult(mmat,mat);
    }

    private static float[][] xrotatemat(
        float[][] mat,
        float rs, float rc
    ) {
        float[][] mmat = new float[4][4];

        mmat[0][0] = 1.0f;
        mmat[0][1] = 0.0f;
        mmat[0][2] = 0.0f;
        mmat[0][3] = 0.0f;

        mmat[1][0] = 0.0f;
        mmat[1][1] = rc;
        mmat[1][2] = rs;
        mmat[1][3] = 0.0f;

        mmat[2][0] = 0.0f;
        mmat[2][1] = -rs;
        mmat[2][2] = rc;
        mmat[2][3] = 0.0f;

        mmat[3][0] = 0.0f;
        mmat[3][1] = 0.0f;
        mmat[3][2] = 0.0f;
        mmat[3][3] = 1.0f;
        return matrixmult(mmat,mat);
    }

    private static float[][] yrotatemat(
        float[][] mat,
        float rs, float rc)
    {
        float[][] mmat = new float[4][4];

        mmat[0][0] = rc;
        mmat[0][1] = 0.0f;
        mmat[0][2] = -rs;
        mmat[0][3] = 0.0f;

        mmat[1][0] = 0.0f;
        mmat[1][1] = 1.0f;
        mmat[1][2] = 0.0f;
        mmat[1][3] = 0.0f;

        mmat[2][0] = rs;
        mmat[2][1] = 0.0f;
        mmat[2][2] = rc;
        mmat[2][3] = 0.0f;

        mmat[3][0] = 0.0f;
        mmat[3][1] = 0.0f;
        mmat[3][2] = 0.0f;
        mmat[3][3] = 1.0f;
        return matrixmult(mmat,mat);
    }

    private static float[][] zrotatemat(
        float[][] mat,
        float rs, float rc)
    {
        float[][] mmat = new float[4][4];

        mmat[0][0] = rc;
        mmat[0][1] = rs;
        mmat[0][2] = 0.0f;
        mmat[0][3] = 0.0f;

        mmat[1][0] = -rs;
        mmat[1][1] = rc;
        mmat[1][2] = 0.0f;
        mmat[1][3] = 0.0f;

        mmat[2][0] = 0.0f;
        mmat[2][1] = 0.0f;
        mmat[2][2] = 1.0f;
        mmat[2][3] = 0.0f;

        mmat[3][0] = 0.0f;
        mmat[3][1] = 0.0f;
        mmat[3][2] = 0.0f;
        mmat[3][3] = 1.0f;
        return matrixmult(mmat,mat);
    }

    private static float[][] zshearmat(
        float[][] mat,
        float dx, float dy)
    {
        float[][] mmat = new float[4][4];

        mmat[0][0] = 1.0f;
        mmat[0][1] = 0.0f;
        mmat[0][2] = dx;
        mmat[0][3] = 0.0f;

        mmat[1][0] = 0.0f;
        mmat[1][1] = 1.0f;
        mmat[1][2] = dy;
        mmat[1][3] = 0.0f;

        mmat[2][0] = 0.0f;
        mmat[2][1] = 0.0f;
        mmat[2][2] = 1.0f;
        mmat[2][3] = 0.0f;

        mmat[3][0] = 0.0f;
        mmat[3][1] = 0.0f;
        mmat[3][2] = 0.0f;
        mmat[3][3] = 1.0f;
        return matrixmult(mmat,mat);
    }
    /*
     *	huerotatemat -
     *		rotate the hue, while maintaining luminance.
     */
    private static float[][] huerotatemat(
        float mat[][],
        float rot)
    {
        float[][] mmat = new float[4][4];
        float mag;
        float lx, ly, lz;
        float xrs, xrc;
        float yrs, yrc;
        float zrs, zrc;
        float zsx, zsy;

        mmat = identmat();

    /* rotate the grey vector into positive Z */
        mag = (float)Math.sqrt(2.0);
        xrs = 1.0f/mag;
        xrc = 1.0f/mag;
        mmat = xrotatemat(mmat,xrs,xrc);
        mag = (float)Math.sqrt(3.0);
        yrs = -1.0f/mag;
        yrc = (float)Math.sqrt(2.0)/mag;
        mmat = yrotatemat(mmat,yrs,yrc);

    /* shear the space to make the luminance plane horizontal */
        float [] lv = xformpnt(mmat,RLUM,GLUM,BLUM);
        lx = lv[0];
        ly = lv[1];
        lz = lv[2];
        zsx = lx/lz;
        zsy = ly/lz;
        mmat = zshearmat(mmat,zsx,zsy);

    /* rotate the hue */
        zrs = (float) Math.sin(rot*Math.PI/180.0);
        zrc = (float)Math.cos(rot*Math.PI/180.0);
        mmat = zrotatemat(mmat,zrs,zrc);

    /* unshear the space to put the luminance plane back */
        mmat = zshearmat(mmat,-zsx,-zsy);

    /* rotate the grey vector back into place */
        mmat = yrotatemat(mmat,-yrs,yrc);
        mmat = xrotatemat(mmat,-xrs,xrc);

        return matrixmult(mmat,mat);
    }

}
