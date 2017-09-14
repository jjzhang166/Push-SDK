//
//  IAUtility.m
//  MediaRecorder
//
//  Created by Derek Lix on 16/3/24.
//  Copyright © 2016年 Derek Lix. All rights reserved.
//

#import "IAUtility.h"
#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "CocoaLumberjack.h"
#import "sys/utsname.h"
#include <sys/mount.h>
#import <AVFoundation/AVFoundation.h>
#import "LiveConfig.h"
#include <ifaddrs.h>
#include <sys/socket.h>
#include <net/if.h>


#define IA_gameId_key     @"gameId"
#define IA_vPath_Key      @"vPath"
#define IA_imgPath_Key    @"imgPath"
#define IA_uploadFlag_Key @"uploadFlag"
#define IA_videoSize_Key  @"videoSize"
#define IA_startTime_Key  @"startTime"
#define IA_endTime_Key    @"endTime"
#define IA_sportType_Key  @"sportType"
#define IA_gameStatus_Key @"gameStatus"
#define IA_gameType_Key   @"gameType"
#define IA_duration_Key   @"duration"

static NSString* gKeyStr = @"IARecordStreaming_";



static NSData*   gImageData = nil;
static NSString* gVideoStartTime = nil;
static NSString* gSportType = nil;
static NSInteger gLastVideoFrameSize = -1;
static NSInteger gLastAudioFrameSize = -1;
static NSTimeInterval  gLastSendVideoTime = 0;
static NSTimeInterval  gLastSendAudioTime = 0;
static NSTimeInterval  gGameStartTimeInterval = 0;
static NSString*       gParameter = nil;
static NSString*       gEnv = nil;
static NSString*       gUserId = nil;
static NSString*       gClientId = nil;
static NSString*       gGameType = nil;
static NSString*       gGameStatus = nil;
static NSMutableDictionary*  gDownloadingDic = nil;
static NSTimeInterval   gTimestampInterval = 0;
static long long int    gGPRSInitialData = 0;
static long long int    gWifiInitialData = 0;
static NSInteger        gFlowBreakCount = 0;
static NSString*        gGameId = nil;
static BOOL             gIsBroadcast = NO;

@implementation IAVideoInfo


-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.gameId = [aDecoder decodeObjectForKey:IA_gameId_key];
        self.vPath = [aDecoder decodeObjectForKey:IA_vPath_Key];
        self.imgPath = [aDecoder decodeObjectForKey:IA_imgPath_Key];
        self.uploadFlag = [aDecoder decodeObjectForKey:IA_uploadFlag_Key];
        self.videoSize = [aDecoder decodeInt64ForKey:IA_videoSize_Key];
        self.startTime = [aDecoder decodeObjectForKey:IA_startTime_Key];
        self.endTime = [aDecoder decodeObjectForKey:IA_endTime_Key];
        self.sportType = [aDecoder decodeObjectForKey:IA_sportType_Key];
        self.gameType = [aDecoder decodeObjectForKey:IA_gameType_Key];
        self.gameStatus = [aDecoder decodeObjectForKey:IA_gameStatus_Key];
        self.duration =  [aDecoder decodeDoubleForKey:IA_duration_Key];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.gameId forKey:IA_gameId_key];
    [aCoder encodeObject:self.vPath forKey:IA_vPath_Key];
    [aCoder encodeObject:self.imgPath forKey:IA_imgPath_Key];
    [aCoder encodeObject:self.uploadFlag forKey:IA_uploadFlag_Key];
    [aCoder encodeInt64:self.videoSize forKey:IA_videoSize_Key];
    [aCoder encodeObject:self.startTime forKey:IA_startTime_Key];
    [aCoder encodeObject:self.endTime forKey:IA_endTime_Key];
    [aCoder encodeObject:self.sportType forKey:IA_sportType_Key];
    [aCoder encodeObject:self.gameType forKey:IA_gameType_Key];
    [aCoder encodeObject:self.gameStatus forKey:IA_gameStatus_Key];
    [aCoder encodeDouble:self.duration forKey:IA_duration_Key];
    
}

