package com.wangyong.demo.pushsdk.BasicClasses;

import android.app.Fragment;

import java.util.concurrent.ConcurrentLinkedQueue;

/**
 * Created by wangyong on 2017/7/3.
 */

public class DataQueue extends ConcurrentLinkedQueue {
    private ConcurrentLinkedQueue<DataStructure.Data> queue = null;
    private int queueLen = 0;
    private long queueStartTime = 0;
    private long queueEndTime = 0;
    private String name = null;

    public DataQueue(String name) {
        this.queue = new ConcurrentLinkedQueue<DataStructure.Data>();
        this.queueLen = 0;
        this.name = name;
    }

    public boolean addTailer(DataStructure.Data data) {
        boolean added = queue.add(data);

        if (true == added) {
            queueLen++;
            queueEndTime = data.timestamp;
        }
        return added;
    }

    public DataStructure.Data removeHeader() {

        if (queueLen <= 0) {
            queueLen = 0;
            return null;
        }

        DataStructure.Data data = queue.poll();
        if (null != data) {
            queueStartTime = data.timestamp;
            queueLen--;
            if (0 >= queueLen)
                queueLen = 0;
        }

        return data;
    }

//
//    public boolean removeData(DataStructure.Data data) {
//
//        if (queueLen <= 0) {
//            queueLen = 0;
//            return true;
//        }
//
//        boolean removed = queue.remove(data);
//        if (true == removed)
//            queueLen --;
//
//        return removed;
//    }

    public long queueDuration() {
        long duration =  queueEndTime - queueStartTime;
        if (0 > duration)duration = 0;

        return duration;
    }

    public void cleanQueue() {
        while (queueLen > 0)
            removeHeader();
    }

    public int len() {
        if (queueLen > 0)
            return queueLen;

        queueLen = 0;

        return queueLen;
    }
}
