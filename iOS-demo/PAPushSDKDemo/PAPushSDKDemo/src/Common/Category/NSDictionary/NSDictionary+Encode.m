//
//  NSDictionary+Encode.m
//  anchor
//
//  Created by yu on 16/6/16.
//  Copyright © 2016年 PAJK. All rights reserved.
//

#import "NSDictionary+Encode.h"

@implementation NSDictionary (Encode)

- (NSString *)stringForKey:(id)key
{
    id obj = [self objectForKey:key];
    if (obj) {
        if ([obj isKindOfClass:[NSString class]])
            return (NSString *)obj;
        else if ([obj isKindOfClass:[NSNumber class]])
            return [(NSNumber *)obj stringValue];
        else if ([obj isKindOfClass:[NSNull class]])
            return @"";
    }
    return @"";
}

- (double)doubleForKey:(id)key
{
    id obj = [self objectForKey:key];
    if (obj) {
        if ([obj isKindOfClass:[NSString class]])
            return [(NSString *)obj doubleValue];
        else if ([obj isKindOfClass:[NSNumber class]])
            return [(NSNumber *)obj doubleValue];
    }
    return 0;
}

- (CGFloat)floatForKey:(id)key
{
    NSString * value = [self stringForKey:key];
    if (value.length > 0)
        return [value floatValue];
    return 0;
}

- (NSDictionary *)dictForKey:(id)key
{
    id obj = [self objectForKey:key];
    if (obj && [obj isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)obj;
    }
    return nil;
}

- (NSArray *)arrayForKey:(id)key
{
    id obj = [self objectForKey:key];
    if (obj && [obj isKindOfClass:[NSArray class]]) {
        return (NSArray *)obj;
    }
    return nil;
}

-(id) objectForCaseInsensitiveKey:(id)aKey {
    
    for (NSString *key in self.allKeys) {
        if ([key compare:aKey options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            return [self objectForKey:key];
        }
    }
    return  nil;
}

-(NSString*) jsonEncodedKeyValueString {
    
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self
                                                   options:0 // non-pretty printing
                                                     error:&error];
    if(error)
        NSLog(@"JSON Parsing Error: %@", error);
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}


-(NSString*) plistEncodedKeyValueString {
    
    NSError *error = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:self
                                                              format:NSPropertyListXMLFormat_v1_0
                                                             options:0 error:&error];
    if(error)
        NSLog(@"JSON Parsing Error: %@", error);
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
