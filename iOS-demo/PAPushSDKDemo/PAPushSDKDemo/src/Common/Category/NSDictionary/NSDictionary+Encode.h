//
//  NSDictionary+Encode.h
//  anchor
//
//  Created by yu on 16/6/16.
//  Copyright © 2016年 PAJK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Encode)

- (NSString *)stringForKey:(id)key;
- (double)doubleForKey:(id)key;
- (CGFloat)floatForKey:(id)key;
- (NSDictionary *)dictForKey:(id)key;
- (NSArray *)arrayForKey:(id)key;


-(id) objectForCaseInsensitiveKey:(id)aKey;
-(NSString*) urlEncodedKeyValueString;
-(NSString*) jsonEncodedKeyValueString;
-(NSString*) plistEncodedKeyValueString;

@end
