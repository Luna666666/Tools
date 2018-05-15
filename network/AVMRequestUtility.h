//
//  AVMRequestUtility.h
//  AVM
//
//  Created by sunzongtang on 2017/7/3.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#ifndef AVMRequestUtility_h
#define AVMRequestUtility_h

static NSString *kAVMBaseUrl = @"http://avmtest.uning.tv/avm_test/index.php";


@class NSURLSessionTask;
typedef NSURLSessionTask AVMURLSessionTask;
typedef void(^AVMResponseSuccess)(NSDictionary *resultDict,NSInteger code,NSString *msg);
typedef void(^AVMResponseFailure)(NSError *error);

#endif /* AVMRequestUtility_h */
