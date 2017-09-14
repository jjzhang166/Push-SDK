//
//  LogHttpRequest.h
//  WebTest
//
//  Created by wangweishun on 8/11/16.
//  Copyright © 2016 DD. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SuccessBlock)(id response);
typedef void(^FailureBlock)(NSError *error);

@interface LogHttpRequest : NSObject

// get请求
+ (void)getUrlString:(NSString *)url parameters:(id)parameters success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock;

// post请求
+ (void)postUrlString:(NSString *)url parameters:(id)parameters success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock;

// batch批量上传
+ (void)batchPostUrlString:(NSString *)url parameters:(id)parameters success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock;

@end
