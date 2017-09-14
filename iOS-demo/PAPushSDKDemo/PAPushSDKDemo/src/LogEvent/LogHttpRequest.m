//
//  LogHttpRequest.m
//  WebTest
//
//  Created by wangweishun on 8/11/16.
//  Copyright © 2016 DD. All rights reserved.
//

#import "LogHttpRequest.h"

//ref: http://doc.pajk-ent.com/pages/viewpage.action?pageId=28870690

#define kTimeoutInterval 30

@implementation LogHttpRequest

+ (void)getUrlString:(NSString *)url parameters:(id)parameters success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock
{
    NSString *requestUrl = [NSString stringWithFormat:@"%@%@", url,[LogHttpRequest handleParameterWithDict:parameters]];
    LogDebug(@"url: %@", requestUrl);
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:requestUrl]];
    NSURLSession *urlSession = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:urlRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            failureBlock(error);
        } else {
            id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            successBlock(obj);
        }
    }];

    [dataTask resume];
}

+ (void)postUrlString:(NSString *)url parameters:(id)parameters success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kTimeoutInterval];
    request.HTTPMethod = @"POST";
    
    NSString *dataStr = [LogHttpRequest handleParameterWithDict:parameters];
    request.HTTPBody = [[NSString stringWithFormat:@"data=%@", dataStr] dataUsingEncoding:NSUTF8StringEncoding];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            failureBlock(error);
        } else {
            id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            successBlock(obj);
        }
    }];

    [dataTask resume];
}

+ (void)batchPostUrlString:(NSString *)url parameters:(NSArray *)parameters success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kTimeoutInterval];
    request.HTTPMethod = @"POST";

    if (0) {
//        NSString *dataStr = [LogHttpRequest handleParameterWithDict:parameters];
//        LogDebug(@"Batch dataStr: %@", dataStr);
//        NSDictionary *resultDataDic = [NSDictionary dictionaryWithObject:dataStr forKey:@"data"];
//        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:resultDataDic options:NSJSONWritingPrettyPrinted error:nil];
    } else {
         NSMutableData *body = [NSMutableData data];
        //设置表单项分隔符
        NSString *boundary = @"---------------------------1473780983146649988274664566";
        
        //设置内容类型
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
        
        //写入INFO的内容
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",@"data"] dataUsingEncoding:NSUTF8StringEncoding]];
         NSString *dataStr = [LogHttpRequest handleParameterWithDict:parameters];
        [body appendData:[dataStr dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        //写入尾部内容
        [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [request setHTTPBody:body];
    }

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session uploadTaskWithRequest:request fromData:nil completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            failureBlock(error);
        } else {
            id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            successBlock(obj);
        }
    }];
    
    [dataTask resume];
}

+ (NSString *)handleParameterWithDict:(id)parameters
{
    if (!parameters) {
        return @"";
    }

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    LogDebug(@"%@", jsonString);
    
    NSString *base64 = [LogHttpRequest base64EncodeWithString:jsonString];
    NSString *urlEncode = [LogHttpRequest urlEncodeWithString:base64];
    return urlEncode;
}

+ (NSString *)base64EncodeWithString:(NSString *)string
{
    if (!string) {
        return nil;
    }
    NSData *nsdata = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
    return base64Encoded;
}

+ (NSString *)urlEncodeWithString:(NSString *)string
{
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (__bridge CFStringRef)string,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                 CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
}

@end
