package com.wangyong.demo.pushsdk;

import com.wangyong.demo.pushsdk.BasicClasses.Loging;

/**
 * Created by wangyong on 2017/8/21.
 */

public class FileMuxer {

    private final String TAG = "FileMuxer";

    private boolean debug = false;

    private final int AVC_HEADER_SIZE = 4;

    private long handler = 0;

    private int sampleRate = 0, sampleBit = 0, channels = 0;
    private byte [] sps = null, pps = null;
//    byte[] adts = new byte[7];

    public FileMuxer() {
        handler = nativeInit();
    }

    public int open(String name) {
        if (0 >= handler)
            return -1;

        return nativeOpen(handler, name);
    }

    public int close() {
        if (0 >= handler)
            return -1;

        int nRC = nativeClose(handler);
        if (0 > nRC)
            return nRC;

        return nativeUninit(handler);
    }

    public int setAudioParameter(int codecID, int bitrate, int samplerate, int samplebit, int channels) {
        if (0 >= handler)
            return -1;

        this.sampleRate = samplerate;
        this.sampleBit = samplebit;
        this.channels = channels;

        return nativeSetAudioParameter(handler, codecID, bitrate, samplerate, samplebit, channels);
    }

    public int setVideoParameter(int codecID, int bitrate, int width, int height, int fps, int gopsize) {
        if (0 >= handler)
            return -1;

        return nativeSetVideoParameter(handler, codecID, bitrate, width, height, fps, gopsize);
    }

    public int setSPSPPS(byte[] spspps) {
        if (0 >= handler)
            return -1;

        parserSPSPPS(spspps, AVC_HEADER_SIZE);
        if (null == sps || null == pps)
            return -1;

        return nativeSetSPSPPS(handler, sps, pps, sps.length, pps.length);
    }

    public int inputAudioSample(byte[] jdata, int size, long pts, long dts) {
        if (0 >= handler)
            return -1;

        return nativeInputAudioSample(handler, jdata, size, pts, dts);

//        adts = generateADTSHeader(size);
//        byte[] data = new byte[size + 7];
//        System.arraycopy(adts, 0, data, 0, 7);
//        System.arraycopy(jdata, 0, data, 7, size);
//        size += 7;
//
//        Loging.Log(TAG, "Eoollo Size : " + size + " : "  + byte2hex(data));
//
//        return nativeInputAudioSample(handler, data, size, pts, dts);
    }

    public int inputVideoSample(byte[] jdata, int size, long pts, long dts, boolean bKeyFrame) {
        if (0 >= handler)
            return -1;

        return nativeInputVideoSample(handler, jdata, size, pts, dts, bKeyFrame);
    }

    /**************************** Private ****************************/