//-(NSString*)vPath{
//    
//    NSArray* URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
//    NSURL* url = [URLs objectAtIndex:0];
//    NSString* urlStr = [url path];
//    NSRange platformTip = [_vPath rangeOfString:IA_PlatformMark_Str];
//    if (platformTip.length>0) {
//        NSString* subString = [_vPath substringFromIndex:platformTip.location];
//        urlStr = [urlStr stringByAppendingPathComponent:subString];
//        return urlStr;
//    }
//    return _vPath;
//}

//-(NSString*)imgPath{
//    NSArray* URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
//    NSURL* url = [URLs objectAtIndex:0];
//    NSString* urlStr = [url path];
//    NSRange platformTip = [_imgPath rangeOfString:IA_PlatformMark_Str];
//    if (platformTip.length>0) {
//        NSString* subString = [_imgPath substringFromIndex:platformTip.location];
//        urlStr = [urlStr stringByAppendingPathComponent:subString];
//        return urlStr;
//    }
//    return _imgPath;
//}

@end


@implementation IAGameInfo


-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.gameId = [aDecoder decodeObjectForKey:IA_gameId_key];
        self.uploadFlag = [aDecoder decodeObjectForKey:IA_uploadFlag_Key];
        self.videoSize = [aDecoder decodeIntegerForKey:IA_videoSize_Key];
        self.gameStatus = [aDecoder decodeObjectForKey:IA_gameStatus_Key];
        self.gameType = [aDecoder decodeObjectForKey:IA_gameType_Key];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.gameId forKey:IA_gameId_key];
    [aCoder encodeObject:self.uploadFlag forKey:IA_uploadFlag_Key];
    [aCoder encodeInteger:self.videoSize forKey:IA_videoSize_Key];
    [aCoder encodeObject:self.gameStatus forKey:IA_gameStatus_Key];
    [aCoder encodeObject:self.gameType forKey:IA_gameType_Key];
}

@end


@implementation IAUtility


+(BOOL)isMoreThanIOS10{
    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (systemVersion >= 10.0){
        return YES;
    }
    return NO;
}

+(BOOL)isIphone7 {
    
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *hardwareType = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSString* iphone7cdma = @"iPhone9,1";
    NSString* iphone7gsm = @"iPhone9,3";
    if (hardwareType&&([hardwareType isEqualToString:iphone7cdma]||[hardwareType isEqualToString:iphone7gsm])) {
        return YES;
    }
    
    return NO;
}

+(BOOL)moreThanIphone6{
    CGFloat width = [UIScreen mainScreen].bounds.size.height<[UIScreen mainScreen].bounds.size.width?[UIScreen mainScreen].bounds.size.height:[UIScreen mainScreen].bounds.size.width;
    if (width>=375) {
        return YES;
    }
    return NO;
}

+ (int)convertToInt:(NSString*)strtemp
{
    int strlength = 0;
    char* p = (char*)[strtemp cStringUsingEncoding:NSUnicodeStringEncoding];
    for (int i=0 ; i<[strtemp lengthOfBytesUsingEncoding:NSUnicodeStringEncoding] ;i++) {
        if (*p) {
            p++;
            strlength++;
        }
        else {
            p++;
        }
        
    }
    return strlength;
}

