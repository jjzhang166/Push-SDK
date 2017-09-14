//
//  NSData+PHLEncode.h
//  anchor
//
//  Created by yu on 16/6/3.
//  Copyright © 2016年 PAJK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (PHLEncode)
#pragma mark - MD5
- (NSData *)phl_md5Digest;
- (NSString *)phl_md5String;

#pragma mark - sha1Digest
- (NSData *)phl_sha1Digest;

#pragma mark - 转成16位形式
- (NSString *)phl_hexStringValue;

#pragma mark - 64位编码和解码
- (NSString *)phl_base64Encoded;
- (NSData *)phl_base64Decoded;

@end
