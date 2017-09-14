//
//  UIViewController+Custom.h
//  PAPersonalDoctor
//
//  Created by wangweishun on 1/19/15.
//  Copyright (c) 2015 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <objc/runtime.h>

typedef void(^PARightBtnBlock)();

@interface UIViewController (Custom)

- (void)setBackBarButtonItem;
- (void)setBackBarButtonItemWithImageName:(NSString *)imageName;

- (void)back;

- (void)useDefaultColor;
- (void)useiOS7BeforeStyle;
- (void)titleForController:(NSString *)title;

- (void)setRightBarButtonWithTitle:(NSString *)title imageName:(NSString *)imageName touchBlock:(PARightBtnBlock)touchBlock;

- (BOOL)popToViewController:(Class)objectClass;

NS_ASSUME_NONNULL_BEGIN
- (void)sendNotification:(NSString *)notificationName;
- (void)sendNotification:(NSString *)notificationName userInfo:(nullable id)userInfo;
- (void)registerNotificationObserver:(NSString *)notificationName handle:(void(^)(NSNotification *notification))handle;
- (void)unregisterNotificationObserver:(NSString *)notificationName;
NS_ASSUME_NONNULL_END

@end
