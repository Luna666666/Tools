//
//  AVMRequestManager.m
//  AVM
//
//  Created by sunzongtang on 2017/7/3.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import "AVMRequestManager.h"
#import "AVMRequestUrlManager.h"

#import "AVMRequest.h"


#define kAVMPostRequest_r(url,params,rParmas,hud,rSuccess,rFailure) [AVMRequest postWithPath:(url) paramDict:(params) removeParams:(rParmas) showHUDInView:(hud) success:^(NSDictionary *resultDict, NSInteger code, NSString *msg) {\
if (rSuccess) {\
rSuccess(resultDict,code,msg);\
}\
} failure:^(NSError *error) {\
if (rFailure) {\
rFailure(error);\
}\
}];

#define kAVMPostRequest(url,params,hud,rSuccess,rFailure) [AVMRequest postWithAuthPath:(url) paramDict:(params) showHUDInView:(hud) success:^(NSDictionary *resultDict, NSInteger code, NSString *msg) {\
if (rSuccess) {\
rSuccess(resultDict,code,msg);\
}\
} failure:^(NSError *error) {\
if (rFailure) {\
rFailure(error);\
}\
}];

#define kAVMPostRequestUrl(url) kAVMPostRequest((url), params, HUDSuperView, success, failure);

@implementation AVMRequestManager

+ (void)cancelAllRequest {
    [AVMRequest cancelAllRequest];
}

#pragma mark -登录-注册 lg_
+ (void)lg_loginParamDict:(NSDictionary *)params removeParams:(NSArray *)rParmas showHUDInView:(UIView *)HUDSuperView success:(AVMResponseSuccess)success failure:(AVMResponseFailure)failure {
    kAVMPostRequest_r([[AVMRequestUrlManager shareManager] getLoginApiUrl], params,rParmas, HUDSuperView, success, failure);
}

+ (void)lg_registerParamDict:(NSDictionary *)params removeParams:(NSArray *)rParmas showHUDInView:(UIView *)HUDSuperView success:(AVMResponseSuccess)success failure:(AVMResponseFailure)failure {
    kAVMPostRequest_r([[AVMRequestUrlManager shareManager] getRegisterApiUrl], params,rParmas, HUDSuperView, success, failure);
}

#pragma mark -版本更新
+ (void)app_checkAppVerParamDict:(NSDictionary *)params showHUDInView:(UIView *)HUDSuperView success:(AVMResponseSuccess)success failure:(AVMResponseFailure)failure {
    kAVMPostRequestUrl([kAVMRequestUrlManager checkAppVerApiUrl]);
}


@end
