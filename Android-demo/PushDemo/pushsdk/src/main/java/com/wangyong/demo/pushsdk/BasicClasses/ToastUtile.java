package com.wangyong.demo.pushsdk.BasicClasses;

/**
 * Created by wangyong on 2017/5/18.
 */
import android.content.Context;
import android.widget.Toast;

public class ToastUtile {

    // 构造方法私有化 不允许new对象
    private ToastUtile() {
    }

    // Toast对象
    private static Toast toast = null;

    /**
     * 显示Toast
     */
    public static void makeText(Context context, String text) {
        if (toast == null) {
            toast = Toast.makeText(context, "", Toast.LENGTH_SHORT);
        }
        toast.setText(text);
        toast.show();
    }
}
