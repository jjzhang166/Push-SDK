//
//  JKNKeychainAccessor.h
//  JKNFoundation
//
//  Created by S Q on 13-3-4.
//
//

#import <Foundation/Foundation.h>

@interface JKNKeychainAccessor : NSObject

- (id)  initWithServiceName:(NSString *) serviceName;

- (id)  initWithServiceName:(NSString *) serviceName accessGroup:(NSString *) accessGroup;

- (BOOL) addToKeychainUsingName:(NSString *) name andValue:(NSString *) value error:(NSError **) error;

- (NSString *) valueForName:(NSString *) name error:(NSError **)error;

- (BOOL) removeName:(NSString *) name error:(NSError **) error;

@end
