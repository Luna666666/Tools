//
//  AVMWXPayManager.m
//  AVM
//
//  Created by sunzongtang on 2017/8/31.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import "AVMWXPayManager.h"

@interface AVMWXPayManager ()

@end

@implementation AVMWXPayManager

avm_singleton_implementation(AVMWXPayManager)

#pragma mark - WXApiDelegate
- (void)onResp:(BaseResp *)resp {
    if([resp isKindOfClass:[PayResp class]]){
        //支付返回结果，实际支付结果需要去微信服务器端查询
        switch (resp.errCode) {
            case WXSuccess:
                break;
            case WXErrCodeUserCancel:
                resp.errStr = @"用户中途取消";
                break;
            case WXErrCodeCommon:
                NSLog(@"支付:retcode = %d, restr = %@",resp.errCode, resp.errStr);
                break;
            case WXErrCodeSentFail:
                NSLog(@"支付:retcode = %d, restr = %@",resp.errCode, resp.errStr);
                break;
            case WXErrCodeAuthDeny:
                NSLog(@"支付:retcode = %d, restr = %@",resp.errCode, resp.errStr);
                break;
            case WXErrCodeUnsupport:
                NSLog(@"支付:retcode = %d, restr = %@",resp.errCode, resp.errStr);
                break;
            default:
                NSLog(@"错误，retcode = %d, retstr = %@", resp.errCode,resp.errStr);
                break;
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(wxPayResult:error:)]) {
            if (resp.errCode == WXSuccess) {
                [self.delegate wxPayResult:AVMWXPayResultTypeSuccess error:nil];
            }else{
                [self.delegate wxPayResult:AVMWXPayResultTypeFail error:[NSError errorWithDomain:resp.errStr?resp.errStr:@"支付失败！" code:resp.errCode userInfo:nil]];
            }
        }
    }
}

@end
