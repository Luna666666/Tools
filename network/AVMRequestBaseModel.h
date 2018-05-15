//
//  AVMRequestBaseModel.h
//  AVM
//
//  Created by sunzongtang on 2017/6/5.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AVMRequestBaseModel : NSObject

@property (nonatomic,copy) NSString *APPVer;//版本号
@property (nonatomic, copy)NSString *APPCH;
@property (nonatomic,copy) NSString *APPOS;

@property (nonatomic, copy)NSString *deviceModel;
@property (nonatomic, copy)NSString *currentUserId;
@property (nonatomic, copy)NSString *loginToken;
@property (nonatomic, copy)NSString *setupId;

+ (instancetype)defaultModel;

@end
