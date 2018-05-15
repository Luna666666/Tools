//
//  AVMRequestBaseInfo.m
//  AVM
//
//  Created by sunzongtang on 2017/6/5.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import "AVMRequestBaseInfo.h"
#import "AVMRequestBaseModel.h"
#import "YYModel.h"


@implementation AVMRequestBaseInfo

+ (NSDictionary*)getBaseInfoDict{
    AVMRequestBaseModel *requestBaseModel = [AVMRequestBaseModel defaultModel];
    NSDictionary *requestBaseDict = [requestBaseModel yy_modelToJSONObject];
    return requestBaseDict;
}



@end

