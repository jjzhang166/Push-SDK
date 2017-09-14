//
//  UIView+HUD.m
//  PAPersonalDoctor
//
//  Created by shixiangyu on 16/3/20.
//  Copyright © 2016年 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//
#import "UIView+HUD.h"


static NSString *RI_EMPTY_BLOCK_KEY = @"com.pajk.EMPTY_BLOCK";
static NSString *RI_NETWORKERROR_KEY = @"com.pajk.NETWORKERROR_BLOCK";
static NSString *RI_NETWORKCLOSE_KEY = @"com.pajk.NETWORKCLOSE_BLOCK";
static NSString *RI_NETWORKERRORCLOSE_KEY = @"com.pajk.NETWORKERRORCLOSE_BLOCK";

@interface UIView ()

@property (nonatomic, copy) void (^emptyRetryBlock)();     // 空页面
@property (nonatomic, copy) void (^netWrokErrorRetryBlock)();// 错误页面
@property (nonatomic, copy) void (^netWrokErrorCloseBlock)();// H5 页面的关闭按钮
@property (nonatomic, copy) void (^netCloseBlock)();//   页面的关闭按钮

@end

@implementation UIView (HUD)

#pragma mark - loading页面
- (void)showHud
{
    [self showHudWithInViewCenterXOffset:0.0f centerYOffset:0.0f];
}

- (void)showHudWithInViewCenterXOffset:(CGFloat)xOffSet centerYOffset:(CGFloat)yOffSet
{
    [self removeHudInView];
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithFrame:self.bounds];
    hud.tag = HUDVIEWTAG;
    hud.removeFromSuperViewOnHide = YES;
    hud.xOffset = xOffSet;
    hud.yOffset = yOffSet;
    
    [self addSubview:hud];
    [hud show:YES];
}

- (void)showHudWithText:(NSString *)text
{
    if (text.length == 0) {
        return;
    }
    
    [self removeHudInView];
    
    MBProgressHUD *hudView = [[MBProgressHUD alloc] initWithFrame:self.bounds];
    hudView.tag = HUDVIEWTAG;
    hudView.removeFromSuperViewOnHide = YES;
    hudView.labelText = text;
    [self addSubview:hudView];
    [hudView show:YES];
}

#pragma mark - 菊花
- (void)removeHudInView
{
    MBProgressHUD *hudView = (MBProgressHUD*)[self viewWithTag:HUDVIEWTAG];
    if (hudView)
    {
        [hudView removeFromSuperview];
    }
}

- (void)showHudWithTextOnly:(NSString *)text
{
    [self showHudWithTextOnly:text afterDelay:2 block:nil];
}

- (void)showHudWithTextOnly:(NSString *)text afterDelay:(NSTimeInterval)delay
{
    [self showHudWithTextOnly:text afterDelay:delay block:nil];
}

- (void)showHudWithTextOnly:(NSString *)text block:(void(^)())block
{
    [self showHudWithTextOnly:text afterDelay:2 block:block];
}

- (void)showHudWithTextOnly:(NSString *)text afterDelay:(NSTimeInterval)delay block:(void(^)())block
{
    if (text.length == 0) {
        return;
    }
    
    [self removeHudInView];
    
    MBProgressHUD *hudView = [MBProgressHUD showHUDAddedTo:self animated:YES];
    hudView.tag = HUDVIEWTAG;
    hudView.removeFromSuperViewOnHide = YES;
    hudView.mode = MBProgressHUDModeText;
    hudView.labelText = @"";
    hudView.detailsLabelFont = [UIFont systemFontOfSize:17];
    hudView.detailsLabelText = text;
    
    hudView.completionBlock = ^(){
        if (block) {
            block ();
        }
    };
    
    [hudView hide:YES afterDelay:delay];
}

