//
//  YDQuickLogin.m
//  JXPClientSideProject
//
//  Created by iOS on 2019/11/21.
//  Copyright © 2019 he. All rights reserved.
//

#import "YDQuickLogin.h"
#import <NTESQuickPass/NTESQuickPass.h>


@implementation YDQuickLogin
//快速注册，该方法需前置执行
- (BOOL)registerQuickLogin{
    self.shouldQL = [[NTESQuickLoginManager sharedInstance] shouldQuickLogin];
    if (self.shouldQL) {
        [[NTESQuickLoginManager sharedInstance] registerWithBusinessID:YDBusinessID timeout:3*1000 configURL:nil extData:nil completion:^(NSDictionary * _Nullable params, BOOL success) {
            if (success) {
                self.token = [params objectForKey:@"token"];
                self.precheckSuccess = YES;
//                [self startGetPhoneNumber];
            } else {
                self.precheckSuccess = NO;
            }
        }];
        return YES;
    }else{
        if ([[NTESQuickLoginManager sharedInstance] getCarrier]==0) {
            [MessageView showWithimage:@"" Title:@"失败" subTitle:@"手机无SIM卡"];
        }
        return NO;
    }
}

//开始取号
- (void)startGetPhoneNumber{
   if (!self.shouldQL || !self.precheckSuccess) {
       [MessageView showWithimage:@"" Title:@"失败" subTitle:@"网络异常，请检查您的网络连接后重试"];
            return;
        }
        if ([[NTESQuickLoginManager sharedInstance] getCarrier] == 1) {
            ASLog(@"电信");
            
            [SVProgressHUD showWithStatus:@"加载中..."];

            [self loginDianxin];
        } else if ([[NTESQuickLoginManager sharedInstance] getCarrier] == 2) {
            ASLog(@"移动");
            // 移动
            [SVProgressHUD showWithStatus:@"加载中..."];
            [[NTESQuickLoginManager sharedInstance] getPhoneNumberCompletion:^(NSDictionary * _Nonnull resultDic) {
                NSNumber *boolNum = [resultDic objectForKey:@"success"];
                BOOL success = [boolNum boolValue];
                if (success) {
                    [self authorizeCMLogin];
                } else {
                    [SVProgressHUD showErrorWithStatus:@"一键登录失败"];

                }
            }];
        } else {
            ASLog(@"联通");
            // 联通
            [SVProgressHUD showWithStatus:@"加载中..."];

            [[NTESQuickLoginManager sharedInstance] getPhoneNumberCompletion:^(NSDictionary * _Nonnull resultDic) {
                NSNumber *boolNum = [resultDic objectForKey:@"success"];
                BOOL success = [boolNum boolValue];
                if (success) {
                    NSLog(@"---%@",resultDic[@"desc"]);
                    [self authorizeCULogin];
                } else {
                    [SVProgressHUD showErrorWithStatus:@"一键登录失败"];

                }
            }];
        }
    }

    #pragma mark ----联通登录，获取accessToken-----
