//
//  AVMRequestBaseModel.m
//  AVM
//
//  Created by sunzongtang on 2017/6/5.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import "AVMRequestBaseModel.h"
#import "AVMUserInfoModel.h"

#import "NSString+YYAdd.h"
#import "AVMUUID.h"
#import "AVMSoftInformationUtil.h"

@implementation AVMRequestBaseModel

- (NSString *)currentUserId {
    //获取userId
    _currentUserId = [AVMUserInfoModel shareUserInfoModel].userBean.userId;
    if (![_currentUserId isNotBlank]) {
        _currentUserId = [AVMUserInfoModel shareUserInfoModel].touristID;
    }
    return _currentUserId;
}

- (NSString *)loginToken {
    _loginToken = [AVMUserInfoModel shareUserInfoModel].userBean.loginToken;
    if (![_loginToken isNotBlank]) {
        _loginToken = @"";
    }
    return _loginToken;
}

- (NSString *)setupId {
    if (![_setupId isNotBlank]) {
        _setupId = [kNSUserDefaults objectForKey:@"kAVMSetupId"];
        if (![_setupId isNotBlank]) {
            _setupId = [AVMUUID getUUIDString];
            [kNSUserDefaults setObject:_setupId forKey:@"kAVMSetupId"];
            [kNSUserDefaults synchronize];
        }
    }
    return _setupId;
}


+ (instancetype)defaultModel{
    static AVMRequestBaseModel *_defaultModel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultModel = [[AVMRequestBaseModel alloc] init];
    });
    return _defaultModel;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static AVMRequestBaseModel *_defaultModel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultModel = [super allocWithZone:zone];
    });
    return _defaultModel;
}

- (instancetype)init {
    if (self = [super init]) {
        _APPVer = [AVMSoftInformationUtil getSoftVersionString];
        _APPCH = REQUEST_APP_CH;
        _APPOS = [AVMSoftInformationUtil getDeviceSystemVersion];
        
        
        _deviceModel = [AVMSoftInformationUtil getDeviceModel];
        
    }
    return self;
}

@end
