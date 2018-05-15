//
//  AVMKeyBoardManager.h
//  AVM
//
//  Created by sunzongtang on 2017/9/5.
//  Copyright © 2017年 WanYueLiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AVMKeyboardManager : NSObject

avm_singleton_interface(AVMKeyboardManager);

//是否自动根据调整键盘高度 ，默认YES
@property (nonatomic, assign) BOOL avmAutoAdjustKeyboardHeight;

@end
