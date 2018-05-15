//
//  UIScrollView+WYLRefreshExtension.h
//  BabyShot
//
//  Created by sunzongtang on 2017/3/31.
//
//

#import <UIKit/UIKit.h>

@interface UIScrollView (AVMRefreshExtension)

@property(nonatomic,assign)BOOL footerHidden;

- (void)addHeaderRefreshAndBeginRefreshing:(SEL)sel;

- (void)addHeaderRefresh:(SEL)sel;

- (void)addFooterLoadMore:(SEL)aSel;

- (void)beginRefreshing;

- (void)endHeaderRefreshing;

- (void)endFooterLoadMore;

- (void)endRefreshingAndLoadMore;


/**
 *  底部加载结束，当每页数据数 < 页限制数 隐藏底部 isHidden = YES;
 *
 */
- (void)endFooterLoadingIsHidden:(BOOL)isHidden;

- (void)removeFooter;

@end
