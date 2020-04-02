![mahua](http://upload-images.jianshu.io/upload_images/259-0ad0d0bfc1c608b6.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

# Tools

## Tools是什么?
一个基于Objective-C语言开发的高内聚低耦合的iOS开发工具类

向Tools的开发者Michael Chan致敬!

## Tools主要功能？

* 包含网络请求、视频播放、支付、分享等类的封装及对第三方库的封装和修改

## 更新记录
2018.5.29 -- v0.0.1:提交0.0.1版本并完成框架搭建和核心功能模块编写

## 使用方式
1.0 下载Tools直接集成到项目运行

## 注意事项
1. 熟悉Objective-C基本语法

## 相关作品

## 有问题反馈
在使用中有任何问题，欢迎反馈给我，可以用以下联系方式跟我交流
* 邮件(951123604@qq.com)
* QQ: 951123604
* weibo: [@xiaoqiang是个小疯子](https://weibo.com/p/1005055732746027/home?from=page_100505&mod=TAB#place)
* twitter: [@CharlesDing8](https://twitter.com/CharlesDing8)

## 捐助开发者
在兴趣的驱动下,写一个`免费`的东西，有欣喜，也还有汗水，希望你喜欢我的作品，同时也能支持一下。
当然，有钱捧个钱场（右上角的爱心标志，支持支付宝和PayPal捐助），没钱捧个人场，谢谢各位。

## 感激
感谢以下的项目,排名不分先后

* [mou](http://mouapp.com/) 
* [ace](http://ace.ajax.org/)
* [jquery](http://jquery.com)

# 你的Star是我更新的动力，使用过程如果有什么问题或者有什么新的建议，可以issues,我会及时回复大家！

``` objc
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

```

