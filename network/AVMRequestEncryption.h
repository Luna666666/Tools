//
//  AVMRequestEncryption.h
//  AVM
//
//  Created by sunzongtang on 2017/7/3.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AVMRequestEncryption : NSObject

+ (NSDictionary *)signEncryption:(NSMutableDictionary *)params;

@end
