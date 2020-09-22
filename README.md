# 易盾一键登录
在易盾官方demo上进行的一些自定义改动

公司项目的一键登录功能使用的网易易盾的号码认证，做完了之后整理一下iOS端的开发流程：
## 一键登录的实现逻辑
如下图：
![易盾一键登录的交互流程图.png](https://upload-images.jianshu.io/upload_images/1431215-4e34e6d4c41dd13e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 客户端的实现流程
作为客户端开发者，我们关注的也就是上图中“应用客户端”和“易盾SDK”之间的交互，也就是步骤2，3，4，6，9，11和12。
总结简化下来也就是四步：
###### 1.本地初始化
###### 2.预取号-调取授权页
###### 3.用户点击按钮确认授权，获得Token
###### 4.用Token与服务器交互，服务器用token完成登录


**1.本地初始化**
```
//快速注册，该方法需前置执行
///YDBusinessID是你们公司从易盾拿到的busID,注意：此时的Token跟后面的accessToken不一样
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
```
第一步没什么要说的，只有一点要注意，该方法是一定是第一步执行的。

**2.预取号-调取授权页**

```
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
```
这一步要注意的点：
- 联通和移动的卡需要调起自带的授权页，这是运营商要求的，没办法省略，电信没有要求，可以省略第三步。
- 联通和移动的授权页部分界面可以自定义，但是自定义的部分不一样，所以客户端研发需要跟UI提前沟通，确定好UI。

**3.用户点击按钮确认授权，获得Token**
![联通用户授权界面](https://upload-images.jianshu.io/upload_images/1431215-4aa9efdffd67ef69.PNG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
```
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
```
**用Token与服务器交互，服务器用token完成登录**
客户端在这一步其实就基本完成了，只需要拿着第一步的token和第三步的accessToken交给后台就行了，后台返回登录信息，整个一键登录就完成了。


