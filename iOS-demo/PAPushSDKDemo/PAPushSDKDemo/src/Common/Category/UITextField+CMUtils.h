//
//  UITextField+CMUtils.h
//  anchor
//
//  Created by yu on 16/5/31.
//  Copyright © 2016年 PAJK. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextField (CMUtils)

//创建textField
/**
 *@param keyboardType 键盘类型
 */
+ (id)createTextField:(NSString*)placeHolder keyBoardType:(UIKeyboardType)keyboardType delegate:(id<UITextFieldDelegate>)delegate;

@end