+ (NSString*)abstractStrForStreaming:(NSString*)sourceStr subLength:(float*)suLength{
    
    NSArray* upercaseArray = [NSArray arrayWithObjects:@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z", nil];
    NSInteger maxLen = 14;
    NSString* resultStr = sourceStr;
    float strlength = 0;
    NSInteger offset = 0;
    char* p = (char*)[sourceStr cStringUsingEncoding:NSUnicodeStringEncoding];
    for (int i=0 ; i<[sourceStr lengthOfBytesUsingEncoding:NSUnicodeStringEncoding] ;i++) {
        
        if (*p) {
            if ([upercaseArray containsObject:[NSString stringWithCString:p encoding:NSUTF8StringEncoding]]) {
                strlength+=1.5;
            }else{
                strlength++;
            }
            
            *suLength = strlength;
            if (strlength>maxLen) {
                resultStr = [sourceStr substringToIndex:offset];
                break;
            }
            
            p++;
            if ((i%2==0)&&(strlength<maxLen)) {
                offset++;
            }
            
            
        }
        else {
            p++;
        }
        
    }
    
    NSLog(@"resultStrresultStr :%@",resultStr);
    return resultStr;
}



+(NSMutableArray*)allAlbumVideos{
    
    NSMutableArray* assets = [[NSMutableArray alloc] init];
    ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
    
    UIImage *viewImage;
    
    [library writeImageToSavedPhotosAlbum:[viewImage CGImage] orientation:(ALAssetOrientation)[viewImage imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error){
        if (error) {
            NSLog(@"error");
        } else {
            NSLog(@"url %@", assetURL);
            
            NSData* urlData = [[NSData alloc] initWithContentsOfURL:assetURL];
            NSLog(@"urlDataLen :%d",[urlData length]);
            
        }
    }];
    
    
    [library enumerateGroupsWithTypes:ALAssetsGroupAll  usingBlock:^(ALAssetsGroup *group, BOOL *stop){
        
        if (group != NULL) {
            
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop){
                
                
                if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
                    NSLog(@"asset: %@", result);
                    [assets addObject:result];
                }
                
            }];
        }
        
    }
                         failureBlock:^(NSError *error){
                             
                             NSLog(@"failure");
                         }];
    
    return assets;
    
}

+(NSInteger)getVideoIndexWithPath:(NSString*)videoPath{
    if (videoPath) {
        NSString* lastComponent = [[videoPath lastPathComponent] stringByDeletingPathExtension];
        NSString* markStr =  @"_";
        if (lastComponent) {
            NSRange firstRange = [lastComponent rangeOfString:markStr];
            if (firstRange.length>0) {
                if ([lastComponent length]>(firstRange.location+1)) {
                    lastComponent = [lastComponent substringFromIndex:(firstRange.location+1)];
                    NSString* lastMarkStr = @"_i";
                    if (lastComponent) {
                        NSRange lastMarkRange = [lastComponent rangeOfString:lastMarkStr];
                        if (lastMarkRange.length>0) {
                            lastComponent = [lastComponent substringToIndex:lastMarkRange.location];
                            if (lastComponent) {
                                NSRange markRange = [lastComponent rangeOfString:markStr];
                                if (markRange.length>0) {
                                    if ([lastComponent length]>(markRange.location+1)) {
                                        lastComponent = [lastComponent substringFromIndex:(markRange.location+1)];
                                        return [lastComponent integerValue];
                                    }
                                }
                            }
                        }
                    }
                    
                }
                
            }
        }
    }
    return 0;
}

+ (double) appTotalAvaiableMemory{
    struct statfs buf;
    long long freespace = -1;
    if(statfs("/var", &buf) >= 0){
        freespace = (long long)(buf.f_bsize * buf.f_bfree);
    }
    
    double result = freespace/1024/1024 - 200;
    result =  result>=0?result:0;
    
    return result;
    // return [NSString stringWithFormat:@"%qi MB" ,freespace/1024/1024];
}
//+(NSURL*)cacheFileDirectory{
//    
//    NSArray* URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
//    NSURL* url = [URLs objectAtIndex:0];
//    url = [url URLByAppendingPathComponent:IA_PlatformMark_Str isDirectory:YES];
//    BOOL isDir = YES;
//    if (![[NSFileManager defaultManager] fileExistsAtPath:[url absoluteString] isDirectory:&isDir]) {
//        [[NSFileManager defaultManager] createDirectoryAtPath:[url path] withIntermediateDirectories:YES attributes:nil error:nil];
//    }else{
//    }
//    return url;
//}
+(NSString*)rootRecordConfigKey{
    NSString* userId = [IAUtility userId];
    if (userId) {
        return  [NSString stringWithFormat:@"%@%@_",gKeyStr,userId];
    }
    return gKeyStr;
}
+(NSString*)gameInfoKey:(NSString*)gameId{
    NSString* gameInfo = @"gameInof";
    NSString* userId = [IAUtility userId];
    if (userId) {
        return  [NSString stringWithFormat:@"%@%@%@_",gameInfo,userId,gameId];
    }
    return gameInfo;
}
static NSString* gameInfo = @"scoreInfo";

