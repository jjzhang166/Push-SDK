//
//  JKNKeychainAccessor+QuickAccessor.h
//  PAFoundation
//
//  Created by S Q on 13-3-4.
//
//

#import "JKNKeychainAccessor.h"

@interface JKNKeychainAccessor (JKNQuickAccess)

+ (BOOL) addToKeychainUsingName:(NSString *) name andValue:(NSString *) value andServiceName:(NSString *) serviceName error:(NSError **) error;

+ (NSString *) valueForName:(NSString *) name andServiceName:(NSString *) serviceName error:(NSError **)error;

+ (BOOL) removeName:(NSString *) name andServiceName:(NSString *) serviceName error:(NSError **) error;

@end
