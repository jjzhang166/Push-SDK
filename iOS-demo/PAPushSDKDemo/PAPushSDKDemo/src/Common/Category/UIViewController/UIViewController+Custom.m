//
//  UIViewController+Custom.m
//  PAPersonalDoctor
//
//  Created by wangweishun on 1/19/15.
//  Copyright (c) 2015 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#import "UIViewController+Custom.h"
#import "AppDelegate.h"
//#import "MJPhotoBrowser.h"
//#import "PDMineViewController.h"
//#import "PDScanViewController.h"


//#import "HPMainViewController.h"

const char rightBarButton;

@implementation UIViewController (Custom)

- (void)useDefaultColor
{
     self.view.backgroundColor = [UIColor jkn_colorWithHex:0xeaeff1];
}

- (void)useiOS7BeforeStyle
{
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)titleForController:(NSString *)title
{
    self.title = title;
#if 0
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 280, 20)];
    titleLabel.font = [UIFont boldSystemFontOfSize:17];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.text = title;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.backgroundColor = [UIColor clearColor];
    [titleLabel sizeToFit];
    self.navigationItem.titleView = titleLabel;
#endif
}

- (void)setBackBarButtonItem
{
    if (![self isKindOfClass:[[self.navigationController.viewControllers objectAtIndex:0] class]]) {
        [self setBackBarButtonItemWithImageName:@"system_icon_back"];
    }
}

- (void)setBackBarButtonItemWithImageName:(NSString *)imageName
{
    if (!imageName) {
        LogError(@"imageName 不能为空！");
        return;
    }
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [backBtn setFrame:CGRectMake(0, 0, 24, 32)];
    backBtn.imageEdgeInsets = UIEdgeInsetsMake(0, -12, 0, 0);
    [backBtn setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [backBtn setImage:[UIImage imageNamed:imageName] forState:UIControlStateHighlighted];
    [backBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
}

//返回上一页
- (void)back
{
    if ([self isKindOfClass:[[self.navigationController.viewControllers objectAtIndex:0] class]]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    [self.navigationController popViewControllerAnimated:YES];
}


- (BOOL)popToViewController:(Class)objectClass
{
    NSArray *viewControllers = [self.navigationController viewControllers];
    for (UIViewController *tempViewController in viewControllers) {
        if ([tempViewController isKindOfClass:objectClass]) {
            [self.navigationController popToViewController:tempViewController animated:YES];
            return YES;
        }
    }
    return NO;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self.navigationController pushViewController:viewController animated:animated];
}

- (void)setRightBarButtonWithTitle:(NSString *)title imageName:(NSString *)imageName touchBlock:(PARightBtnBlock)touchBlock
{
    UIButton *rightButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 80, 44)];
    if (imageName.length != 0) {
        UIImage *backgroundImage = [UIImage imageNamed:imageName];
        [rightButton setBackgroundImage:backgroundImage forState:UIControlStateNormal];
        rightButton.size = backgroundImage.size;
    }
    [rightButton setTitle:title forState:UIControlStateNormal];
    [rightButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [rightButton addTarget:self action:@selector(rightButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
    [rightButton sizeToFit];
    objc_setAssociatedObject(rightButton, &rightBarButton, touchBlock, OBJC_ASSOCIATION_COPY);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
}

- (void)rightButtonEvent:(id)rightButton
{
    PARightBtnBlock touchBlock = objc_getAssociatedObject(rightButton, &rightBarButton);
    if (touchBlock) {
        touchBlock();
    }
}

#pragma mark -rotate
- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - 通知相关
- (void)sendNotification:(NSString *)notificationName;
{
    [self sendNotification:notificationName userInfo:nil];
}

- (void)sendNotification:(NSString *)notificationName userInfo:(nullable id)userInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:userInfo];
}

- (void)registerNotificationObserver:(NSString *)notificationName handle:(void(^)(NSNotification *notification))handle
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReceiveNotification:) name:notificationName object:nil];
    objc_setAssociatedObject(self, (__bridge const void *)(notificationName), handle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)unregisterNotificationObserver:(NSString *)notificationName
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:notificationName object:nil];
    objc_setAssociatedObject(self, (__bridge const void *)(notificationName), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)handleReceiveNotification:(NSNotification *)notification
{
    void(^handle)(NSNotification *notification) = objc_getAssociatedObject(self,(__bridge const void *)(notification.name));
    if (handle != nil) {
        handle(notification);
    }
}

@end
