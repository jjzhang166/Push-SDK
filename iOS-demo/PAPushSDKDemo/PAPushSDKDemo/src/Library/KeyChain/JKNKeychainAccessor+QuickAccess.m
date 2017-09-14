//
//  JKNKeychainAccessor+QuickAccessor.m
//  JKNFoundation
//
//  Created by S Q on 13-3-4.
//
//

#import "JKNKeychainAccessor+QuickAccess.h"
//#import "UtilitiesDef.h"
#import "JKNKeychainAccessor.h"

//PA_FIX_CATEGORY_BUG(JKNKeychainAccessor_JKNQuickAccess)

@implementation JKNKeychainAccessor (JKNQuickAccess)

+ (BOOL) addToKeychainUsingName:(NSString *) name andValue:(NSString *) value andServiceName:(NSString *) serviceName error:(NSError **) error
{
    BOOL result = NO;
    JKNKeychainAccessor *accessor = [[JKNKeychainAccessor alloc] initWithServiceName:serviceName];
    result = [accessor addToKeychainUsingName:name andValue:value error:error];
//    [accessor release];
    return result;
}

+ (NSString *) valueForName:(NSString *) name andServiceName:(NSString *) serviceName error:(NSError **)error
{
    NSString *value = nil;
    JKNKeychainAccessor *accessor = [[JKNKeychainAccessor alloc] initWithServiceName:serviceName];
    value = [accessor valueForName:name error:error];
//    [accessor release];
    return value;
}

+ (BOOL) removeName:(NSString *) name andServiceName:(NSString *) serviceName error:(NSError **) error
{
    BOOL result = NO;
    JKNKeychainAccessor *accessor = [[JKNKeychainAccessor alloc] initWithServiceName:serviceName];
    result = [accessor removeName:name error:error];
//    [accessor release];
    return result;
}

@end
