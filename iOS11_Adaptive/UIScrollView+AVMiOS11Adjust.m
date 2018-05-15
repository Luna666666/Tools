//
//  UIScrollView+AVMiOS11Adjust.m
//  AVM
//
//  Created by sunzongtang on 2017/9/21.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import "UIScrollView+AVMiOS11Adjust.h"
#import <objc/runtime.h>

@implementation UIScrollView (AVMiOS11Adjust)

+ (void)load {
    Method m0_original = class_getInstanceMethod([self class], @selector(initWithFrame:));
    Method m0_new     = class_getInstanceMethod([self class], @selector(avm_iOS11_initWithFrame:));
    method_exchangeImplementations(m0_original, m0_new);
    
    Method m1_original = class_getInstanceMethod([self class], @selector(awakeFromNib));
    Method m1_new      = class_getInstanceMethod([self class], @selector(avm_iOS11_awakeFromNib));
    method_exchangeImplementations(m1_original, m1_new);
}

- (instancetype)avm_iOS11_initWithFrame:(CGRect)frame {
    if (![self isKindOfClass:[UIScrollView class]]) {
        return self;
    }
    [self avm_iOS11_initWithFrame:frame];
#ifdef __IPHONE_11_0
    if ([self respondsToSelector:@selector(setContentInsetAdjustmentBehavior:)]) {
        if (@available(iOS 11.0, *)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            // Fallback on earlier versions
        }
    }
#endif
    return self;
}

- (void)avm_iOS11_awakeFromNib {
    if (![self isKindOfClass:[UIScrollView class]]) {
        return ;
    }
    [self avm_iOS11_awakeFromNib];
    
#ifdef __IPHONE_11_0
    if ([self respondsToSelector:@selector(setContentInsetAdjustmentBehavior:)]) {
        if (@available(iOS 11.0, *)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            // Fallback on earlier versions
        }
    }
#endif
}

@end
