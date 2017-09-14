//
//  PAClientCollect.h
//  TalkingData
//
//  Created by YICAI
//  Copyright (c) 2015年. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PACollectTalkingData : NSObject

//开启会话后定时记录当前手机电量和定位位置
+ (void)sessionStarted;

//设定一条记录的定位数据数，默认值5
+ (void)setMaxLocationCount:(NSInteger)maxCount;

//设定一条记录的电池数据数，默认值5
+ (void)setMaxBatteryCount:(NSInteger)maxCount;

//设定SDK最大缓存数据数，默认值30
+ (void)setUploadLimit:(NSInteger)uploadLimit;

//设定定位采集时间间隔（毫秒），默认值120000
+ (void)setLocationInterval:(NSInteger)locationInterval;

//设定电池采集时间间隔（毫秒），默认值120000
+ (void)setBatteryInterval:(NSInteger)batteryInterval;

//是否收集定位信息，默认值TRUE
+ (void)setCollectLocationEnable:(BOOL)enable;

//是否收集电池信息，默认值TRUE
+ (void)setCollectBatteryEnable:(BOOL)enable;

//是否打印日志，默认值FALSE
+ (void)setLogEnabled:(BOOL)enable;
@end