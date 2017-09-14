package com.wangyong.demo.pushsdk.BasicClasses;

/**
 * Created by wangyong on 2017/6/30.
 */

public class ByteHelper {

    private static final String TAG = "ByteHelper";

    public static void print(byte[] bytes){
        Loging.Log(TAG, "byte:" + toString(bytes));
    }

    public static String toString(byte[] bytes){
        StringBuffer buffer = new StringBuffer();
        for(byte b : bytes){
            buffer.append(String.format(" %02x", b));
        }
        return buffer.toString();
    }
}