+(NSString*)homeScoreKey:(NSString*)gameId{

    if (gameId) {
        return  [NSString stringWithFormat:@"%@%@_home",gameInfo,gameId];
    }
    return [NSString stringWithFormat:@"%@_home",gameInfo];
}
+(NSString*)guestSocreKey:(NSString*)gameId{

    if (gameId) {
        return  [NSString stringWithFormat:@"%@%@_guest",gameInfo,gameId];
    }
    return [NSString stringWithFormat:@"%@_guest",gameInfo];
}

+(NSString*)recordConfigKey:(NSString*)gameId{
    assert(gameId);
    NSString* userId = [IAUtility userId];
    if (userId) {
        return  [NSString stringWithFormat:@"%@%@_%@",gKeyStr,userId,gameId];
    }
    return [NSString stringWithFormat:@"%@%@",gKeyStr,gameId];
}

+(NSString*)currentDate{
    
    NSString* formatter =  @"yyyy-MM-dd";
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:formatter];
    NSString* destDateString = [dateFormatter stringFromDate:[NSDate date]];
    return destDateString;
}

+(NSString*)currentTime{
    
    NSString* formatter =  @"HH:mm:ss";
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:formatter];
    NSString* destDateString = [dateFormatter stringFromDate:[NSDate date]];
    return destDateString;
}

+(NSString*)currentExactTime{
    
    NSString* formatter =  @"yyyy-MM-dd HH:mm:ss";
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:formatter];
    NSString* destDateString = [dateFormatter stringFromDate:[NSDate date]];
    return destDateString;
}
+(NSDate*)convertDateFromString:(NSString*)dateString formatter:(NSString*)formatter
{
    NSDateFormatter* dataFormatter = [[NSDateFormatter alloc] init] ;
    [dataFormatter setDateFormat:formatter];
    NSDate* date=[dataFormatter dateFromString:dateString];
    return date;
}

+(void)setStillCaptureImageData:(NSData*)imageData{
    
    gImageData = imageData;
}

+(NSData*)stillCaptureImageData{
    
    return gImageData;
}

+(void)setRecordVideoStartTime:(NSString*)startTime{
    gVideoStartTime = startTime;
}

+(NSString*)recordVideoStartTime{
    return gVideoStartTime;
}

+(void)setSportType:(NSString*)sportType{
    
    gSportType = sportType;
}

+(NSString*)sportType{
    
    return gSportType;
}

+(void)setLastVideoFrameSize:(NSInteger)videoFrameSize{
    
    gLastVideoFrameSize = videoFrameSize;
}
+(NSInteger)lastVideoFrameSize{
    return  gLastVideoFrameSize;
}
+(void)setLastAudioFrameSize:(NSInteger)audioFrameSize{
    gLastAudioFrameSize = audioFrameSize;
}
+(NSInteger)lastAudioFrameSize{
    return gLastAudioFrameSize;
}
+(void)setLastVideoFrameSendTime:(NSTimeInterval)timeInterval{
    gLastSendVideoTime = timeInterval;
}
+(NSTimeInterval)lastVideoFrameSendTime{
    return gLastSendVideoTime;
}
+(void)setLastAudioFrameSendTime:(NSTimeInterval)timeInterval{
    gLastSendAudioTime = timeInterval;
}
+(NSTimeInterval)lastAudioFrameSendTime{
    return gLastSendAudioTime;
}


+(UIImage *)getImageFromVideoFile:(NSString *)videoURL{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoURL] options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(25, 600);  //  参数( 截取的秒数， 视频每秒多少帧)
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return thumb;
    
}

+(void)setGameStartTimeInterval:(NSTimeInterval)startTimeInterval{
    
    gGameStartTimeInterval = startTimeInterval;
}

+(NSTimeInterval)gameStartTimeInterval{
    
    return gGameStartTimeInterval;
}
+(void)setParameter:(NSString*)parameter{
    
    gParameter = parameter;
}
+(NSString*)parameter{
    return gParameter;
}

+(void)setEnv:(NSString*)env{
    gEnv = env;
}
+(NSString*)env{
    
    return gEnv;
}

