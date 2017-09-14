//
//  IAUtility.h
//  MediaRecorder
//
//  Created by Derek Lix on 16/3/24.
//  Copyright © 2016年 Derek Lix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CocoaLumberjack.h"
#import "DDTTYLogger.h"


//static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#define IA_TermianteLogKey  @"IA_TermianteLogKey"
#define IALog_Key   @"IALog_Key"
#define IA_START_LiveStr   @"开始直播"

#define PA_Broadcast_Logo_Key   @"PA_Broadcast_Logo_Key"
#define PA_CAMERA_AUTHORIZE_FAIL       @"PA_CAMERA_AUTHORIZE_FAIL"
#define PA_MICROPHONE_AUTHORIZE_FAIL   @"PA_MICROPHONE_AUTHORIZE_FAIL"
#define PA_VIDEOHARDWARE_LOADERROR     @"videohardware_loaderror"
#define PA_AUDIOHARDWARE_LOADERROR     @"audiohardware_loaderror"
#define PA_RUNTIME_NOVIDEO             @"runtime_novideo"
#define PA_RUNTIME_NOAUDIO             @"runtime_noaudio"


static   NSString*  IA_EndPoint   =   @"http://oss-cn-hangzhou.aliyuncs.com/";
static   NSString*  IA_BucketName  =   @"smart-videos";
static   NSString*  IA_OSS_Path    =  @"http://smart-videos.oss-cn-hangzhou.aliyuncs.com/game/gpgameraw/%@";



#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@interface IAScoreInfo :NSObject<NSCoding>

@property(nonatomic,strong)NSString* homeScore;
@property(nonatomic,strong)NSString* guestScore;

@end

@interface IAVideoInfo : NSObject<NSCoding>

@property(nonatomic,strong)NSString*  gameId;
@property(nonatomic,strong)NSString*  vPath;
@property(nonatomic,strong)NSString*  imgPath;
@property(nonatomic,strong)NSString*  uploadFlag;
@property(nonatomic,assign)long long  videoSize;
@property(nonatomic,strong)NSString*  startTime;
@property(nonatomic,strong)NSString*  endTime;
@property(nonatomic,strong)NSString*  sportType;
@property(nonatomic,strong)NSString*  gameType;
@property(nonatomic,strong)NSString*  gameStatus;
@property(nonatomic,assign)NSTimeInterval duration;

@end

@interface IAGameInfo : NSObject<NSCoding>

@property(nonatomic,strong)NSString*  gameId;
@property(nonatomic,strong)NSString*  uploadFlag;
@property(nonatomic,assign)NSUInteger videoSize;
@property(nonatomic,strong)NSString*  gameStatus;
@property(nonatomic,strong)NSString*  gameType;

@end

@interface IAUploadGameVideosInfo : NSObject

@property(nonatomic,assign)NSUInteger videosCount;
@property(nonatomic,assign)NSInteger  currentIndex;
@property(nonatomic,assign)float      rate;
@property(nonatomic,assign)float      totalSize;
@property(nonatomic,assign)float      uploadedSize;
@end

typedef void(^IAAliyunUpLoadHandler)(NSString* gameId ,NSUInteger videosCount,NSUInteger currentIndex,float rate,float bytesSent,float totalSizeSent,float totalBytesExpectedToSend,NSError* error);
typedef void(^IAUploadVideoFinishedHandler)(NSString* gameId, NSString* videoPath);
typedef void(^IAOneVideoUploadedHandler)(NSString* gameId, NSString* videoPath);
typedef void(^IAAllVideosUploadedHandler)(NSString* gameId);
typedef void(^IARelateVideoGameHandler)(NSString* gameId, BOOL isSuccess);
typedef void(^IADeleteVideosHandler)(NSArray* pathArray);

@interface IAUtility : NSObject

