//
//  AVMIPAManager.h
//  AVM
//
//  Created by sunzongtang on 2017/8/31.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
// 苹果内购

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef NS_ENUM(NSInteger, AVMIAPCodeType) {
    /**
     *  苹果返回错误信息
     */
    AVMIAPCodeTypeAppleError = 0,

    /**
     *  用户禁止应用内付费购买
     */
    AVMIAPCodeTypeCanNotMakePayment = 1,
    /**
     *  商品为空
     */
    AVMIAPCodeTypeEmptyGoods = 2,
    /**
     *  无法获取产品信息，请重试
     */
    AVMIAPCodeTypeCanNotGetProductInfromation = 3,
    /**
     *  购买失败，请重试
     */
    AVMIAPCodeTypeBuyFailed = 4,
    /**
     *  用户取消交易
     */
    AVMIAPCodeTypeCancel = 5,
    
    /**
     *  有未完成的交易，稍等购买
     */
    AVMIAPCodeTypeHasUnFinishedTransaction = 6,
    /**
     * 交易成功
     */
    AVMIAPCodeTypeTransactionSucceed = 7,
    
    /**
     * 正在购买ing
     */
    AVMIAPCodeTypePurchasing = 8,
    
    /**
     *  无网络
     */
    AVMIAPCodeTypeNetworkError = 9,
};

@protocol AVMIAPRequestResultDelegate <NSObject>

- (void)requestResultCode:(AVMIAPCodeType)codeType error:(NSString *)errorString;

@end

@interface AVMIAPManager : NSObject

avm_singleton_interface(AVMIAPManager)

@property (nonatomic, weak) id<AVMIAPRequestResultDelegate> delegate;

/**
 启动工具
 */
- (void)startManager;

/**
 结束工具
 */
- (void)stopManager;

/**
 购买商品

 @param productId 商品ID app申请的
 @param orderId   订单编号
 */
- (void)buyGoodsWithProductId:(NSString *)productId orderId:(NSString *)orderId;

@end
