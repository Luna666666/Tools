//
//  UIScrollView+WYLRefreshExtension.m
//  BabyShot
//
//  Created by sunzongtang on 2017/3/31.
//
//

#import "UIScrollView+AVMRefreshExtension.h"

#import "MJRefresh.h"

#import <objc/runtime.h>

@interface UIScrollView ()

@property (nonatomic, assign)SEL headerRefreshSel;
@property (nonatomic, assign)SEL footerLoadMoreSel;

@end

@implementation UIScrollView (WYLRefreshExtension)

- (NSArray *)pullingImages {
    NSMutableArray *pullingImages = [NSMutableArray arrayWithCapacity:16];
    for (NSInteger i = 1; i <= 12; i++) {
        UIImage *pullingImage = [UIImage imageNamed:[NSString stringWithFormat:@"loading_icon_%03ld",i]];
        [pullingImages addObject:pullingImage];
    }
    UIImage *pullingImage = [UIImage imageNamed:@"loading_icon_001"];
    for (NSInteger i = 0; i < 4; i ++) {
        [pullingImages insertObject:pullingImage atIndex:0];
    }
    return pullingImages;
}

- (NSArray *)refreshImages {
    NSMutableArray *waitingImages = [NSMutableArray arrayWithCapacity:8];
    for (NSInteger i = 1; i <= 12; i++) {
        UIImage *waitingImage = [UIImage imageNamed:[NSString stringWithFormat:@"loading_icon_%03ld",i]];
        [waitingImages addObject:waitingImage];
    }
    return waitingImages;
}
/////

//////////////////
#pragma mark -属性
- (void)setHeaderRefreshSel:(SEL)rSel {
    objc_setAssociatedObject(self, _cmd, NSStringFromSelector(rSel), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (SEL)headerRefreshSel {
    NSString *sSel = objc_getAssociatedObject(self, @selector(setHeaderRefreshSel:));
    return NSSelectorFromString(sSel);
}

- (void)setFooterLoadMoreSel:(SEL)footerLoadMoreSel {
    objc_setAssociatedObject(self, _cmd, NSStringFromSelector(footerLoadMoreSel), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (SEL)footerLoadMoreSel {
    NSString *sSel = objc_getAssociatedObject(self, @selector(setFooterLoadMoreSel:));
    return NSSelectorFromString(sSel);
}
/////////////////////

#pragma mark -添加刷新控件
- (void)addHeaderRefreshAndBeginRefreshing:(SEL)sel{
    [self addHeaderRefresh:sel];
    [self beginRefreshing];
}

- (void)addHeaderRefresh:(SEL)sel{
    MJRefreshGifHeader *gifHeader = [MJRefreshGifHeader headerWithRefreshingTarget:self refreshingAction:@selector(refreshData)];
    [gifHeader setImages:[self pullingImages] forState:MJRefreshStateIdle];
    [gifHeader setImages:@[[UIImage imageNamed:@"loading_icon_012"]] forState:MJRefreshStatePulling];
    [gifHeader setImages:[self refreshImages] forState:MJRefreshStateRefreshing];
    
    self.headerRefreshSel = sel;
    
    gifHeader.stateLabel.hidden = YES;
    gifHeader.lastUpdatedTimeLabel.hidden = YES;
    gifHeader.ignoredScrollViewContentInsetTop = -5;
    
    self.mj_header = gifHeader;
}

- (void)addFooterLoadMore:(SEL)aSel{
    MJRefreshBackGifFooter *gifFooter = [MJRefreshBackGifFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
    [gifFooter setImages:[self pullingImages] forState:MJRefreshStateIdle];
    [gifFooter setImages:@[[UIImage imageNamed:@"loading_icon_012"]] forState:MJRefreshStatePulling];
    [gifFooter setImages:[self refreshImages] forState:MJRefreshStateRefreshing];
    
    self.footerLoadMoreSel = aSel;
    
//    gifFooter.stateLabel.hidden = YES;
    
    self.mj_footer = gifFooter;
    self.mj_footer.automaticallyHidden = NO;
    self.mj_footer.hidden = YES;
}


#pragma mark -开始-结束刷新
- (void)beginRefreshing{
    [self.mj_header beginRefreshing];
}

- (void)endHeaderRefreshing{
    [self.mj_header endRefreshing];
}

- (void)endFooterLoadMore{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mj_footer endRefreshing];
    });
}

- (void)endRefreshingAndLoadMore{
    [self endHeaderRefreshing];
    [self endFooterLoadMore];
}

- (void)setFooterHidden:(BOOL)footerHidden{
    self.mj_footer.hidden = footerHidden;
}

- (BOOL)footerHidden{
    return self.mj_footer.hidden;
}

- (void)endFooterLoadingIsHidden:(BOOL)aBo{
    if (aBo) {
        self.mj_footer.hidden = aBo;
    }else{
        self.mj_footer.hidden = NO;
        [self endFooterLoadMore];
    }
}

- (void)removeFooter{
    [self.mj_footer removeFromSuperview];
    self.mj_footer = nil;
}

#pragma mark -返回刷新数据
- (void)refreshData {
    if (self.mj_footer && self.mj_footer.isRefreshing) {
        [self.mj_header endRefreshing];
        return;
    }
    if ([self.delegate respondsToSelector:self.headerRefreshSel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.delegate performSelector:self.headerRefreshSel];
#pragma clang diagnostic pop
    }
}

- (void)loadMoreData {
    if (self.mj_header && self.mj_header.isRefreshing) {
        [self.mj_footer endRefreshing];
    }
    if ([self.delegate respondsToSelector:self.footerLoadMoreSel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.delegate performSelector:self.footerLoadMoreSel];
#pragma clang diagnostic pop
    }
}

@end
