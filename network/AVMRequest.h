//
//  AVMRequest.h
//  AVM
//
//  Created by sunzongtang on 2017/6/5.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AVMRequestUtility.h"

@interface AVMRequest : NSObject

+ (instancetype)sharedInstance;

+ (AVMURLSessionTask *)postWithAuthPath:(NSString*)path
                             paramDict:(NSDictionary*)paramDict
                         showHUDInView:(UIView*)HUDSuperView
                               success:(AVMResponseSuccess)success
                               failure:(AVMResponseFailure)failure;

+ (AVMURLSessionTask *)postWithPath:(NSString*)path
                          paramDict:(NSDictionary*)paramDict
                       removeParams:(NSArray *)removeParams
                      showHUDInView:(UIView*)HUDSuperView
                            success:(AVMResponseSuccess)success
                            failure:(AVMResponseFailure)failure;

+ (void)cancelAllRequest;

@end
