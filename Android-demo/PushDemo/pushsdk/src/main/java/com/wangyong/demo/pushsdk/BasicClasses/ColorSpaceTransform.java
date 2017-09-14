package com.wangyong.demo.pushsdk.BasicClasses;

/**
 * Created by wangyong on 2017/7/12.
 */

public abstract  class ColorSpaceTransform {

    private static final String TAG = "ColorSpaceTransform";

    protected int width;
    protected int height;

    public ColorSpaceTransform(int width, int height) {
        this.width = width;
        this.height = height;
        Loging.Log(TAG, "ColorSpaceTransform;" + getClass().getSimpleName());
    }

    public abstract byte[] transform(byte[] src, byte[] dest);

    public static class Unknown extends ColorSpaceTransform {

        public Unknown(int width, int height) {
            super(width, height);
        }

        @Override
        public byte[] transform(byte[] src, byte[] dest) {
            System.arraycopy(src, 0, dest, 0, src.length);
            return dest;
        }
    }

    public static class YV12toYUV420Planar extends ColorSpaceTransform {

        public YV12toYUV420Planar(int width, int height) {
            super(width, height);
        }

        @Override
        public byte[] transform(byte[] src, byte[] dest) {
            YV12toYUV420Planar(src, dest, width, height);
            return dest;
        }
    }

    public static class YV12toYUV420SemiPlanar extends ColorSpaceTransform {

        public YV12toYUV420SemiPlanar( int width, int height) {
            super(width, height);
        }

        @Override
        public byte[] transform(byte[] src, byte[] dest) {
            YV12toYUV420PackedSemiPlanar(src, dest, width, height);
            return dest;
        }
    }

    public static class YV12toYUV420PackedPlanar extends ColorSpaceTransform {

        public YV12toYUV420PackedPlanar(int width, int height) {
            super(width, height);
        }

        @Override
        public byte[] transform(byte[] src, byte[] dest) {
            YV12toYUV420PackedSemiPlanar(src, dest, width, height);
            return dest;
        }
    }

    public static class NV21toYUV420Planar extends ColorSpaceTransform {

        public NV21toYUV420Planar(int width, int height) {
            super(width, height);
        }

        @Override
        public byte[] transform(byte[] src, byte[] dest) {
            NV21toYUV420Planar(src, dest, width, height);
            return dest;
        }
    }

    public static class NV21toYUV420SemiPlanar extends ColorSpaceTransform {

        public NV21toYUV420SemiPlanar(int width, int height) {
            super(width, height);
        }

        @Override
        public byte[] transform(byte[] src, byte[] dest) {
            NV21toYUV420SemiPlanar(src, dest, width, height);
            return dest;
        }
    }

    public static class NV21toYUV420PackedPlanar extends ColorSpaceTransform {

        public NV21toYUV420PackedPlanar(int width, int height) {
            super(width, height);
        }

        @Override
        public byte[] transform(byte[] src, byte[] dest) {
            NV21toYUV420SemiPlanar(src, dest, width, height);
            return dest;
        }
    }

    private static byte[] NV21toYUV420Planar(byte[] input, byte[] output, int width, int height) {
        final int frameSize = width * height;
        final int qFrameSize = frameSize/4;

        System.arraycopy(input, 0, output, 0, frameSize); // Y

        byte v, u;

        // vuvu->uv
        for (int i = 0; i < qFrameSize; i++) {
            v = input[frameSize + i*2];
            u = input[frameSize + i*2 + 1];

            output[frameSize + i + qFrameSize] = v;
            output[frameSize + i] = u;
        }

        return output;
    }

    @SuppressWarnings("unused")
    private static byte[] NV21toYUV420SemiPlanar(byte[] input, byte[] output, int width, int height) {
        final int frameSize = width * height;
        final int qFrameSize = frameSize/4;

        System.arraycopy(input, 0, output, 0, frameSize); // Y

        for (int i = 0; i < qFrameSize; i++) {
            output[frameSize + i*2] = input[frameSize + i*2 + 1]; // U
            output[frameSize + i*2 + 1] = input[frameSize + i*2]; // V
        }

        return output;
    }

    private static byte[] YV12toYUV420PackedSemiPlanar(final byte[] input, final byte[] output, final int width, final int height) {
        final int frameSize = width * height;
        final int qFrameSize = frameSize / 4;

        System.arraycopy(input, 0, output, 0, frameSize); // Y

        for (int i = 0; i < qFrameSize; i++) {
            output[frameSize + i * 2] = input[frameSize + i + qFrameSize]; // Cb (U)
            output[frameSize + i * 2 + 1] = input[frameSize + i]; // Cr (V)
        }
        return output;
    }

    private static byte[] YV12toYUV420Planar(byte[] input, byte[] output, int width, int height) {
        final int frameSize = width * height;
        final int qFrameSize = frameSize / 4;

//       yvu -> yuv
        System.arraycopy(input, 0, output, 0, frameSize); // Y
        System.arraycopy(input, frameSize, output, frameSize + qFrameSize, qFrameSize); // Cr (V)
        System.arraycopy(input, frameSize + qFrameSize, output, frameSize, qFrameSize); // Cb (U)

        return output;
    }
}
