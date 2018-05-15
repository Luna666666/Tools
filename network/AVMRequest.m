//
//  AVMRequest.m
//  AVM
//
//  Created by sunzongtang on 2017/6/5.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import "AVMRequest.h"

#import "AVMRequestBaseInfo.h"
#import "AVMRequestEncryption.h"

#import "AVMMaskView.h"

#import "NSString+YYAdd.h"
#import "AFNetworking.h"
#import <AFNetworking/AFURLResponseSerialization.h>

@interface AVMRequest ()<NSCopying>

@property(nonatomic, strong) AFHTTPSessionManager *theMainManager;

@property (nonatomic, strong) UINotificationFeedbackGenerator *errorNotiFeedBackGenerator;

@end

@implementation AVMRequest

#pragma mark - 初始化
+ (instancetype)sharedInstance
{
    static AVMRequest* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AVMRequest alloc] init];
    });
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static AVMRequest* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super allocWithZone:zone];
    });
    return instance;
}

- (id)copyWithZone:(NSZone *)zone {
    return [AVMRequest sharedInstance];
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [self createManger];
        if (IsiOS10AndLater) {
            self.errorNotiFeedBackGenerator = [[UINotificationFeedbackGenerator alloc] init];
            [self.errorNotiFeedBackGenerator prepare];
        }
    }
    return self;
}

- (void)createManger{
    _theMainManager = [[AFHTTPSessionManager alloc] init];
    _theMainManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    _theMainManager.requestSerializer.timeoutInterval = 30.f;
    
    AFJSONResponseSerializer *JSONResponseSerializer = [AFJSONResponseSerializer serializer];
    JSONResponseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html", nil];
    _theMainManager.responseSerializer = JSONResponseSerializer;
    
    //允许非权威机构颁发的证书
    _theMainManager.securityPolicy.allowInvalidCertificates = YES;
    //也不验证域名一致性
    _theMainManager.securityPolicy.validatesDomainName = NO;
    ////////////
}

+ (AFHTTPSessionManager *)mainSessionManger{
    AVMRequest *request = [self sharedInstance];
    return request.theMainManager;
}

#pragma mark -POST Method -授权
+ (AVMURLSessionTask *)postWithPath:(NSString *)path paramDict:(NSDictionary *)paramDict removeParams:(NSArray *)removeParams showHUDInView:(UIView *)HUDSuperView success:(AVMResponseSuccess)success failure:(AVMResponseFailure)failure {
    return [self POST:path paramDict:paramDict removeParams:removeParams showHUDInView:HUDSuperView success:success failure:failure];
}

+ (AVMURLSessionTask *)postWithAuthPath:(NSString *)path paramDict:(NSDictionary *)paramDict showHUDInView:(UIView *)HUDSuperView success:(AVMResponseSuccess)success failure:(AVMResponseFailure)failure {
    return [self POST:path paramDict:paramDict removeParams:nil showHUDInView:HUDSuperView success:success failure:failure];
}

#pragma mark -POST Method
/**
 POST请求
 */
+ (AVMURLSessionTask *)POST:(NSString *)path paramDict:(NSDictionary *)paramDict removeParams:(NSArray *)removeParams showHUDInView:(UIView *)HUDSuperView success:(AVMResponseSuccess)success failure:(AVMResponseFailure)failure {
    NSMutableDictionary *tDict = [NSMutableDictionary dictionaryWithDictionary:[AVMRequestBaseInfo getBaseInfoDict]];
    [tDict setValuesForKeysWithDictionary:paramDict];
    
    if (removeParams) {
        [tDict removeObjectsForKeys:removeParams];
    }
    
    //添加签名参数
    [tDict setValuesForKeysWithDictionary:[AVMRequestEncryption signEncryption:tDict]];
    
    
    //NSString *postUrl = AVMPostUrl(path);
    NSString *postUrl = path;
//    NSLog(@"urlString = %@",postUrl);
//    NSLog(@"param = %@",tDict);

    AFHTTPSessionManager *manager = [self mainSessionManger];
    
    //是否要显示loading
    AVMMaskView *maskView = nil;
    if (HUDSuperView) {
        maskView = [AVMMaskView loadFromXib];
        [maskView showInView:HUDSuperView backgroundColor:kColorWithRGBA(0, 0, 0, 0.2) delay:0.3];
    }
    kWEAKTYPE(maskView);
    
    AVMURLSessionTask *task = [manager POST:postUrl parameters:tDict progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self dealNetworkResponse:task.response responseObject:responseObject error:nil maskView:weakType_maskView success:success failure:failure];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (error) {
            NSLog(@"error: %@",error);
        }
        [self dealNetworkResponse:task.response responseObject:nil error:error maskView:weakType_maskView success:success failure:failure];
    }];
    
    return task;
}

