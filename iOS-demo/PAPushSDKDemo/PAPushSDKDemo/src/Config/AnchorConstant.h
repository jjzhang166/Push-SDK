//
//  CommonConstant.h
//  anchor
//
//  Created by yu on 16/5/31.
//  Copyright © 2016年 PAJK. All rights reserved.
//

#ifndef CommonConstant_h
#define CommonConstant_h

/**
 * 本类描述一些常用的语句的宏
 */

#ifndef    weakify
#if __has_feature(objc_arc)
#define weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
#endif
#endif

#ifndef    strongify
#if __has_feature(objc_arc)
#define strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
#else
#define strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
#endif
#endif

#define PA_FIX_CATEGORY_BUG(name) @interface PA_FIX_CATEGORY_BUG_##name:NSObject @end \
@implementation PA_FIX_CATEGORY_BUG_##name @end

#define SCREEN_WIDTH    [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT   [[UIScreen mainScreen] bounds].size.height
#define SCREEN_SCALE    [UIScreen mainScreen].scale

#define JKN_SCREEN_WIDTH    SCREEN_WIDTH
#define JKN_SCREEN_HEIGHT   SCREEN_HEIGHT

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
// 版本比较
#define JKN_SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch|NSCaseInsensitiveSearch] == NSOrderedSame)
#define JKN_SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch|NSCaseInsensitiveSearch] == NSOrderedDescending)
#define JKN_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch|NSCaseInsensitiveSearch] != NSOrderedAscending)
#define JKN_SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch|NSCaseInsensitiveSearch] == NSOrderedAscending)
#define JKN_SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch|NSCaseInsensitiveSearch] != NSOrderedDescending)
#endif

//自适应的一些参数配置
#define baseSizeWidth 375  //多分辨率适配基准宽度，用来计算倍率

#define SCREEN_ADAPTER SCREEN_WIDTH/baseSizeWidth  //基准倍率

#define DEVICE_MODEL            [UIDevice currentDevice].model
#define DEVICE_MAC_ADDRESS      [[UIDevice currentDevice] macAddress]
#define DEVICE_SYSTEM_VERSION   [[UIDevice currentDevice] systemVersion]

#define APP_VERSION [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]

#ifndef IOS_VERSION
#define IOS_VERSION [[[UIDevice currentDevice] systemVersion] floatValue]
#endif

#define iOSVersion ([[[UIDevice currentDevice] systemVersion] floatValue])

//是否是模拟器
#if TARGET_IPHONE_SIMULATOR
#define SIMULATOR 1
#elif TARGET_OS_IPHONE
#define SIMULATOR 0
#endif


#define RGBCOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:(a)]
#define generateKeyChainKey(sourceKey) ([NSString stringWithFormat:@"%@_%@", sourceKey , [PAAPI_BaseUrl stringByReplacingOccurrencesOfString:@"http://" withString:@""]])

#define kKeyChainServiceName generateKeyChainKey(@"PHLKeyChainServiceName")

// 全部存放在customKeyChain中

#define kKeyChainUserDataToken generateKeyChainKey(@"PHLAccountTokenData_0")

//通知
#define PHLDidLoginSuccessNotification @"userLoginSuccessNotification"
#define PHLUserLockedNotification @"userLockedNotification"
#define PHLNoActiveDeviceNotification @"noActiveDeviceNotification"
#define PHLUserLogoutNotification @"userWillLogoutNotification"
//非主播用户
#define PHLIllegalUserNotification @"illegal_user_notification"

#define kNotificationShareStatus @"share_status_notification"


//标志是否是新装的应用第一次进入
#define kNotFirstLoginApp @"isFirstLogin"
#define kLastCheckVersionData @"last_checkversion_date"

//经纬度
#define kLastLongitude @"kLastLongitude"
#define kLastLatitude @"kLastLatitude"



#define onePixel (1.0/[[UIScreen mainScreen] scale])
#define isIphone_4_7_Inch ((double)[[UIScreen mainScreen] bounds].size.width - (double)360 > 0)

//分享账号
#define kWeixinShareAppID @"wx64c4b0ac5997c662"     // 分享用的微信AppID, 抬头是健康直播助手
#define kWeiboShareAppID @"2813730557"              // 微博:平安好医生

//蒲公英账号
#define PGY_APPKEY @"ddfeeb426b14b00c620d6381e1947ce1"


//用户已在其它地方登录的标志
static const NSString *PHLNoActiveDevice = @"NoActiveDevice";

#define DEPRECATED(_version) __attribute__((deprecated))

#endif /* CommonConstant_h */
