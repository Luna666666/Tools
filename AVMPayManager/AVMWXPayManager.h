//
//  AVMWXPayManager.h
//  AVM
//
//  Created by sunzongtang on 2017/8/31.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WXApi.h"

typedef NS_ENUM(NSInteger, AVMWXPayResultType) {
    AVMWXPayResultTypeSuccess = 0, //成功
    AVMWXPayResultTypeFail    = 1, //失败
};

@protocol AVMWXPayResultDelegate <NSObject>

- (void)wxPayResult:(AVMWXPayResultType) resultType error:(NSError *) error;

@end

@interface AVMWXPayManager : NSObject<WXApiDelegate>

avm_singleton_interface(AVMWXPayManager);

@property (nonatomic, weak) id<AVMWXPayResultDelegate> delegate;

@end
