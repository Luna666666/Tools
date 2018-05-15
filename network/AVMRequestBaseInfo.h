//
//  AVMRequestBaseInfo.h
//  AVM
//
//  Created by sunzongtang on 2017/6/5.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AVMRequestBaseInfo : NSObject

/**
 *  每个请求都需要添加的公共字段
 *
 *  @return <#return value description#>
 */
+ (NSDictionary*)getBaseInfoDict;



@end