    private void parserSPSPPS(byte[] data, int headerSize) {
        int spsIndex = 0, ppsIndex = 0, i = 0, size = data.length;
        int nSpsLen = 0, nPpsLen = 0;

        while(i < size - headerSize)
        {
            if(0 == (data[i] & 0xff) && 0 == (data[i + 1] & 0xff) && 0 == (data[i + 2] & 0xff) && 1 == (data[i + 3] & 0xff))
            {
                if(7 == (data[i + headerSize] & 0x1f))
                    spsIndex = i + headerSize;
                else if(8 == (data[i + headerSize] & 0x1f))
                    ppsIndex = i + headerSize;
            }
            i++;
        }

        if(spsIndex > 0 && ppsIndex > 0)
        {
            if(spsIndex < ppsIndex)
            {
                if (true == debug) {
                    nSpsLen = ppsIndex - spsIndex - headerSize;
                    nPpsLen = size - ppsIndex;
                    sps = new byte[nSpsLen];
                    pps = new byte[nPpsLen];

                    System.arraycopy(data, headerSize, sps, 0, nSpsLen);
                    System.arraycopy(data, ppsIndex, pps, 0, nPpsLen);
                } else {
                    nSpsLen = ppsIndex - spsIndex;
                    nPpsLen = size - ppsIndex + headerSize;
                    sps = new byte[nSpsLen];
                    pps = new byte[nPpsLen];

                    System.arraycopy(data, 0, sps, 0, nSpsLen);
                    System.arraycopy(data, ppsIndex - headerSize, pps, 0, nPpsLen);
                }
            }
            else
            {
                if (true == debug) {
                    nSpsLen = size - spsIndex;;
                    nPpsLen = spsIndex - ppsIndex - headerSize;
                    sps = new byte[nSpsLen];
                    pps = new byte[nPpsLen];

                    System.arraycopy(data, spsIndex, sps, 0, nSpsLen);
                    System.arraycopy(data, headerSize, pps, 0, nPpsLen);
                } else {
                    nSpsLen = size - spsIndex + headerSize;
                    nPpsLen = spsIndex - ppsIndex;
                    sps = new byte[nSpsLen];
                    pps = new byte[nPpsLen];

                    System.arraycopy(data, spsIndex - headerSize, sps, 0, nSpsLen);
                    System.arraycopy(data, 0, pps, 0, nPpsLen);
                }
            }
        }
        else if(spsIndex > 0)
        {
            nSpsLen = size - headerSize;
            sps = new byte[nSpsLen];

            System.arraycopy(data, headerSize, sps, 0, nSpsLen);
        }
        else if(ppsIndex > 0)
        {
            nPpsLen = size - headerSize;
            pps = new byte[nPpsLen];

            System.arraycopy(data, headerSize, pps, 0, nPpsLen);
        }
    }

//    private byte[] generateADTSHeader(int size) {
//        int sample_rate = 0;
//        size += 7;
//
//        if(this.sampleRate >= 96000)sample_rate = 0;
//        else if(this.sampleRate >= 88200)sample_rate = 1;
//        else if(this.sampleRate >= 64000)sample_rate = 2;
//        else if(this.sampleRate >= 48000)sample_rate = 3;
//        else if(this.sampleRate >= 44100)sample_rate = 4;
//        else if(this.sampleRate >= 32000)sample_rate = 5;
//        else if(this.sampleRate >= 24000)sample_rate = 6;
//        else if(this.sampleRate >= 22050)sample_rate = 7;
//        else if(this.sampleRate >= 16000)sample_rate = 8;
//
//        ///////// ADTS_FIXED_HEADER
//
//    /* Sync point over a full byte */
//
//        adts[0] = (byte)0xFF; // 1 ~ 12 : 0xFFF syncword
//        adts[1] = (byte)0xF1; // 13 : ID. 14 ~ 15 : layer, always "00", 16 : protection_absent
//
//        adts[2] = (byte)(0x01 << 6); // 17 ~ 18 : profile. main = 1, LC = 2, SSR = 3, LTP = 4, HE/SBR = 5;
//        adts[2] |= (sample_rate << 2); /* 19 ~ 22 : sampleRate index over next 4 bits */
//
//    /* 23 : private bit*/
//
//        adts[2] |= (this.channels & 0x4) >> 2; /* 24 ~ 26 : channels over last 2 bits */
//        adts[3] = (byte)((this.channels & 0x3) << 6); /* channels continued over next 2 bits + 4 bits at zero */
//
//    /* 27 : original_copy*/
//    /* 28 : home */
//
//        //////// ADTS_VARIABLE_HEADER
//
//    /* 29 : copyright_identification_bit */
//    /* 30 : copyright_identification_start */
//
//        adts[3] |= (size & 0x1800) >> 11; /* 31 ~ 43 : 13 bits for frame size. over last 2 bits */
//        adts[4] = (byte)((size & 0x1FF8) >> 3); /* frame size continued over full byte */
//        adts[5] = (byte)((size & 0x7) << 5); /* frame size continued first 3 bits */
//
//        adts[5] |= 0x1F; /* 44 ~ 54 : buffer fullness (0x7FF for VBR) over 5 last bits */
//        adts[6] = (byte)0xFC; /* buffer fullness (0x7FF for VBR) continued over 6 first bits + 2 zeros number of raw data blocks */
//
//        adts[6] |= 0 & 0x03; // 55 ~ 56 : number_of_raw_data_blocks_in_frame.
//
//        return adts;
//    }
//
//    private byte[] generateADTSHeader2(int size) {
//
//        int obj_type = 0;
////        int num_data_block = size / 1024;
//        int num_data_block = 2;
//
//        size += 7;
//
//        int sample_rate = 0;
//
//        if(this.sampleRate >= 96000)sample_rate = 0;
//        else if(this.sampleRate >= 88200)sample_rate = 1;
//        else if(this.sampleRate >= 64000)sample_rate = 2;
//        else if(this.sampleRate >= 48000)sample_rate = 3;
//        else if(this.sampleRate >= 44100)sample_rate = 4;
//        else if(this.sampleRate >= 32000)sample_rate = 5;
//        else if(this.sampleRate >= 24000)sample_rate = 6;
//        else if(this.sampleRate >= 22050)sample_rate = 7;
//        else if(this.sampleRate >= 16000)sample_rate = 8;
//
//        /* Generate ADTS header */
//
//        adts[0] = (byte)0xFF; // Sync point over a full byte
//        adts[1] = (byte)0xF9; // Sync point continued over first 4 bits + static 4 bits (ID, layer, protection)
//        adts[2] = (byte)(obj_type << 6); // Object type over first 2 bits
//        adts[2] |= (sample_rate << 2); // rate index over next 4 bits
//        adts[2] |= (this.channels & 0x4) >> 2; // channels over last 2 bits
//        adts[3] = (byte)((this.channels & 0x3) << 6); // channels continued over next 2 bits + 4 bits at zero
//        adts[3] |= (size & 0x1800) >> 11; // frame size over last 2 bits
//        adts[4] = (byte)((size & 0x1FF8) >> 3); // frame size continued over full byte
//        adts[5] = (byte)((size & 0x7) << 5); // frame size continued first 3 bits
//        adts[5] |= 0x1F; // buffer fullness (0x7FF for VBR) over 5 last bits
//        adts[6] = (byte)0xFC;// buffer fullness (0x7FF for VBR) continued over 6 first bits + 2 zeros number of raw data blocks.
//        adts[6] |= num_data_block & 0x03; //one raw data blocks, Set raw Data blocks.
//
//        return adts;
//    }

    private static String byte2hex(byte [] buffer){
        String h = "";

        for(int i = 0; i < buffer.length; i++){
            String temp = Integer.toHexString(buffer[i] & 0xFF);
            if(temp.length() == 1){
                temp = "0" + temp;
            }
            h = h + " "+ temp;
        }

        return h;

    }

    private native long nativeInit();
    private native int nativeUninit(long nHandler);
    private native int nativeOpen(long nHandler, String filename);
    private native int nativeClose(long handler);
    private native int nativeSetAudioParameter(long nHandler, int codecID, int bitrate, int samplerate, int samplebit, int channels);
    private native int nativeSetVideoParameter(long nHandler, int codecID, int bitrate, int width, int height, int fps, int gopsize);
    private native int nativeSetSPSPPS(long nHandler, byte[] jsps, byte[] jpps, int spsSize, int ppsSize);
    private native int nativeInputAudioSample(long nHandler, byte[] jdata, int size, long pts, long dts);
    private native int nativeInputVideoSample(long nHandler, byte[] jdata, int size, long pts, long dts, boolean keyframe);
}
