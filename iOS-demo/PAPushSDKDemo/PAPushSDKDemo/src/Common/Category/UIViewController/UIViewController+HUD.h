//
//  UIViewController+HUD.h
//  PAPersonalDoctor
//
//  Created by shixiangyu on 16/4/8.
//  Copyright © 2016年 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * 基于UIViewController的新错误页面
 */
@interface UIViewController (HUD)

/**
 *  显示loading(hud加到self上)
 */
- (void)showHud;

/**
 * 显示loading(hud加到self上),菊花 相对于父视图中心点的x轴偏移量和y轴偏移量
 *
 * @param  xOffSet   相对于父视图中心点的x轴偏移量    X轴左侧为“-”   X轴右侧为“+”
 * @param  xOffSet   相对于父视图中心点的y轴偏移量    Y轴上侧为“-”   Y轴下侧为“+”
 *
 */
- (void)showHudWithInViewCenterXOffset:(CGFloat)xOffSet centerYOffset:(CGFloat)yOffSet;

/**
 *  显示loading(菊花&文字 hud加到self上)
 *
 *  @param text  文本内容
 */
- (void)showHudWithText:(NSString *)text;

/**
 *  显示loading(只有文字 hud加到self上)
 *
 *  @param text  文本内容
 */
- (void)showHudWithTextOnly:(NSString *)text;
/**
 *
 * @param text  文本内容
 * @param block 方法回调
 *
 */
- (void)showHudWithTextOnly:(NSString *)text block:(void(^)())block;

/**
 *  显示loading(只有文字 hud加到self上)
 *
 *  @param errorCode  错误对应的 code
 */
- (void)showHudWithErrorCode:(NSInteger)errorCode;

/**
 *  结束loadingView
 */
- (void)hideHud;
- (void)hideHudAfterDelay:(NSTimeInterval) delay;
- (void)hideHudAfterDelay:(NSTimeInterval) delay blcok:(void(^)())block ;

/**
 *  添加空数据View         默认
 *
 */
- (void)showNoDataView;

/**
 *  显示空数据view        可以根据不同页面定制页面
 *  @param topEdge       距上边距离
 *
 *  @param lableAString  文本内容A
 *  @param lableBString  文本内容B
 */
- (void)showNoDataViewInViewWithTopEdge:(CGFloat)topEdge;
- (void)showNoDataViewInViewWithTopEdge:(CGFloat)topEdge lableAText:(NSString *)lableAString;
- (void)showNoDataViewLableAText:(NSString *)lableAString lableBText:(NSString *)lableBString;

/**
 *  移除空数据View
 *
 *  @param containView
 */
-(void)removeNoDataView;

/**
 *  添加错误View        默认
 *
 *  @param block       retry block
 */
- (void)showErrorViewWithRetryBlcok:(void(^)())block;

/**
 *   添加错误View       支持定制图片和文字及上边居
 *
 * @param   topEdge     居上边居
 *
 * @param   title       提示文字
 * @return retry block
 */
- (void)showErrorViewWithTopEdgeInView:(CGFloat)topEdge retryBlcok:(void(^)())block;
- (void)showErrorViewInViewWithTopEdge:(CGFloat)topEdge title:(NSString *)title retryBlcok:(void(^)())block;

/**
 *  移除错误View
 *
 */
-(void)removeErrorView;

/**
 *  添加网络异常View     默认
 *
 *  @param block       retry block
 *
 */
- (void)showNetWorkErrorViewWithRetryBlcok:(void(^)())block;

/**
 *  添加网络异常View      支持定制图片和文字及上边居
 *  @param topEdge      距上边距离
 *
 *  @param title        提示文字
 *  @param block        block
 */
- (void)showNetWorkErrorViewWithTopEdgeInView:(CGFloat)topEdge retryBlcok:(void(^)())block;
- (void)showNetWorkErrorViewWithTopEdge:(CGFloat)topEdge title:(NSString *)title retryBlcok:(void(^)())block;

/**
 *  H5 页面网络错误
 *
 * @param  rBlock   检测网络回调
 * @param  cBlock   关闭按钮回调
 *
 */
- (void)showHtmlNetworkErrorRetryBlcok:(void(^)())rBlock closeBlock:(void(^)())cBlock;

/**
 *  移除网络异常View
 *
 */
-(void)removeNetWorkView;

/**
 *  移除所有异常View
 *
 */
- (void)removeAllErrorView;

/**
 *  数据请求失败统一处理
 *
 */
//- (void)handleRequestErrorWithError:(HMError *)error dataListCount:(NSInteger)dataListCount block:(void(^)())block;

@end
