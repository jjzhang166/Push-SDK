//
//  JKNKeychainAccessor+Array.m
//  JKNFoundation
//
//  Created by S Q on 13-4-3.
//
//

#import "JKNKeychainAccessor+Array.h"
//#import "UtilitiesDef.h"
#import "JKNKeychainAccessor+QuickAccess.h"
#import "JKNLog.h"

//PA_FIX_CATEGORY_BUG(JKNKeychainAccessor_JKNArray)

@implementation JKNKeychainAccessor (JKNArray)

+ (BOOL) addToKeychainUsingName:(NSString *) name andArray:(NSArray *) array andServiceName:(NSString *) serviceName error:(NSError **) error;
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:error];
    if (error)
    {
        LogError(@"[KeyChain] Convert array to json failed with error:%@", *error);
        return NO;
    }
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    LogDebug(@"save array as json string\n[%@] to keychain", jsonString);
    return [self addToKeychainUsingName:name andValue:jsonString andServiceName:serviceName error:error];
}

+ (NSArray *) arrayForName:(NSString *) name andServiceName:(NSString *) serviceName error:(NSError **) error
{
    NSString *jsString = [self valueForName:name andServiceName:serviceName error:error];
    if (error)
    {
        LogError(@"[KeyChain] Get array as json string from keychain failed with error:%@", *error);
        return nil;
    }
    if ([jsString length] == 0)
    {
        return nil;
    }
    NSData *data = [jsString dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *jsArr = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:error];
    return jsArr;
}

@end
