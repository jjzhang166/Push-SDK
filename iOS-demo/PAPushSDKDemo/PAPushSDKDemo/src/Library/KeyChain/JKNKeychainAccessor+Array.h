//
//  JKNKeychainAccessor+Array.h
//  JKNFoundation
//
//  Created by S Q on 13-4-3.
//
//

#import "JKNKeychainAccessor.h"

@interface JKNKeychainAccessor (JKNArray)

+ (BOOL) addToKeychainUsingName:(NSString *) name andArray:(NSArray *) array andServiceName:(NSString *) serviceName error:(NSError **) error;

+ (NSArray *) arrayForName:(NSString *) name andServiceName:(NSString *) serviceName error:(NSError **) error;

@end
