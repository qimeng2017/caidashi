//
//  AppDelegate.m
//  LotteryNews
//
//  Created by 邹壮壮 on 2016/12/20.
//  Copyright © 2016年 邹壮壮. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginViewController.h"
#import "LNTabBarVC.h"
#import "WXApiManager.h"
#import "LNLottoryConfig.h"
#import "UserStore.h"
#import "LNUserInfoModel.h"
#import <AlipaySDK/AlipaySDK.h>
#import <Bugly/Bugly.h>
#import "HRSystem.h"
#import <UMMobClick/MobClick.h>
@interface AppDelegate ()<LoginViewControllerDelegate>
@property (nonatomic, strong) LNTabBarVC *LNTabBarViewController;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"ok");
    NSArray *arr = [NSArray array];
    NSLog(@"%@",[arr objectAtIndex:111]);
    [WXApi registerApp:kAuthOpenID withDescription:@"demo 2.0"];
    BuglyConfig *bugConfig = [[BuglyConfig alloc]init];
    bugConfig.blockMonitorEnable = YES;
    bugConfig.unexpectedTerminatingDetectionEnable = YES;
    bugConfig.debugMode = YES;
    [Bugly startWithAppId:kBuglyAppid config:bugConfig];
    
    UMConfigInstance.appKey = UM_appkey;
    [MobClick startWithConfigure:UMConfigInstance];
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    NSString *userID = UserDefaultObjectForKey(LOTTORY_AUTHORIZATION_UID);
    NSString *buildVersion = [HRSystem bundleVersion];
    if (userID&&UserDefaultObjectForKey(buildVersion)) {
        self.LNTabBarViewController = [[LNTabBarVC alloc] init];
        self.window.rootViewController = self.LNTabBarViewController;
    }else{
        LoginViewController *loginVC = [[LoginViewController alloc]init];
        loginVC.delegate = self;
         self.window.rootViewController = loginVC;
    }
    
    
    
    [self.window makeKeyAndVisible];
   
    return YES;
}
- (void)userLoginSucess{
    self.LNTabBarViewController = [[LNTabBarVC alloc] init];
    self.window.rootViewController = self.LNTabBarViewController;
    [self.window makeKeyAndVisible];
    NSString *buildVersion = [HRSystem bundleBuildVersion];
    UserDefaultSetObjectForKey(@"sucess", buildVersion);
    NSString *userId = UserDefaultObjectForKey(LOTTORY_AUTHORIZATION_UID);
    if (userId) {
        [[UserStore sharedInstance]requestGetUserInfoWithUserId:userId sucess:^(NSURLSessionDataTask *task, id responseObject) {
            LNUserInfoModel *model = [[LNUserInfoModel alloc]initWithDictionary:responseObject error:nil];
            UserDefaultSetObjectForKey(model.login_type, @"login_type");
           // NSLog(@"%@",responseObject);
            [LNUserInfoModel saveUserInfo:userId userInfo:model];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            //NSLog(@"%@",error);
        }];
    }
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {

    [self checkReviewTheStatus];

   
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return  [WXApi handleOpenURL:url delegate:[WXApiManager sharedManager]];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    if ([url.absoluteString hasPrefix:@"wx"]) {
        return  [WXApi handleOpenURL:url delegate:[WXApiManager sharedManager]];
    }
    //如果极简开发包不可用，会跳转支付宝钱包进行支付，需要将支付宝钱包的支付结果回传给开发包
    if ([url.host isEqualToString:@"safepay"]) {
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            //【由于在跳转支付宝客户端支付的过程中，商户app在后台很可能被系统kill了，所以pay接口的callback就会失效，请商户对standbyCallback返回的回调结果进行处理,就是在这个方法里面处理跟callback一样的逻辑】
            NSNumber *resultStatusNum = [resultDic objectForKey:@"resultStatus"];
            NSString *resultStatus = [NSString stringWithFormat:@"%@",resultStatusNum];
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlipayResultStatusNotification object:resultStatus];
        }];
    }
    if ([url.host isEqualToString:@"platformapi"]){//支付宝钱包快登授权返回authCode
        
        [[AlipaySDK defaultService] processAuthResult:url standbyCallback:^(NSDictionary *resultDic) {
            //【由于在跳转支付宝客户端支付的过程中，商户app在后台很可能被系统kill了，所以pay接口的callback就会失效，请商户对standbyCallback返回的回调结果进行处理,就是在这个方法里面处理跟callback一样的逻辑】
            NSNumber *resultStatusNum = [resultDic objectForKey:@"resultStatus"];
            NSString *resultStatus = [NSString stringWithFormat:@"%@",resultStatusNum];
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlipayResultStatusNotification object:resultStatus];
        }];
    }
    return YES;
    
}
// NOTE: 9.0以后使用新API接口
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options
{
    if ([url.absoluteString hasPrefix:@"wx"]) {
        return  [WXApi handleOpenURL:url delegate:[WXApiManager sharedManager]];
    }
    //如果极简开发包不可用，会跳转支付宝钱包进行支付，需要将支付宝钱包的支付结果回传给开发包
    if ([url.host isEqualToString:@"safepay"]) {
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            //【由于在跳转支付宝客户端支付的过程中，商户app在后台很可能被系统kill了，所以pay接口的callback就会失效，请商户对standbyCallback返回的回调结果进行处理,就是在这个方法里面处理跟callback一样的逻辑】
            NSNumber *resultStatusNum = [resultDic objectForKey:@"resultStatus"];
            NSString *resultStatus = [NSString stringWithFormat:@"%@",resultStatusNum];
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlipayResultStatusNotification object:resultStatus];
            //NSLog(@"result = %@",resultDic);
        }];
    }
    if ([url.host isEqualToString:@"platformapi"]){//支付宝钱包快登授权返回authCode
        
        [[AlipaySDK defaultService] processAuthResult:url standbyCallback:^(NSDictionary *resultDic) {
            //【由于在跳转支付宝客户端支付的过程中，商户app在后台很可能被系统kill了，所以pay接口的callback就会失效，请商户对standbyCallback返回的回调结果进行处理,就是在这个方法里面处理跟callback一样的逻辑】
            NSNumber *resultStatusNum = [resultDic objectForKey:@"resultStatus"];
            NSString *resultStatus = [NSString stringWithFormat:@"%@",resultStatusNum];
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlipayResultStatusNotification object:resultStatus];
        }];
    }
    return YES;
}
//竖屏
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskPortrait;
}
- (void)checkReviewTheStatus{
    [[UserStore sharedInstance]checkReviewTheStatus];
}
@end