+ (void)dealNetworkResponse:(NSURLResponse *)response responseObject:(id)responseObject error:(NSError *)error maskView:(AVMMaskView *)maskView success:(AVMResponseSuccess)success failure:(AVMResponseFailure)failure {
    
//    NSHTTPURLResponse *tResponse = (NSHTTPURLResponse*)response;
//    NSLog(@"status: %ld",tResponse.statusCode);
    
    if (maskView) {
        if ([response.URL.absoluteString containsString:@"getSquareTypeData"]) {
            [maskView hide:NO delay:0];
        }else {
            [maskView hide:YES delay:0.3];
        }
    }
    if (error) {
        if (error.code != NSURLErrorCancelled) {
            if (IsiOS10AndLater) {
                static CFAbsoluteTime lastTime = 0;
                CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
                if ((currentTime - lastTime) > 1.5) {//大于1.5秒
                    [[[self sharedInstance] errorNotiFeedBackGenerator] notificationOccurred:UINotificationFeedbackTypeError];
                    lastTime = currentTime;
                }
            }
        }
        
        if (failure) {
            failure(error);
            return;
        }
    }else {
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]){
            NSDictionary *tResDict=(NSDictionary*)responseObject;
            NSInteger code = [tResDict[@"code"] integerValue];
            NSString *msg = tResDict[@"msg"];
            if (code == -100) {
//                alertTipsString(@"退出登录-取消所有请求--返回到登录界面");
                //当返回-100时，不调用回调
//                if (success) {
//                    success(nil,-100,nil);
//                }
                [self cancelAllRequest];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kAVMNeedLoginNotification object:nil userInfo:@{@"msg":msg}];
                return;
            }
            if (success) {
                success(responseObject,code,msg);
                return;
            }
        }else{
            if (success) {
                success(nil,-1,@"服务器错误");
            }
        }
    }
    
    
//    //statusCode=401,表示token过期,重新登录
//    if (401 == tResponse.statusCode) {
//        //token过期,跳转回登录界面
//        
//        if (failure) {
//            failure(@"请重新登录");
//        }
//        return;
//    }else if (400 == tResponse.statusCode || 500 == tResponse.statusCode) {
//        //400:鉴权失败, 500:服务器错误
//        if (failure) {
//            failure(@"服务器错误, 请稍后再试");
//        }
//        return;
//    }
//    
//    if (error) {
//        if (failure) {
//            failure(@"网络不给力");
//        }
//    }else{
//        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]){
//            
//            NSDictionary *tResDict=(NSDictionary*)responseObject;
//            if (tResDict[@"code"] && (1 == [tResDict[@"code"] integerValue])) {
//                //返回数据正确
//                if (tResponse.allHeaderFields[@"Set-Cookie"]) {
//                    //                                              [FFUserInfo sharedUserInfo].cookie = tResponse.allHeaderFields[@"Set-Cookie"];
//                }
//                if (success) {
//                    success(responseObject);
//                }
//            }else{
//                //返回错误
//                if (failure){
//                    NSString *tErrMsg = tResDict[@"msg"];
//                    if (tErrMsg) {
//                        //错误提示
//                        failure(tErrMsg);
//                    }else{
//                        failure(@"服务器错误, 请稍后再试");
//                    }
//                }
//            }
//        }else{
//            if (failure) {
//                failure(@"服务器错误, 请稍后再试");
//            }
//        }
//    }
}

+ (void)cancelAllRequest{
    AFHTTPSessionManager *manager = [self mainSessionManger];
    for (NSURLSessionTask *task in manager.tasks) {
        [task cancel];
    }
}

@end
