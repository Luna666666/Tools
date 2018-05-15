//
//  AVMRequestEncryption.m
//  AVM
//
//  Created by sunzongtang on 2017/7/3.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import "AVMRequestEncryption.h"
#import "AVMRequestBaseModel.h"

#import "NSString+YYAdd.h"
#import "NSData+YYAdd.h"
#import "AVMEncryptionHelp.h"


static NSString *AVMJoinParams(NSDictionary *params) {
    NSMutableArray *joinArray = [NSMutableArray arrayWithCapacity:params.allKeys.count];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];
    for (id nestedKey in [params.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
        id nestedValue = params[nestedKey];
        if (nestedValue && [nestedKey isNotBlank]) {
            NSString *tString = [NSString stringWithFormat:@"%@=%@",[nestedKey lowercaseString],nestedValue];
            [joinArray addObject:tString];
        }
    }
    return [joinArray componentsJoinedByString:@"&"];
}

static NSString *AVMSignEncryption(NSMutableDictionary *params) {
    NSString *tEncryption = AVMJoinParams(params);
    tEncryption = [NSString stringWithFormat:@"%@&key=%@",tEncryption,kAVMSignParamsKey];
    
    //    AES -> base64 -> md5 -> uppercase
    NSString *signParamsStr = [[AES256EncryptWithKey(tEncryption, kAVMAES256Key) base64EncodedString].md5String uppercaseString];
    
    return signParamsStr;
}

@implementation AVMRequestEncryption

+ (NSDictionary *)signEncryption:(NSMutableDictionary *)params {
    NSMutableDictionary *signDict = [params mutableCopy];
    
    NSString *timestamp = [NSString stringWithFormat:@"%ld", (long)([[NSDate date] timeIntervalSince1970] *1000)];
    signDict[@"timestamp"] = timestamp;
    
    return @{@"timestamp":timestamp,
             @"sign":AVMSignEncryption(signDict)};
}

@end
