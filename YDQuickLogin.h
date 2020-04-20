//
//  YDQuickLogin.h
//  JXPClientSideProject
//
//  Created by iOS on 2019/11/21.
//  Copyright © 2019 he. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ResultBlock)(NSDictionary *resultDic);
@interface YDQuickLogin : NSObject

@property (copy, nonatomic) NSString *token;
@property (copy, nonatomic) NSString *accessToken;

@property (nonatomic, assign) BOOL shouldQL;
@property (nonatomic, assign) BOOL precheckSuccess;

@property (nonatomic, strong) UIViewController *rootVC; //根控制器

@property (nonatomic, copy) ResultBlock resultBlock;

//快速注册，该方法需前置执行,建议放在根控制器的ViewWillAppear方法里
- (BOOL)registerQuickLogin;

//开始取号
- (void)startGetPhoneNumber;
@end

NS_ASSUME_NONNULL_END