- (void)hideHud
{
    MBProgressHUD *hudView = (MBProgressHUD*)[self viewWithTag:HUDVIEWTAG];
    if (hudView) {
        [MBProgressHUD hideHUDForView:self animated:YES];
    }
}

- (void)hideHudAfterDelay:(NSTimeInterval)delay
{
    [self hideHudAfterDelay:delay blcok:nil];
}

- (void)hideHudAfterDelay:(NSTimeInterval) delay blcok:(void(^)())block
{
    MBProgressHUD *hudView = (MBProgressHUD*)[self viewWithTag:HUDVIEWTAG];
    hudView.completionBlock = ^(){
        if (block) {
            block ();
        }
    };
    if (hudView) {
        [hudView hide:YES afterDelay:delay];
    }
}

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    if (hud) {
        [hud removeFromSuperview];
        hud = nil;
    }
}

#pragma mark - 异常页面
- (void)showNoDataView
{
    [self showNoDataViewInViewWithTopEdge:75 image:[UIImage imageNamed:@"NetWorkError"] lableAText:NSLocalizedString(@"暂无内容，去别处逛逛", nil) lableBText:nil];
}

- (void)showNoDataViewInViewWithTopEdge:(CGFloat)topEdge
{
    [self showNoDataViewInViewWithTopEdge:topEdge image:[UIImage imageNamed:@"NetWorkError"] lableAText:NSLocalizedString(@"暂无内容，去别处逛逛", nil) lableBText:nil];
}

- (void)showNoDataViewInViewWithTopEdge:(CGFloat)topEdge lableAText:(NSString *)lableAString
{
    [self showNoDataViewInViewWithTopEdge:topEdge image:[UIImage imageNamed:@"NetWorkError"] lableAText:lableAString lableBText:nil];
}

- (void)showNoDataViewLableAText:(NSString *)lableAString lableBText:(NSString *)lableBString
{
    [self showNoDataViewInViewWithTopEdge:75 image:[UIImage imageNamed:@"NetWorkError"] lableAText:lableAString lableBText:lableBString];
}

- (void)showNoDataViewInViewWithTopEdge:(CGFloat)topEdge image:(UIImage *)image lableAText:(NSString *)lableAString lableBText:(NSString *)lableBString
{
    UIView *noDataViewOld = [self viewWithTag:KNODATAVIEWTAG];
    if (noDataViewOld) {
        [noDataViewOld removeFromSuperview];
    }
    
    UIView *noDataView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
    noDataView.tag = KNODATAVIEWTAG;
    noDataView.userInteractionEnabled = NO;
    noDataView.backgroundColor = [UIColor jkn_colorWithHex:0xf0f0f0];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, topEdge, 110, 110)];
    imageView.image = image;
    imageView.centerX = self.width / 2;
    [noDataView addSubview:imageView];
    
    UILabel *labelA = [UILabel creatLabelWithFrame:CGRectMake(0, imageView.bottom + 25, CGRectGetWidth(self.frame), 16) text:lableAString];
    [noDataView addSubview:labelA];
    
    if (lableBString) {
        UILabel *labelB = [UILabel creatLabelWithFrame:CGRectMake(0, labelA.bottom + 15, CGRectGetWidth(self.frame), 16) text:lableAString];
        [noDataView addSubview:labelB];
    }
    
    [self addSubview:noDataView];
}

-(void)removeNoDataView
{
    UIView *noDataView = [self viewWithTag:KNODATAVIEWTAG];
    if (noDataView) {
        [noDataView removeFromSuperview];
    }
}

- (void)showErrorViewWithRetryBlcok:(void(^)())block
{
    [self showErrorViewInViewWithTopEdge:75 image:[UIImage imageNamed:@"NetWorkError"] title:NSLocalizedString(@"网络异常，请稍后再试", @"") retryBlcok:block closeBlock: nil];
}