+(BOOL)isMoreThanIOS10;
+(BOOL)isIphone7;
+(BOOL)moreThanIphone6;
+ (int)convertToInt:(NSString*)strtemp;
+ (NSString*)abstractStrForStreaming:(NSString*)sourceStr subLength:(float*)suLength;
+(NSMutableArray*)allAlbumVideos;
+ (double) appTotalAvaiableMemory;
+(NSURL*)cacheFileDirectory;
+(NSString*)rootRecordConfigKey;
+(NSString*)gameInfoKey:(NSString*)gameId;
+(NSString*)homeScoreKey:(NSString*)gameId;
+(NSString*)guestSocreKey:(NSString*)gameId;
+(NSString*)recordConfigKey:(NSString*)gameId;
+(NSString*)currentDate;
+(NSString*)currentTime;
+(NSString*)currentExactTime;
+(NSDate*)convertDateFromString:(NSString*)dateString formatter:(NSString*)formatter;

+(NSInteger)getVideoIndexWithPath:(NSString*)videoPath;
+(void)setStillCaptureImageData:(NSData*)imageData;
+(NSData*)stillCaptureImageData;
+(void)setRecordVideoStartTime:(NSString*)startTime;
+(NSString*)recordVideoStartTime;
+(void)setSportType:(NSString*)sportType;
+(NSString*)sportType;
+(void)setLastVideoFrameSize:(NSInteger)videoFrameSize;
+(NSInteger)lastVideoFrameSize;
+(void)setLastAudioFrameSize:(NSInteger)audioFrameSize;
+(NSInteger)lastAudioFrameSize;
+(void)setLastVideoFrameSendTime:(NSTimeInterval)timeInterval;
+(NSTimeInterval)lastVideoFrameSendTime;
+(void)setLastAudioFrameSendTime:(NSTimeInterval)timeInterval;
+(NSTimeInterval)lastAudioFrameSendTime;
+(UIImage *)getImageFromVideoFile:(NSString *)videoURL;
+(void)setGameStartTimeInterval:(NSTimeInterval)startTimeInterval;
+(NSTimeInterval)gameStartTimeInterval;
+(void)setParameter:(NSString*)parameter;
+(NSString*)parameter;
+(void)setEnv:(NSString*)env;
+(NSString*)env;
+(void)setUserId:(NSString*)userId;
+(NSString*)userId;
+(NSString*)clientId;
+(NSString*)gameId;
+(void)setGameId:(NSString*)gameId;
+(void)setGameType:(NSString*)gameType;
+(NSString*)gameType;
+(void)setGameStatus:(NSString*)gameStatus gameId:(NSString*)gameId;
+(NSString*)gameStatus;
+(void)setDownloadingMark:(NSString*)gameId;
+(NSString*)downloadingMark:(NSString*)gameId;
+(void)IALog:(id)logInfo;
+(NSTimeInterval)startTimestampInterval;
+(void)setStartTimestampInterval:(NSTimeInterval)startTimestampInterval;
+(unsigned long long) getGprsFlowBytes;
+(unsigned long long)getWifiBytes;
+(NSString *)bytesToAvaiUnit:(unsigned long long)bytes;
+(void)setGPRSInitialData:(unsigned long long)initialData;
+(unsigned long long)gPRSInitialData;
+(void)setWifiInitialData:(unsigned long long)initialData;
+(unsigned long long)wifigPRSInitialData;
+(void)setFlowBreakCount:(NSInteger)breakCount;
+(NSInteger)flowBreakCount;

+(void)configOSSParameter:(BOOL)debug;
+(void)setIsBroadcast:(BOOL)isBroadcast;
+(BOOL)isBroadcast;
+(NSString*)homeTeamWonderfullEventSequenceNumberKey:(NSString*)gameId;
+(NSString*)guestTeamWonderfullEventSequenceNumberKey:(NSString*)gameId;
+(NSString*)activityWonderfullEventSequenceNumberKey:(NSString*)gameId;

+(void)storeWaterMarkImageWithUrl:(NSString*)imageUrl;
+(BOOL)doesWaterMarkFileExist;
+(NSURL*)cacheWaterMarkImagePath;
@end
