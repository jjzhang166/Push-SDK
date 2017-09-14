//
//  UITextField+CMUtils.m
//  anchor
//
//  Created by yu on 16/5/31.
//  Copyright © 2016年 PAJK. All rights reserved.
//

#import "UITextField+CMUtils.h"

@implementation UITextField (CMUtils)

+ (id)createTextField:(NSString*)placeHolder keyBoardType:(UIKeyboardType)keyboardType delegate:(id<UITextFieldDelegate>)delegate
{
    UITextField *textfield = [[UITextField alloc] init];
    textfield.keyboardType = keyboardType;
    textfield.placeholder = placeHolder;
    textfield.font = [UIFont systemFontOfSize:16.0];
    textfield.delegate = delegate;
    return textfield;
}

@end