- (void)authorizeCULogin
{
    NTESQuickLoginCUModel *CUModel = [[NTESQuickLoginCUModel alloc] init];
    CUModel.currentVC = self.rootVC;
    CUModel.controllerType = NTESCUPresentController;
    CUModel.checkBoxValue= YES;
    CUModel.logoImg = kIMAGE_Name(@"Icon_logo");
    CUModel.navText = @"登录";
    CUModel.navTextColor = kWhiteColor;
    CUModel.navReturnImg = kIMAGE_Name(@"login_left");
    CUModel.swithAccHidden = YES;
    CUModel.navBgColor = kMainColor;
    CUModel.logBtnUsableBGColor = kMainColor;
    CUModel.logBtnUnusableBGColor = kRGB(204, 204, 204);
    CUModel.logBtnRadius= 24;
    CUModel.logBtnHeight = 48;
    CUModel.logBtnOffsetY =65;
    if (kISiPhoneXX) {
        CUModel.logBtnOffsetY =90;

    }
    CUModel.checkBoxOffsetY = -6;
//    CUModel.privacyTextColor = kRGBA(0, 160, 233, 1);
    CUModel.privacyColor = kMainColor;
    CUModel.logBtnText = @"本机一键登录";
    CUModel.checkBoxNormalImg = kIMAGE_Name(@"disagree");
    CUModel.checkBoxCheckedImg = kIMAGE_Name(@"login_agreed");
    
    [[NTESQuickLoginManager sharedInstance] setupCUModel:CUModel];
    [[NTESQuickLoginManager sharedInstance] CUCMAuthorizeLoginCompletion:^(NSDictionary * _Nonnull resultDic) {
        NSNumber *boolNum = [resultDic objectForKey:@"success"];
        BOOL success = [boolNum boolValue];
        if (success) {
            [SVProgressHUD dismiss];

            self.accessToken = [resultDic objectForKey:@"accessToken"];
            [self startCheck];
        } else {
            NSString *resultCode = [resultDic objectForKey:@"resultCode"];
            if ([resultCode isEqualToString:@"10104"]) {
                NSLog(@"取消登录");
                [SVProgressHUD dismiss];
            }
            if ([resultCode isEqualToString:@"10105"]) {
                NSLog(@"切换登录方式");
                [SVProgressHUD showErrorWithStatus:@"一键登录失败"];

//                [self.rootVC dismissViewControllerAnimated:YES completion:nil];
            }else{
                ASLog(@"取消登录");
                [SVProgressHUD dismiss];

//                [SVProgressHUD showErrorWithStatus:@"一键登录失败，请选择其他方式"];

            }
        }
    }];
    
    
}

