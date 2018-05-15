//
//  AVMRequestManager.h
//  AVM
//
//  Created by sunzongtang on 2017/7/3.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVMRequestUtility.h"

//登录的时候用
/**
 登录时调用
 */
#define kAVMRequestManager_method_r(methodName) + (void)methodName##ParamDict:(NSDictionary*)params \
removeParams:(NSArray *)rParmas \
showHUDInView:(UIView*)HUDSuperView \
success:(AVMResponseSuccess)success \
failure:(AVMResponseFailure)failure;

//通用 有返回值--返回请求sessionTask --方便取消请求
#define kAVMRequestManager_method_call(methodName) + (AVMURLSessionTask *)methodName##ParamDict:(NSDictionary*)params \
showHUDInView:(UIView*)HUDSuperView \
success:(AVMResponseSuccess)success \
failure:(AVMResponseFailure)failure;
/**
 通用
 */
#define kAVMRequestManager_method(methodName) + (void)methodName##ParamDict:(NSDictionary*)params \
showHUDInView:(UIView*)HUDSuperView \
success:(AVMResponseSuccess)success \
failure:(AVMResponseFailure)failure;

@interface AVMRequestManager : NSObject

#pragma mark -取消所有请求
//取消所有请求
+ (void)cancelAllRequest;

#pragma mark -登录-注册 lg_
//登录
kAVMRequestManager_method_r(lg_login);

//注册
kAVMRequestManager_method_r(lg_register);


@end