- (void)showErrorViewWithTopEdgeInView:(CGFloat)topEdge retryBlcok:(void(^)())block
{
    [self showErrorViewInViewWithTopEdge:topEdge image:[UIImage imageNamed:@"NetWorkError"] title:NSLocalizedString(@"网络异常，请稍后再试", @"") retryBlcok:block closeBlock:nil];
}

- (void)showErrorViewWithTopEdgeInView:(CGFloat)topEdge retryBlcok:(void(^)())block closeBlock:(void(^)())closeBlock
{
    [self showErrorViewInViewWithTopEdge:topEdge image:[UIImage imageNamed:@"NetWorkError"] title:NSLocalizedString(@"网络异常，请稍后再试", @"") retryBlcok:block closeBlock:closeBlock];
}


- (void)showErrorViewInViewWithTopEdge:(CGFloat)topEdge title:(NSString *)title retryBlcok:(void(^)())block
{
    [self showErrorViewInViewWithTopEdge:topEdge image:[UIImage imageNamed:@"NetWorkError"] title:title retryBlcok:block closeBlock:nil];
}

- (void)showErrorViewInViewWithTopEdge:(CGFloat)topEdge image:(UIImage *)image title:(NSString *)title retryBlcok:(void(^)())block closeBlock:(void(^)())closeBlock
{
    if ([self viewWithTag:KERRORVIEWTAG]) {
        return;
    }
    
    self.emptyRetryBlock = block;
    self.netCloseBlock = closeBlock;

    
    UIView *errorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
    errorView.tag = KERRORVIEWTAG;
    errorView.backgroundColor = [UIColor jkn_colorWithHex:0xf0f0f0];
    
    
    UIImageView *imageView = [[UIImageView alloc] init];
    if (self.height < 480 - 64) {
        imageView.frame = CGRectMake(0, 15, 110, 110);
    } else {
        imageView.frame = CGRectMake(0, topEdge, 110, 110);
    }
    imageView.image = image;
    imageView.centerX = errorView.width / 2;
    [errorView addSubview:imageView];

    
    UILabel *labelA= [UILabel creatLabelWithFrame:CGRectMake(0, imageView.bottom + 25, 220, 21) text:title];
    labelA.centerX = errorView.width / 2;
    [errorView addSubview:labelA];
    
    UIButton *retryButton = [UIButton creatButtonWithFrame:CGRectMake(0, labelA.bottom + 20 , 130, 40) title:NSLocalizedString(@"重新加载", @"")];
    retryButton.centerX = self.width / 2;
    [retryButton addTarget:self action:@selector(emptyRetryButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [errorView addSubview:retryButton];
    
    [self addSubview:errorView];
    
    if (closeBlock) {
        UIButton *closeButton = [UIButton creatButtonWithFrame:CGRectMake(0, 30, 30, 30) imageName:@"hls_iconRank_close"];
        closeButton.right = errorView.right - 15;
        [closeButton addTarget:self action:@selector(closeClick:) forControlEvents:UIControlEventTouchUpInside];
        
        [errorView addSubview:closeButton];
    }

}

-(void)removeErrorView
{
    UIView *noDataView = [self viewWithTag:KERRORVIEWTAG];
    if (noDataView) {
        [noDataView removeFromSuperview];
    }
}

- (void)showNetWorkErrorViewWithRetryBlcok:(void(^)())block
{
    [self showNetWorkErrorViewWithTopEdge:75 image:[UIImage imageNamed:@"NetWorkError"] title:NSLocalizedString(@"网络异常，请稍后再试", @"") retryBlcok:block closeBlock:nil];
}

- (void)showNetWorkErrorViewWithTopEdgeInView:(CGFloat)topEdge retryBlcok:(void(^)())block
{
    [self showNetWorkErrorViewWithTopEdge:topEdge image:[UIImage imageNamed:@"NetWorkError"] title:NSLocalizedString(@"网络异常，请稍后再试", @"") retryBlcok:block closeBlock: nil];
}

- (void)showNetWorkErrorViewWithTopEdgeInView:(CGFloat)topEdge retryBlcok:(void(^)())block closeBlock:(void(^)())closeBlock
{
    [self showNetWorkErrorViewWithTopEdge:topEdge image:[UIImage imageNamed:@"NetWorkError"] title:nil retryBlcok:block closeBlock:closeBlock];
}

- (void)showNetWorkErrorViewWithTopEdge:(CGFloat)topEdge title:(NSString *)title retryBlcok:(void(^)())block
{
    [self showNetWorkErrorViewWithTopEdge:topEdge image:[UIImage imageNamed:@"NetWorkError"] title:title retryBlcok:block closeBlock:nil];
}

- (void)showNetWorkErrorViewWithTopEdge:(CGFloat)topEdge image:(UIImage *)image title:(NSString *)title retryBlcok:(void(^)())block closeBlock:(void(^)())closeBlock
{
    if ([self viewWithTag:KNETWORKERRORTAG]) {
        return;
    }
    
    self.netWrokErrorRetryBlock = block;
    self.netCloseBlock = closeBlock;
    
    UIView *netWorkErrorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
    netWorkErrorView.tag = KNETWORKERRORTAG;
    netWorkErrorView.backgroundColor = [UIColor jkn_colorWithHex:0xf0f0f0];

    UIImageView *imageView = [[UIImageView alloc] init];
    if (self.height < 480 - 64) {
        imageView.frame = CGRectMake(0, 15, 110, 110);
    } else {
        imageView.frame = CGRectMake(0, topEdge, 110, 110);
    }
    imageView.image = image;
    imageView.centerX = self.width / 2;
    [netWorkErrorView addSubview:imageView];

    
    UILabel *labelA = [UILabel creatLabelWithFrame:CGRectMake(50, imageView.bottom + 25, self.width - 50 *2, 16) text:title];
    labelA.centerX = imageView.centerX;
    [netWorkErrorView addSubview:labelA];
    
    UIButton *retryButton = [UIButton creatButtonWithFrame:CGRectMake(0, labelA.bottom + 20 , 130, 40) title:NSLocalizedString(@"重新加载", @"")];
    retryButton.centerX = self.width / 2;
    [retryButton addTarget:self action:@selector(netWorkErrorRetryButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [netWorkErrorView addSubview:retryButton];
    
    [self addSubview:netWorkErrorView];
    
    
    if (closeBlock) {
        UIButton *closeButton = [UIButton creatButtonWithFrame:CGRectMake(0, 30, 30, 30) imageName:@"hls_iconRank_close"];
        closeButton.right = netWorkErrorView.right - 15;
        [closeButton addTarget:self action:@selector(closeClick:) forControlEvents:UIControlEventTouchUpInside];
        
        [netWorkErrorView addSubview:closeButton];
    }

}

- (void)showHtmlNetworkErrorRetryBlcok:(void(^)())rBlock closeBlock:(void(^)())cBlock
{
    if ([self viewWithTag:KNETWORKERRORTAG]) {
        return;
    }
    
    self.netWrokErrorRetryBlock = rBlock;
    self.netWrokErrorCloseBlock = cBlock;
    
    UIView *netWorkErrorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
    netWorkErrorView.tag = KNETWORKERRORTAG;
    netWorkErrorView.backgroundColor = [UIColor jkn_colorWithHex:0xf0f0f0];

    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 75, 110, 110)];
    imageView.image = [UIImage imageNamed:@"NetWorkError"];
    imageView.centerX = self.width / 2;
    [netWorkErrorView addSubview:imageView];

    UILabel *labelA = [UILabel creatLabelWithFrame:CGRectMake(50, imageView.bottom + 25, self.width - 50 *2, 16) text:NSLocalizedString(@"网络异常，请稍后再试", @"")];
    labelA.centerX = imageView.centerX;
    [netWorkErrorView addSubview:labelA];
    
    UIButton *retryButton = [UIButton creatButtonWithFrame:CGRectMake(0, labelA.bottom + 20 , 130, 40) title:NSLocalizedString(@"重新加载", @"")];
    retryButton.centerX = self.width / 2;
    [retryButton addTarget:self action:@selector(netWorkErrorRetryButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [netWorkErrorView addSubview:retryButton];
    
    // H5 页下的关闭按钮
    UIButton *closeButton = [UIButton creatButtonWithFrame:CGRectMake(0, retryButton.bottom + 20, 130, 40) title:NSLocalizedString(@"关闭", nil)];
    closeButton.centerX = netWorkErrorView.width / 2;
    [closeButton addTarget:self action:@selector(netWorkErrorCloseButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [netWorkErrorView addSubview:closeButton];
    
    [self addSubview:netWorkErrorView];
}

-(void)removeNetWorkView
{
    UIView *noDataView = [self viewWithTag:KNETWORKERRORTAG];
    if (noDataView) {
        [noDataView removeFromSuperview];
    }
}

- (void)removeAllErrorView
{
    [self removeErrorView];
    [self removeNoDataView];
    [self removeNetWorkView];
}

- (void)setEmptyRetryBlock:(void (^)())emptyRetryBlock
{
    objc_setAssociatedObject(self, (__bridge const void *)RI_EMPTY_BLOCK_KEY, nil, OBJC_ASSOCIATION_COPY);
    objc_setAssociatedObject(self, (__bridge const void *)RI_EMPTY_BLOCK_KEY, emptyRetryBlock, OBJC_ASSOCIATION_COPY);
}

- (void(^)())emptyRetryBlock
{
    return objc_getAssociatedObject(self, (__bridge const void *)RI_EMPTY_BLOCK_KEY);
}

- (void)setNetWrokErrorRetryBlock:(void (^)())netWrokErrorRetryBlock
{
    objc_setAssociatedObject(self, (__bridge const void *)RI_NETWORKERROR_KEY, nil, OBJC_ASSOCIATION_COPY);
    objc_setAssociatedObject(self, (__bridge const void *)RI_NETWORKERROR_KEY, netWrokErrorRetryBlock, OBJC_ASSOCIATION_COPY);
}

- (void(^)())netWrokErrorRetryBlock
{
    return objc_getAssociatedObject(self, (__bridge const void *)RI_NETWORKERROR_KEY);
}

- (void) setNetWrokErrorCloseBlock:(void (^)())netWrokErrorCloseBlock
{
    objc_setAssociatedObject(self, (__bridge const void *)RI_NETWORKERRORCLOSE_KEY, nil, OBJC_ASSOCIATION_COPY);
    objc_setAssociatedObject(self, (__bridge const void *)RI_NETWORKERRORCLOSE_KEY, netWrokErrorCloseBlock, OBJC_ASSOCIATION_COPY);
}

- (void(^)())netWrokErrorCloseBlock
{
    return objc_getAssociatedObject(self, (__bridge const void *)RI_NETWORKERRORCLOSE_KEY);
}

- (void)setNetCloseBlock:(void (^)())netCloseBlock
{
    objc_setAssociatedObject(self, (__bridge const void *)RI_NETWORKCLOSE_KEY, nil, OBJC_ASSOCIATION_COPY);
    objc_setAssociatedObject(self, (__bridge const void *)RI_NETWORKCLOSE_KEY, netCloseBlock, OBJC_ASSOCIATION_COPY);
}

- (void(^)())netCloseBlock
{
    return objc_getAssociatedObject(self, (__bridge const void *)RI_NETWORKCLOSE_KEY);
}


- (void)emptyRetryButtonAction:(UIButton *)btn
{
    if (self.emptyRetryBlock) {
        self.emptyRetryBlock();
    }
}

- (void)netWorkErrorRetryButtonAction:(UIButton *)btn
{
    if (self.netWrokErrorRetryBlock) {
        self.netWrokErrorRetryBlock();
    }
}

- (void)netWorkErrorCloseButtonAction:(UIButton *)btn
{
    if (self.netWrokErrorCloseBlock) {
        self.netWrokErrorCloseBlock();
    }
}

- (void)closeClick:(UIButton *)sender
{
    if (self.netCloseBlock) {
        self.netCloseBlock();
    }
}

+ (UILabel *)creatLabelWithFrame:(CGRect)frame text:(NSString *)text
{
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.text = text;
    label.textColor = [UIColor jkn_colorWithHex:0x999999];
    label.font = [UIFont systemFontOfSize:15.0];
    label.textAlignment = NSTextAlignmentCenter;
    return label;
}

+ (UIButton *)creatButtonWithFrame:(CGRect)frame title:(NSString *)title
{
    UIButton *button = [[UIButton alloc] initWithFrame:frame];
    [button setTitleColor:[UIColor jkn_colorWithHex:0x666666] forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:@"btn"] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:@"btnSelect"] forState:UIControlStateHighlighted];
    return button;
}

+ (UIButton *)creatButtonWithFrame:(CGRect)frame imageName:(NSString *)imageName
{
    UIButton *button = [[UIButton alloc] initWithFrame:frame];
    [button setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    return button;
}

- (void)showHudWithCustomCoverView:(CGRect)rect
{
    [self removeCoverView];
    
    UIView *contentView = [[UIView alloc] initWithFrame:rect];
    contentView.tag = KCONTENTVIEWTAG;
    [self addSubview:contentView];
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithFrame:contentView.bounds];
    hud.tag = HUDVIEWTAG;
    hud.removeFromSuperViewOnHide = YES;
    
    [contentView addSubview:hud];
    
    [hud show:YES];
}

- (void)hideHudWithCustomCoverView
{
    [self removeCoverView];
}

- (void)removeCoverView
{
    UIView *oldView = [self viewWithTag:KCONTENTVIEWTAG];
    if (oldView) {
        [oldView removeFromSuperview];
    }
}

// 处理特殊不带nav页面  右边关闭
- (void)showHudWithCloseBlock:(void(^)())closeBlock
{
    [self removeHudInView];
    
    MBProgressHUD *hudView = [[MBProgressHUD alloc] initWithFrame:self.bounds];
    hudView.tag = HUDVIEWTAG;
    hudView.removeFromSuperViewOnHide = YES;
    [self addSubview:hudView];
    
    [hudView show:YES];
    
    self.netCloseBlock = closeBlock;
    
    if (closeBlock) {
        UIButton *closeButton = [UIButton creatButtonWithFrame:CGRectMake(0, 30, 30, 30) imageName:@"hls_iconRank_close"];
        closeButton.right = hudView.right - 15;
        [closeButton addTarget:self action:@selector(closeClick:) forControlEvents:UIControlEventTouchUpInside];
        [hudView addSubview:closeButton];
    }
}

//处理特殊不带nav页面  左边返回按钮
- (void)showHudWithBackBlock:(void(^)())backBlock
{
    [self removeHudInView];
    
    MBProgressHUD *hudView = [[MBProgressHUD alloc] initWithFrame:self.bounds];
    hudView.tag = HUDVIEWTAG;
    hudView.removeFromSuperViewOnHide = YES;
    [self addSubview:hudView];
    
    [hudView show:YES];
    
    self.netCloseBlock = backBlock;
    
    if (backBlock) {
        UIButton *closeButton = [UIButton creatButtonWithFrame:CGRectMake(0, 30, 30, 30) imageName:@"system_back"];
        closeButton.left = hudView.left - 15;
        [closeButton addTarget:self action:@selector(closeClick:) forControlEvents:UIControlEventTouchUpInside];
        [hudView addSubview:closeButton];
    }
}

@end