- (void)authorizeCMLogin
{
    NTESQuickLoginCMModel *CMModel = [[NTESQuickLoginCMModel alloc] init];
    CMModel.currentVC = self.rootVC;
    CMModel.privacyState = YES;
    CMModel.logoImg = kIMAGE_Name(@"Icon_logo");
    CMModel.logBtnHeight = 75;
    CMModel.logBtnImgs = @[kIMAGE_Name(@"button_clickable"),kIMAGE_Name(@"button_do not click"),kIMAGE_Name(@"button_do not click")];
    CMModel.logBtnOffsetY = [NSNumber numberWithInt:322];
    CMModel.logoOffsetY = [NSNumber numberWithInt:92];
    CMModel.numberOffsetY = [NSNumber numberWithInt:206];
    CMModel.sloganOffsetY = [NSNumber numberWithInt:236];
    CMModel.logBtnHeight = 48;
    if (kISiPhoneXX) {
        CMModel.logBtnOffsetY = [NSNumber numberWithInt:381];
        CMModel.logoOffsetY = [NSNumber numberWithInt:122];
        CMModel.numberOffsetY = [NSNumber numberWithInt:236];
        CMModel.sloganOffsetY = [NSNumber numberWithInt:266];
    }
    CMModel.swithAccHidden = YES;
    CMModel.navColor = kMainColor;
    CMModel.checkboxWH = [NSNumber numberWithInt:20];
    CMModel.appPrivacyAlignment = NSTextAlignmentCenter;

    CMModel.navText = [[NSMutableAttributedString alloc] initWithString:@"登录" attributes:@{NSFontAttributeName: [UIFont fontWithName:@"PingFang SC" size: 18],NSForegroundColorAttributeName: kWhiteColor}];
    CMModel.navReturnImg = kIMAGE_Name(@"login_left");
    CMModel.logBtnText = [[NSMutableAttributedString alloc] initWithString:@"本机一键登录" attributes:@{NSFontAttributeName: kFont(16),NSForegroundColorAttributeName: kWhiteColor}];
    CMModel.uncheckedImg = kIMAGE_Name(@"disagree");
    CMModel.checkedImg = kIMAGE_Name(@"login_agreed");

    [[NTESQuickLoginManager sharedInstance] setupCMModel:CMModel];
    
    [[NTESQuickLoginManager sharedInstance] CUCMAuthorizeLoginCompletion:^(NSDictionary * _Nonnull resultDic) {
        NSNumber *boolNum = [resultDic objectForKey:@"success"];
        BOOL success = [boolNum boolValue];
        if (success) {
            [SVProgressHUD dismiss];
            self.accessToken = [resultDic objectForKey:@"accessToken"];
            [self startCheck];
        } else {
            NSString *resultCode = [resultDic objectForKey:@"resultCode"];
            if ([resultCode isEqualToString:@"200020"]) {
                NSLog(@"取消登录");
                [SVProgressHUD dismiss];

            }
            if ([resultCode isEqualToString:@"200060"]) {
                NSLog(@"切换登录方式");
                [SVProgressHUD showErrorWithStatus:@"一键登录失败"];

//                [self.rootVC dismissViewControllerAnimated:YES completion:nil];
                
            }else{
                ASLog(@"取消登录");
                [SVProgressHUD dismiss];

//                [SVProgressHUD showErrorWithStatus:@"一键登录失败，请选择其他方式"];
            }
        }
    }];
    
}
//电信 预取号
- (void)loginDianxin{
    [[NTESQuickLoginManager sharedInstance] getPhoneNumberCompletion:^(NSDictionary * _Nonnull resultDic) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSNumber *boolNum = [resultDic objectForKey:@"success"];
            BOOL success = [boolNum boolValue];
            if (success) {
//                self.phoneLabel.text = [resultDic objectForKey:@"securityPhone"];
                [self getDianxinNumber];
            
            } else {
    
            }
        });
    }];
}
- (void)getDianxinNumber{
    [[NTESQuickLoginManager sharedInstance] CTAuthorizeLoginCompletion:^(NSDictionary * _Nonnull resultDic) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSNumber *boolNum = [resultDic objectForKey:@"success"];
                    BOOL success = [boolNum boolValue];
                    if (success) {
                        [SVProgressHUD dismiss];
                        self.accessToken = [resultDic objectForKey:@"accessToken"];
                        [self startCheck];
                    } else {
                        [SVProgressHUD showErrorWithStatus:@"一键登录失败"];

                    }
                });
            }];
}
- (void)startCheck
{
    NSDictionary *dict = @{
                           @"accessToken":self.accessToken?:@"",
                           @"token":self.token?:@"",
    };
    [PPNetworkHelper setAFHTTPSessionManagerProperty:^(AFHTTPSessionManager *sessionManager) {
        // 请求参数
        sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/html", nil];
        sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    }];
    [PPNetworkHelper POST:[baseUrl stringByAppendingString:YDCheckUrl] parameters:dict success:^(id responseObject) {
        if ([responseObject[@"code"] integerValue]==200) {
            NSDictionary *dataDic = [NetDataTool ManagerDataWithdata:responseObject];
            NSString *codeStr = [dataDic[@"type"] componentsSeparatedByString:@"&"][0];

            if ([codeStr isEqualToString:@"success"]) {
                [kUserDefaults setObject:dataDic[@"token"] forKey:kUserToken];
                [kUserDefaults setObject:dataDic[@"clientUser"] forKey:kUserInfo];

                [SVProgressHUD showSuccessWithStatus:@"登录成功"];
                KPostNotification(KNotificationLoginStateChange, @(YES), nil);
                AppDelegate *appdelegate = (AppDelegate *)kApplication.delegate;
                NSInteger clientUserID = [dataDic[@"clientUser"][@"id"] integerValue];

                NSDictionary *dicc = @{@"clientUserId":@(clientUserID),
                  @"deviceToken":appdelegate.deviceToken
                };
                [NetDataTool POST:[baseUrl stringByAppendingString:sendDeviceTokenUrl] parameters:dicc success:^(id  _Nonnull responseObject) {
                    
                } failure:^(NSError * _Nonnull error) {
                    
                }];
             }else{
                 NSString * info = [dataDic[@"type"] componentsSeparatedByString:@"&"][1];
                 [MessageView showWithimage:@"" Title:@"一键登录失败" subTitle:info];
                 [SVProgressHUD dismiss];
                 
             }
//            NSString *phoneNum = [data objectForKey:@"phone"];
//            if (phoneNum && phoneNum.length > 0) {
//                if (self.resultBlock) {
//                    self.resultBlock(str);
//
//            }else{
//                [SVProgressHUD showErrorWithStatus:@"一键登录失败，请选择其他方式"];
//            }
        }else{
            [SVProgressHUD showErrorWithStatus:@"一键登录失败"];
        }
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [self.rootVC dismissViewControllerAnimated:YES completion:nil];
//
//        });
        
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"一键登录失败"];

    }];
    
}

@end
