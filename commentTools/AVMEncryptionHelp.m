//
//  AVMEncryptionHelp.m
//  AVM
//
//  Created by sunzongtang on 2017/7/7.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import "AVMEncryptionHelp.h"

#import "NSData+YYAdd.h"
#import "NSString+YYAdd.h"
#import <CommonCrypto/CommonCryptor.h>

NSString *AVMFilmPlayUrlDecrypt(NSString *encryptUrl,NSString *token) {
    NSString *tempKey = [kAVMAES256Key substringFromIndex:kAVMAES256Key.length - 16];
    NSString *sKey = [token stringByAppendingString:tempKey];
    NSData *base64EncodedData = [NSData dataWithBase64EncodedString:encryptUrl];
    NSData *decryptData = AES256DecryptWithKey(base64EncodedData, sKey);
    NSString *playUrl = [[NSString alloc] initWithData:decryptData encoding:NSUTF8StringEncoding];
    return playUrl;
}

NSString *AVMMD5(NSString *needMD5String) {
    return [needMD5String md5String];
}

NSString *AVMPayOrderDataDecrypt(NSString *encryptOrder) {
    NSData *base64EncodedData = [NSData dataWithBase64EncodedString:encryptOrder];
    NSData *decryptData = AES256DecryptWithKey(base64EncodedData, kAVMAES256Key);
    NSString *decryptStr = [[NSString alloc] initWithData:decryptData encoding:NSUTF8StringEncoding];
    return decryptStr;
}

NSData *AES256EncryptWithKey(NSString *encryptionStr, NSString *keyString) //加密
{
    NSData *encryptionData = [encryptionStr dataUsingEncoding:NSUTF8StringEncoding];
    char keyPtr[kCCKeySizeAES256 +1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    [keyString getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [encryptionData length];
    size_t bufferSize           = dataLength + kCCBlockSizeAES128;
    void  *buffer               = malloc(bufferSize);
    size_t numBytesEncrypted    = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding|kCCOptionECBMode,
                                          keyPtr,
                                          kCCKeySizeAES256,
                                          NULL ,
                                          [encryptionData bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}

NSData *AES256DecryptWithKey(NSData *decrptionData, NSString *key)   //解密
{
    char keyPtr[kCCKeySizeAES256+1 ]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength       = [decrptionData length];
    size_t bufferSize           = dataLength + kCCBlockSizeAES128;
    void  *buffer               = malloc(bufferSize);
    size_t numBytesDecrypted    = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding|kCCOptionECBMode,
                                          keyPtr,
                                          kCCKeySizeAES256,
                                          NULL ,
                                          [decrptionData bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesDecrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    free(buffer); //free the buffer;
    return nil;
    
}

@implementation AVMEncryptionHelp

@end