+(void)setUserId:(NSString*)userId{
    gUserId = userId;
}
+(NSString*)userId{
    
    return gUserId;
}
+(NSString*)clientId{
    if (!gClientId) {
        gClientId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    return gClientId;
}

+(NSString*)gameId{
    
    return gGameId;
}

+(void)setGameId:(NSString*)gameId{
    
    gGameId = gameId;
}

+(void)setGameType:(NSString*)gameType{
    
    gGameType = gameType;
}

+(NSString*)gameType{
    return gGameType;
}
+(void)setGameStatus:(NSString*)gameStatus gameId:(NSString*)gameId{
    gGameStatus = gameStatus;
    [[NSUserDefaults standardUserDefaults] setObject:gameStatus forKey:[self gameInfoKey:gameId]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
+(NSString*)gameStatus{
    return gGameStatus;
}

+(void)setDownloadingMark:(NSString*)gameId{
    if (!gDownloadingDic) {
        gDownloadingDic = [[NSMutableDictionary alloc] init];
    }
    [gDownloadingDic setObject:gameId forKey:gameId];
}
+(NSString*)downloadingMark:(NSString*)gameId{
    if (gDownloadingDic) {
        return [gDownloadingDic objectForKey:gameId];
    }
    return nil;
}

+(void)IALog:(id)logInfo{
    
#ifdef IALog_Key
    NSString* string = [NSString stringWithFormat:@"%@",logInfo];
    NSLog(string,nil);
#else
#endif
    
}

+(NSTimeInterval)startTimestampInterval{
    return gTimestampInterval;
}
+(void)setStartTimestampInterval:(NSTimeInterval)startTimestampInterval{
    gTimestampInterval = startTimestampInterval;
}

+(unsigned long long) getGprsFlowBytes
{
    struct ifaddrs *ifa_list = 0, *ifa;
    if (getifaddrs(&ifa_list) == -1)
    {
        return 0;
    }
    
    uint32_t iBytes = 0;
    uint32_t oBytes = 0;
    
    for (ifa = ifa_list; ifa; ifa = ifa->ifa_next)
    {
        if (AF_LINK != ifa->ifa_addr->sa_family)
            continue;
        
        if (!(ifa->ifa_flags & IFF_UP) && !(ifa->ifa_flags & IFF_RUNNING))
            continue;
        
        if (ifa->ifa_data == 0)
            continue;
        
        if (!strcmp(ifa->ifa_name, "pdp_ip0"))
        {
            struct if_data *if_data = (struct if_data *)ifa->ifa_data;
            
            iBytes += if_data->ifi_ibytes;
            oBytes += if_data->ifi_obytes;
            NSLog(@"%s :iBytes is %d, oBytes is %d",
                  ifa->ifa_name, iBytes, oBytes);
        }
    }
    freeifaddrs(ifa_list);
    
    return iBytes + oBytes;
}

+ (unsigned long long)getWifiBytes
{
    struct ifaddrs *ifa_list = 0, *ifa;
    if (getifaddrs(&ifa_list) == -1)
    {
        return 0;
    }
    
    uint32_t iBytes = 0;
    uint32_t oBytes = 0;
    
    for (ifa = ifa_list; ifa; ifa = ifa->ifa_next)
    {
        if (AF_LINK != ifa->ifa_addr->sa_family)
            continue;
        
        if (!(ifa->ifa_flags & IFF_UP) && !(ifa->ifa_flags & IFF_RUNNING))
            continue;
        
        if (ifa->ifa_data == 0)
            continue;
        
        /* Not a loopback device. */
        if (strncmp(ifa->ifa_name, "lo", 2))
        {
            struct if_data *if_data = (struct if_data *)ifa->ifa_data;
            
            iBytes += if_data->ifi_ibytes;
            oBytes += if_data->ifi_obytes;
            
            //            NSLog(@"%s :iBytes is %d, oBytes is %d",
            //                  ifa->ifa_name, iBytes, oBytes);
        }
    }
    freeifaddrs(ifa_list);
    
    return iBytes+oBytes;
}

+(NSString *)bytesToAvaiUnit:(unsigned long long)bytes
{
    if(bytes < 1024)     // B
    {
        return [NSString stringWithFormat:@"%lluB", bytes];
    }
    else if(bytes >= 1024 && bytes < 1024 * 1024) // KB
    {
        return [NSString stringWithFormat:@"%.1fKB", (double)bytes / 1024];
    }
    else if(bytes >= 1024 * 1024 && bytes < 1024 * 1024 * 1024)   // MB
    {
        return [NSString stringWithFormat:@"%.2fMB", (double)bytes / (1024 * 1024)];
    }
    else    // GB
    {
        return [NSString stringWithFormat:@"%.3fGB", (double)bytes / (1024 * 1024 * 1024)];
    }  
}


+(void)setGPRSInitialData:(unsigned long long)initialData{
    
    gGPRSInitialData = initialData;
}
+(unsigned long long)gPRSInitialData{
    return gGPRSInitialData;
}
+(void)setWifiInitialData:(unsigned long long)initialData{
    gWifiInitialData = initialData;
}
+(unsigned long long)wifigPRSInitialData{
    return gWifiInitialData;
}

+(void)setFlowBreakCount:(NSInteger)breakCount{
    gFlowBreakCount = breakCount;
}
+(NSInteger)flowBreakCount{
    return gFlowBreakCount;
}

+(void)configOSSParameter:(BOOL)debug{
    
    if (debug) {
       IA_EndPoint   =   @"http://oss-cn-beijing.aliyuncs.com/";
       IA_BucketName  =   @"smart-video";
        IA_OSS_Path    =  @"http://smart-video.oss-cn-beijing.aliyuncs.com/game/gpgameraw/%@";
    }else{
        IA_EndPoint   =   @"http://oss-cn-hangzhou.aliyuncs.com/";
        IA_BucketName  =   @"smart-videos";
        IA_OSS_Path    =  @"http://smart-videos.oss-cn-hangzhou.aliyuncs.com/game/gpgameraw/%@";
    }
    
}

+(void)setIsBroadcast:(BOOL)isBroadcast{
    gIsBroadcast = isBroadcast;
}
+(BOOL)isBroadcast{
    return gIsBroadcast;
}

+(NSString*)homeTeamWonderfullEventSequenceNumberKey:(NSString*)gameId{
    
    NSString* gameInfo = @"homeTeam";
    NSString* userId = [IAUtility userId];
    if (userId) {
        return  [NSString stringWithFormat:@"%@%@%@_",gameInfo,userId,gameId];
    }
    return [NSString stringWithFormat:@"%@%@_",gameInfo,gameId];
}
+(NSString*)guestTeamWonderfullEventSequenceNumberKey:(NSString*)gameId{
    
    NSString* gameInfo = @"guestTeam";
    NSString* userId = [IAUtility userId];
    if (userId) {
        return  [NSString stringWithFormat:@"%@%@%@_",gameInfo,userId,gameId];
    }
    return [NSString stringWithFormat:@"%@%@_",gameInfo,gameId];
}

+(NSString*)activityWonderfullEventSequenceNumberKey:(NSString*)gameId{
    
    NSString* gameInfo = @"activityWonderfull";
    NSString* userId = [IAUtility userId];
    if (userId) {
        return  [NSString stringWithFormat:@"%@%@%@_",gameInfo,userId,gameId];
    }
    return [NSString stringWithFormat:@"%@%@_",gameInfo,gameId];
}


+(BOOL)doesWaterMarkFileExist{
    
    BOOL result ;
    NSString* cachedWaterMarkFilePath = [[self cacheWaterMarkImagePath] path];
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachedWaterMarkFilePath isDirectory:&result]) {
        return  YES;
    }
    return NO;
}

+(void)storeWaterMarkImageWithUrl:(NSString*)imageUrl{
    
    if (!imageUrl || ([imageUrl length]<=0)) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),  ^{
        BOOL result = [[NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]]  writeToURL:[IAUtility cacheWaterMarkImagePath] atomically:YES];
        if (!result) {
            NSLog(@"store watermark failure");
        }
    });
}



+(NSURL*)cacheWaterMarkImagePath{
    
    NSArray* URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL* url = [URLs objectAtIndex:0];
    url = [url URLByAppendingPathComponent:@"videoWMDir" isDirectory:YES];
    BOOL isDir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:[url absoluteString] isDirectory:&isDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[url path] withIntermediateDirectories:YES attributes:nil error:nil];
    }else{
    }
    url = [url URLByAppendingPathComponent:@"waterMark.png" isDirectory:NO];
    return url;
}

@end
