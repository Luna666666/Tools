//
//  AVMIPAManager.m
//  AVM
//
//  Created by sunzongtang on 2017/8/31.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import "AVMIAPManager.h"

static NSString * const receiptKey   = @"receipt";
static NSString * const productIdKey = @"product_id";
static NSString * const orderIdKey   = @"orderId";
static NSString * const sandboxKey   = @"sandbox"; //1：danbox环境；0：正式环境

static NSString * const kAVMReceiptKey = @"AVMReceiptKey";

@interface AVMIAPManager ()<SKPaymentTransactionObserver, SKProductsRequestDelegate>

@property (nonatomic, assign) BOOL goodsRequestFinished; //判断一次请求是否完成

@property (nonatomic, copy) NSString *receipt; //交易成功后拿到的一个64编码字符串 ,交易凭证
@property (nonatomic, copy) NSString *productId; //商品ID
@property (nonatomic, copy) NSString *orderId; //订单Id

@property (nonatomic, strong) NSLock *lock;

@end

@implementation AVMIAPManager

#pragma mark -public method
avm_singleton_implementation(AVMIAPManager)
- (instancetype)init {
    if (self = [super init]) {
        self.lock = [[NSLock alloc] init];
    }
    return self;
}

- (void)startManager {
    self.goodsRequestFinished = YES;
    
    /***
     内购支付两个阶段：
     1.app直接向苹果服务器请求商品，支付阶段；
     2.苹果服务器返回凭证，app向公司服务器发送验证，公司再向苹果服务器验证阶段；
     */
    
    /**
     阶段一正在进中,app退出。
     在程序启动时，设置监听，监听是否有未完成订单，有的话恢复订单。
     */
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    /**
     阶段二正在进行中,app退出。
     在程序启动时，检测本地是否有receipt文件，有的话，去二次验证。
     */
    [self checkIAPReceiptFiles];
}

- (void)stopManager {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)buyGoodsWithProductId:(NSString *)productId orderId:(NSString *)orderId{
    self.orderId = orderId;
    self.productId = productId;
    if (self.goodsRequestFinished) {
        if ([SKPaymentQueue canMakePayments]) { //用户允许app内购
            if (productId.length) {
                NSLog(@"%@商品正在请求中",productId);
                
                self.goodsRequestFinished = NO; //正在请求
                
                NSArray *product = @[productId];
                NSSet *set = [NSSet setWithArray:product];
                
                SKProductsRequest *productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:set];
                productRequest.delegate = self;
                [productRequest start];
                
            } else {
                
                NSLog(@"商品为空");
                
                [self requestResultCode:AVMIAPCodeTypeEmptyGoods error:@"商品为空"];
                self.goodsRequestFinished = YES; //完成请求
            }
            
        } else { //没有权限
            [self requestResultCode:AVMIAPCodeTypeCanNotMakePayment error:@"用户禁止应用内付费购买"];
            self.goodsRequestFinished = YES; //完成请求
        }
        
    } else {
        
        NSLog(@"上次请求还未完成，请稍等");
        [self requestResultCode:AVMIAPCodeTypeHasUnFinishedTransaction error:@"有未完成的交易，请稍等..."];
    }
}

#pragma mark SKProductsRequestDelegate 查询成功后的回调
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    NSArray *product = response.products;
    
    if (product.count == 0) {
        
        NSLog(@"无法获取商品信息，请重试");
        
        [self requestResultCode:AVMIAPCodeTypeCanNotGetProductInfromation error:@"无法获取商品信息，请重试"];
        self.goodsRequestFinished = YES; //失败，请求完成
        
    } else {
        //发起购买请求
        SKPayment *payment = [SKPayment paymentWithProduct:product[0]];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

#pragma mark SKProductsRequestDelegate 查询失败后的回调
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    
    [self requestResultCode:AVMIAPCodeTypeAppleError error:error.localizedDescription];
    self.goodsRequestFinished = YES; //失败，请求完成
}

#pragma Mark 购买操作后的回调
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(nonnull NSArray<SKPaymentTransaction *> *)transactions {
    
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing://正在交易
                [self requestResultCode:AVMIAPCodeTypePurchasing error:@"正在交易中..."];
                break;
                
            case SKPaymentTransactionStatePurchased://交易完成
                
                [self getReceipt]; //获取交易成功后的购买凭证
                
                [self saveReceipt:transaction]; //存储交易凭证
                
                [self checkIAPReceiptFiles];//把self.receipt发送到服务器验证是否有效
                
                [self completeTransaction:transaction];
                
                break;
                
            case SKPaymentTransactionStateFailed://交易失败
                
                [self failedTransaction:transaction];
                
                break;
                
            case SKPaymentTransactionStateRestored://已经购买过该商品
                
                [self restoreTransaction:transaction];
                
                break;
                
            default:
                
                break;
        }
    }
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    
    self.goodsRequestFinished = YES; //成功，请求完成
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}


- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
    NSLog(@"error :%@", [transaction.error localizedDescription]);
    
    if(transaction.error.code != SKErrorPaymentCancelled) {
        [self requestResultCode:AVMIAPCodeTypeBuyFailed error:[transaction.error localizedDescription]];
        //购买失败
    } else {
        [self requestResultCode:AVMIAPCodeTypeCancel error:@"取消了交易"];
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    self.goodsRequestFinished = YES; //失败，请求完成
}


- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    self.goodsRequestFinished = YES; //恢复购买，请求完成
}

#pragma mark 获取交易成功后的购买凭证

- (void)getReceipt {
    
    NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptUrl];
    self.receipt = [receiptData base64EncodedStringWithOptions:0];
}

#pragma mark  持久化存储用户购买凭证(这里最好还要存储当前日期，用户id等信息，用于区分不同的凭证)
-(void)saveReceipt:(SKPaymentTransaction *)transaction {

    if (!self.productId) {
        self.productId = transaction.payment.productIdentifier;
    }
//    if (!self.orderId) {
//        <#statements#>
//    }
    if (!self.receipt || !self.orderId || !self.productId) { //关闭交易
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        return;
    }
    NSDictionary *receiptDic = @{receiptKey:self.receipt,
                                 orderIdKey:self.orderId,
                                 productIdKey:self.productId,
                                 sandboxKey:@(avm_sandbox)};
    self.orderId = nil;
    self.productId = nil;
    NSMutableArray *receipts = [NSMutableArray arrayWithArray:[kNSUserDefaults objectForKey:kAVMReceiptKey]];
    [receipts addObject:receiptDic];
    
    [kNSUserDefaults setObject:receipts forKey:kAVMReceiptKey];
    [kNSUserDefaults synchronize];
}


#pragma mark -private method

#pragma mark 将存储到本地的IAP文件发送给服务端 验证receipt失败,App启动后再次验证
- (void)checkIAPReceiptFiles{
    
    NSArray *receipts = [kNSUserDefaults objectForKey:kAVMReceiptKey];
    for (NSDictionary *receiptDict in receipts) {
        [self sendReceiptToAPPServer:receiptDict];
    }
}

#pragma mark -发送receipt 给APP服务器
- (void)sendReceiptToAPPServer:(NSDictionary *)receiptDict {
    if (!receiptDict || !receiptDict[receiptKey]) {
        return;
    }
    
    kWEAKSELF;
    [AVMRequestManager pay_appstorePayCheckParamDict:receiptDict showHUDInView:nil success:^(NSDictionary *resultDict, NSInteger code, NSString *msg) {
        if (code == 1) {
            [weakSelf requestResultCode:AVMIAPCodeTypeTransactionSucceed error:@"交易成功"];
            [weakSelf removeReceipt:receiptDict];
        }else if (code == 2){//服务器错误，需要重新请求
            [weakSelf sendReceiptToAPPServer:receiptDict];
        }else {
           [weakSelf requestResultCode:AVMIAPCodeTypeBuyFailed error:msg];
            [weakSelf removeReceipt:receiptDict];
        }
    } failure:^(NSError *error) {
       [weakSelf requestResultCode:AVMIAPCodeTypeNetworkError error:@"无网络"];
    }];
}

#pragma mark -删除本地receipt
- (void)removeReceipt:(NSDictionary *)receiptDict {
    [self.lock lock];
    NSString *orderId = receiptDict[orderIdKey];
    NSMutableArray *receipts = [NSMutableArray arrayWithArray: [kNSUserDefaults objectForKey:kAVMReceiptKey]];
    [receipts enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *orderId_t = obj[orderIdKey];
        if ([orderId isEqualToString:orderId_t]) {
            [receipts removeObjectAtIndex:idx];
            *stop = YES;
        }
    }];
    [kNSUserDefaults setObject:receipts forKey:kAVMReceiptKey];
    [kNSUserDefaults synchronize];
    [self.lock unlock];
}

#pragma mark -错误信息反馈
- (void)requestResultCode:(AVMIAPCodeType)codeType error:(NSString *)errorString {
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestResultCode:error:)]) {
        [self.delegate requestResultCode:codeType error:errorString];
    }
}

@end
