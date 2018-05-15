//
//  UIView+AVMExtensioniOS11.m
//  AVM
//
//  Created by sunzongtang on 2017/9/22.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import "UIView+AVMExtensioniOS11.h"
#import <objc/runtime.h>

@implementation UIView (AVMExtensioniOS11)

+ (void)load {
    Method originalMethod = class_getInstanceMethod([self class], @selector(hitTest:withEvent:));
    Method swizzleMethod = class_getInstanceMethod([self class], @selector(bm_hitTest:withEvent:));
    
    BOOL didAddMethod = class_addMethod([self class], @selector(bm_hitTest:withEvent:), method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    if (didAddMethod) {
        class_replaceMethod([self class], @selector(hitTest:withEvent:), method_getImplementation(swizzleMethod), method_getTypeEncoding(swizzleMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzleMethod);
    }
}

- (UIView *)bm_hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    __block UIView *hitView = nil;
    if (IsiOS11AndLater) {
        if ([NSStringFromClass([self class]) isEqualToString: @"_UINavigationBarContentView"]) {
            [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull tobj, NSUInteger tidx, BOOL * _Nonnull tstop) {
                if ([tobj isKindOfClass:NSClassFromString(@"_UIButtonBarStackView")]) {
                    if (CGRectContainsPoint(CGRectInset(tobj.frame, -16, 0), point)) {
                        [tobj.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull ttobj, NSUInteger ttidx, BOOL * _Nonnull ttstop) {
                            if ([ttobj isKindOfClass:NSClassFromString(@"_UITAMICAdaptorView")]) {
                                [ttobj.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull tttobj, NSUInteger tttidx, BOOL * _Nonnull tttstop) {
                                    if ([tttobj isKindOfClass:NSClassFromString(@"AVMBaseNavigationItemBarButton")]) {
                                        hitView = tttobj;
                                    }
                                }];
                            }
                        }];
                    }
                }
            }];
        }
    }
    if (!hitView) {
        hitView = [self bm_hitTest: point withEvent: event];
    }
    return hitView;
}

@end
