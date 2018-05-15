//
//  AVMEncryptionHelp.h
//  AVM
//
//  Created by sunzongtang on 2017/7/7.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark -解密视频播放地址
extern NSString *AVMFilmPlayUrlDecrypt(NSString *encryptUrl,NSString *token);

//密码 MD5
extern NSString *AVMMD5(NSString *needMD5String);


/**
 获取订单数据界面

 @param encryptOrder <#encryptOrder description#>
 @return <#return value description#>
 */
extern NSString *AVMPayOrderDataDecrypt(NSString *encryptOrder);


#pragma mark -AES256
//aes256 加密
extern NSData *AES256EncryptWithKey(NSString *encryptionStr, NSString *keyString);
//aes256 解密
extern NSData *AES256DecryptWithKey(NSData *decrptionData, NSString *key);


@interface AVMEncryptionHelp : NSObject


@end
