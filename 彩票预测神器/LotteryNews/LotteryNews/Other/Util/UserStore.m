//
//  UserStore.m
//  LotteryNews
//
//  Created by 邹壮壮 on 2016/12/23.
//  Copyright © 2016年 邹壮壮. All rights reserved.
//

#import "UserStore.h"
#import "HRUtilts.h"
#import "HRNetworkTools.h"
#import "NSString+Extension.h"
#import "LNLottoryConfig.h"
#import "LNLotteryCategories.h"
#import "PPMDataModel.h"
//#import "WXApiManager.h"
#import "WXApiRequestHandler.h"
@implementation UserStore
+ (UserStore *)sharedInstance
{
    static UserStore *_sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[UserStore alloc] init];
    });
    
    return _sharedInstance;
}
#pragma mark --用户登录
    #pragma mark -- 手机号登录
- (void)loginUser:(NSDictionary *)loginUserInfo login_type:(NSString *)login_type sucess:(sucessCompleteBlock)sucessBlock failure:(failureCompleteBlock)failureBlock{
    NSString *url = [NSString stringWithFormat:@"%@/user/login",LOTTERY_HOST_NAME];
    NSString *idfa = [[HRUtilts sharedInstance] idfa];
    NSString *date = [NSDate timeInterval];
    NSString *verify = [[HRUtilts sharedInstance] verify:date];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:idfa forKey:@"idfa"];
    [parameters setObject:verify forKey:@"verify"];
    [parameters setObject:login_type forKey:@"login_type"];
    [parameters setObject:date forKey:@"u_time"];
    if ([login_type isEqualToString:@"0"]) {
        NSString *userInfoStr = [NSString dictionaryToJson:loginUserInfo];
        [parameters setObject:userInfoStr forKey:@"data"];
    }else{
        
        [parameters setObject:[loginUserInfo objectForKey:@"phone_number"] forKey:@"phone_number"];
        [parameters setObject:[loginUserInfo objectForKey:@"scode"] forKey:@"verify_code"];
    }
    
    
    [[HRNetworkTools sharedNetworkTools]POST:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //成功
        sucessBlock(task,responseObject);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        //失败
        failureBlock(task,error);
    }];
}
- (void)getScode:(NSString *)phone_number sucess:(sucessCompleteBlock)sucessBlock failure:(failureCompleteBlock)failureBlock{
    NSString *url = [NSString stringWithFormat:@"%@/user/login_verify_code",LOTTERY_HOST_NAME];
    NSString *idfa = [[HRUtilts sharedInstance] idfa];
    NSString *date = [NSDate timeInterval];
    NSString *verify = [[HRUtilts sharedInstance] verify:date];
    NSDictionary *parameters = @{@"idfa":idfa,@"verify":verify,@"u_time":date,@"phone_number":phone_number};
    [[HRNetworkTools sharedNetworkTools]POST:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        sucessBlock(task,responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureBlock(task,error);
    }];

}
#pragma mark -- 微信登录
-(void)getAccess_token:(NSString *)code sucess:(void(^)( NSDictionary *dict))block

{
    //https://api.weixin.qq.com/sns/oauth2/access_token?appid=APPID&secret=SECRET&code=CODE&grant_type=authorization_code
    
    NSString *url =[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/access_token?appid=%@&secret=%@&code=%@&grant_type=authorization_code",kAuthOpenID,kAuthOpensecret,code];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSURL *zoneUrl = [NSURL URLWithString:url];
        
        NSString *zoneStr = [NSString stringWithContentsOfURL:zoneUrl encoding:NSUTF8StringEncoding error:nil];
        
        NSData *data = [zoneStr dataUsingEncoding:NSUTF8StringEncoding];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (data) {
                
                NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                
                /*
                 
                 {
                 
                 "access_token" = "OezXcEiiBSKSxW0eoylIeJDUKD6z6dmr42JANLPjNN7Kaf3e4GZ2OncrCfiKnGWiusJMZwzQU8kXcnT1hNs_ykAFDfDEuNp6waj-bDdepEzooL_k1vb7EQzhP8plTbD0AgR8zCRi1It3eNS7yRyd5A";
                 
                 "expires_in" = 7200;
                 
                 openid = oyAaTjsDx7pl4Q42O3sDzDtA7gZs;
                 
                 "refresh_token" = "OezXcEiiBSKSxW0eoylIeJDUKD6z6dmr42JANLPjNN7Kaf3e4GZ2OncrCfiKnGWi2ZzH_XfVVxZbmha9oSFnKAhFsS0iyARkXCa7zPu4MqVRdwyb8J16V8cWw7oNIff0l-5F-4-GJwD8MopmjHXKiA";
                 
                 scope = "snsapi_userinfo,snsapi_base";
                 
                 }
                 
                 */
                
                NSString * access_token = [dic objectForKey:@"access_token"];
                
                NSString *openid = [dic objectForKey:@"openid"];
                [self getUserInfo:access_token openid:openid sucess:^(NSDictionary *dict) {
                    block(dict);
                }];
            }
            
        });
        
    });
    
}
//三.根据第二步获取的token和openid来获取用户的相关信息

-(void)getUserInfo:(NSString *)token openid:(NSString *)openid sucess:(void(^)( NSDictionary *dict))block
{
    
    // https://api.weixin.qq.com/sns/userinfo?access_token=ACCESS_TOKEN&openid=OPENID
    
    NSString *url =[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/userinfo?access_token=%@&openid=%@",token,openid];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSURL *zoneUrl = [NSURL URLWithString:url];
        
        NSString *zoneStr = [NSString stringWithContentsOfURL:zoneUrl encoding:NSUTF8StringEncoding error:nil];
        
        NSData *data = [zoneStr dataUsingEncoding:NSUTF8StringEncoding];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (data) {
                
                NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                
                /*
                 
                 {
                 
                 city = Haidian;
                 
                 country = CN;
                 
                 headimgurl = "http://wx.qlogo.cn/mmopen/FrdAUicrPIibcpGzxuD0kjfnvc2klwzQ62a1brlWq1sjNfWREia6W8Cf8kNCbErowsSUcGSIltXTqrhQgPEibYakpl5EokGMibMPU/0";
                 
                 language = "zh_CN";
                 
                 nickname = "xxx";
                 
                 openid = oyAaTjsDx7pl4xxxxxxx;
                 
                 privilege =    (
                 
                 );
                 
                 province = Beijing;
                 
                 sex = 1;
                 
                 unionid = oyAaTjsxxxxxxQ42O3xxxxxxs;
                 
                 }
                 
                 */
                UserDefaultSetObjectForKey(dic, @"weixinUserInfo");
                block(dic);
            }
            
        });
        
    });
    
}
#pragma mark --彩种分类接口
- (void)getCategories:(sucessCompleteBlock)sucessBlock failure:(failureCompleteBlock)failureBlock{
    NSString *url = [NSString stringWithFormat:@"%@/lottery/categories",LOTTERY_HOST_NAME];
    [[HRNetworkTools sharedNetworkTools] GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSNumber *codeNum = [responseObject objectForKey:@"code"];
            NSInteger code = [codeNum integerValue];
            if (code == 1) {
                NSArray *datas = [responseObject objectForKey:@"data"];
                NSMutableArray *dataArray = [NSMutableArray array];
                for (NSDictionary *dict in datas) {
                    LottoryCategoryModel *item = [[LottoryCategoryModel alloc]initWithDictionary:dict error:NULL];
                    [dataArray addObject:item];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:kLotteryDateSuccessedFristNotification object:dataArray];
                
            }
        }
        sucessBlock(task,responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureBlock(task,error);
        NSLog(@"basicViewController====%@",error);
    }];

}


#pragma mark --获取彩票玩法接口
- (void)requestPlayType:(LottoryCategoryModel *)model sucess:(sucessCompleteBlock)sucessBlock failure:(failureCompleteBlock)failureBlock{
    NSString *url = [NSString stringWithFormat:@"%@/lottery/playtype?caipiaoid=%@",LOTTERY_HOST_NAME,model.caipiaoid];
    [[HRNetworkTools sharedNetworkTools]GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSArray *arr = [responseObject objectForKey:@"data"];
        NSMutableArray *dataArray = [NSMutableArray array];
        for (NSDictionary *dict in arr) {
            LottoryPlaytypemodel *PlayModel = [[LottoryPlaytypemodel alloc]initWithDictionary:dict error:nil];
            [dataArray addObject:PlayModel];
        }
        NSDictionary *categoryPlaytypeDict = @{@"category":model,@"playtype":dataArray};
        
        [LNLotteryCategories sharedInstance].categoryPlayArray = dataArray;
        [[NSNotificationCenter defaultCenter] postNotificationName:kLotteryDateSuccessedNotification object:categoryPlaytypeDict];
        sucessBlock(task,responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
         failureBlock(task,error);
        NSLog(@"%@",error);
    }];
}
#pragma mark --获取彩票数据
- (void)request:(NSString *)caipiaoid play_type:(LottoryPlaytypemodel *)play_type jisu_api_id:(NSString *)jisu_api_id isNewData:(BOOL)newData sucess:(sucessCompleteBlock)sucessBlock failure:(failureCompleteBlock)failureBlock{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    NSString *idfa = [[HRUtilts sharedInstance] idfa];
    NSString *date = [NSDate timeInterval];
    NSString *token = [[HRUtilts sharedInstance] verify:date];
    NSString *url = @"";
    NSString *userId = UserDefaultObjectForKey(LOTTORY_AUTHORIZATION_UID);
    if (newData) {
       url = [NSString stringWithFormat:@"%@/category/new_data",LOTTERY_HOST_NAME];
        [parameters setObject:userId forKey:@"userid"];
    }else{
       url = [NSString stringWithFormat:@"%@/category/old_data",LOTTERY_HOST_NAME];
    }
     [parameters setObject:idfa forKey:@"idfa"];
     [parameters setObject:token forKey:@"verify"];
     [parameters setObject:date forKey:@"u_time"];
     [parameters setObject:app_type forKey:@"app_type"];
     [parameters setObject:appid forKey:@"appid"];
     [parameters setObject:caipiaoid forKey:@"caipiaoid"];
    [parameters setObject:play_type.playtype forKey:@"playtype"];
    [parameters setObject:jisu_api_id forKey:@"jisu_api_id"];
    [[HRNetworkTools sharedNetworkTools]POST:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        sucessBlock(task,responseObject);
            
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureBlock(task,error);
        NSLog(@"%@",error);
    }];
}


#pragma mark 获取用户信息
- (void)requestGetUserInfoWithUserId:(NSString *)userId sucess:(sucessCompleteBlock)sucessBlock failure:(failureCompleteBlock)failureBlock{
    NSString *idfa = [[HRUtilts sharedInstance] idfa];
    NSString *date = [NSDate timeInterval];
    NSString *verify = [[HRUtilts sharedInstance] verify:date];
    NSString *url = [NSString stringWithFormat:@"%@/user/info",LOTTERY_HOST_NAME];
    NSDictionary *parameters = @{@"idfa":idfa,@"verify":verify,@"u_time":date,@"userid":userId};
    [[HRNetworkTools sharedNetworkTools]POST:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        sucessBlock(task,responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureBlock(task,error);
    }];
}
#pragma mark -- 我的购买记录
- (void)getBuyRecord:(NSString *)userId sucess:(sucessCompleteBlock)sucessBlock failure:(failureCompleteBlock)failureBlock{
    NSString *idfa = [[HRUtilts sharedInstance] idfa];
    NSString *date = [NSDate timeInterval];
    NSString *verify = [[HRUtilts sharedInstance] verify:date];
    NSString *url = [NSString stringWithFormat:@"%@/user/buy_record",LOTTERY_HOST_NAME];
    NSDictionary *parameters = @{@"idfa":idfa,@"verify":verify,@"u_time":date,@"userid":userId};
    [[HRNetworkTools sharedNetworkTools]POST:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        sucessBlock(task,responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureBlock(task,error);
    }];
}
#pragma mark -- 我的充值记录
- (void)getRechargeRecord:(NSString *)userId sucess:(sucessCompleteBlock)sucessBlock failure:(failureCompleteBlock)failureBlock{
    NSString *idfa = [[HRUtilts sharedInstance] idfa];
    NSString *date = [NSDate timeInterval];
    NSString *verify = [[HRUtilts sharedInstance] verify:date];
    NSString *url = [NSString stringWithFormat:@"%@/user/recharge_record",LOTTERY_HOST_NAME];
    NSDictionary *parameters = @{@"idfa":idfa,@"verify":verify,@"u_time":date,@"userid":userId};
    [[HRNetworkTools sharedNetworkTools]POST:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        sucessBlock(task,responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureBlock(task,error);
    }];
}

#pragma mark --获取专家信息接口
- (void)getHomePage:(NSString *)expert_id sucess:(sucessCompleteBlock)sucessBlock failure:(failureCompleteBlock)failureBlock{
    NSString *idfa = [[HRUtilts sharedInstance] idfa];
    NSString *date = [NSDate timeInterval];
    NSString *verify = [[HRUtilts sharedInstance] verify:date];
    NSString *url = [NSString stringWithFormat:@"%@/expert/homepage",LOTTERY_HOST_NAME];
    NSDictionary *parameters = @{@"idfa":idfa,@"verify":verify,@"u_time":date,@"expert_id":expert_id};
    [[HRNetworkTools sharedNetworkTools]GET:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        sucessBlock(task,responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
         failureBlock(task,error);
    }];
}
#pragma mark -- 获取专家历史预测数据
- (void)getexpertData:(NSString *)expert_id categoryModel:(LottoryCategoryModel *)categoryModel playModel:(LottoryPlaytypemodel *)playModel sucess:(sucessCompleteBlock)sucessBlock failure:(failureCompleteBlock)failureBlock{
    NSString *idfa = [[HRUtilts sharedInstance] idfa];
    NSString *date = [NSDate timeInterval];
    NSString *verify = [[HRUtilts sharedInstance] verify:date];
    NSString *url = [NSString stringWithFormat:@"%@/category/expert_data",LOTTERY_HOST_NAME];
    NSString *userId = UserDefaultObjectForKey(LOTTORY_AUTHORIZATION_UID);
    NSDictionary *parameters = @{@"idfa":idfa,@"verify":verify,@"u_time":date,@"expert_id":expert_id,@"playtype":playModel.playtype,@"caipiaoid":categoryModel.caipiaoid,@"jisu_api_id":categoryModel.jisu_api_id,@"userid":userId};
    [[HRNetworkTools sharedNetworkTools]POST:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        sucessBlock(task,responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureBlock(task,error);
    }];
}
#pragma mark --  购买预测内容接口
- (void)buyExpertData:(NSString *)expert_id userId:(NSString *)userId info:(NSMutableDictionary *)infoDict sucess:(sucessCompleteBlock)sucessBlock failure:(failureCompleteBlock)failureBlock{
    NSString *idfa = [[HRUtilts sharedInstance] idfa];
    NSString *date = [NSDate timeInterval];
    NSString *verify = [[HRUtilts sharedInstance] verify:date];
    NSString *url = [NSString stringWithFormat:@"%@/user/buy",LOTTERY_HOST_NAME];
    [infoDict setObject:idfa forKey:@"idfa"];
    [infoDict setObject:date forKey:@"u_time"];
    [infoDict setObject:verify forKey:@"verify"];
    [infoDict setObject:expert_id forKey:@"expert_id"];
    [infoDict setObject:userId forKey:@"userid"];
    [[HRNetworkTools sharedNetworkTools]POST:url parameters:infoDict progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        sucessBlock(task,responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureBlock(task,error);
    }];
    
}
#pragma mark-- 审核状态
- (void)checkReviewTheStatus{
    NSString *url = [NSString stringWithFormat:@"%@/review_status",LOTTERY_HOST_NAME];
    NSDictionary *parameters = @{@"appid":appid,@"stype":app_type};
    [[HRNetworkTools sharedNetworkTools]GET:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSNumber *statusNum = [responseObject objectForKey:@"status"];
        NSInteger status = [statusNum integerValue];
        if (status == 1) {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:LOTTORY_REVIEW_STATUS];
        }else{
           
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:LOTTORY_REVIEW_STATUS];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
    }];
}
#pragma mark --五星好评
- (void)fiveStarHighPraise:(NSString *)userid sucess:(sucessCompleteBlock)sucessBlock failure:(failureCompleteBlock)failureBlock{
    NSString *url = [NSString stringWithFormat:@"%@/comment_status",LOTTERY_HOST_NAME];
    NSDictionary *parameters = @{@"appid":appid,@"stype":app_type,@"userid":userid};
    [[HRNetworkTools sharedNetworkTools]GET:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        sucessBlock(task,responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureBlock(task,error);
    }];
}
#pragma mark --做任务送金币 =1好评任务，2签到任务
- (void)gold_manage:(NSString *)userid task_type:(NSString *)task_type sucess:(sucessCompleteBlock)sucessBlock failure:(failureCompleteBlock)failureBlock{
    NSString *idfa = [[HRUtilts sharedInstance] idfa];
    NSString *date = [NSDate timeInterval];
    NSString *verify = [[HRUtilts sharedInstance] verify:date];
    NSString *url = [NSString stringWithFormat:@"%@/task/gold_manage",LOTTERY_HOST_NAME];
    NSDictionary *parameters = @{@"userid":userid,@"task_type":task_type,@"idfa":idfa,@"verify":verify,@"u_time":date};
    [[HRNetworkTools sharedNetworkTools]POST:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         sucessBlock(task,responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureBlock(task,error);
    }];
}
#pragma mark --版本更新
- (void)version_update:(NSString *)userid sucess:(sucessCompleteBlock)sucessBlock failure:(failureCompleteBlock)failureBlock{
    NSString *url = [NSString stringWithFormat:@"%@/version_update",LOTTERY_HOST_NAME];
    NSDictionary *parameters = @{@"appid":appid,@"stype":app_type,@"userid":userid};
    [[HRNetworkTools sharedNetworkTools]GET:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        sucessBlock(task,responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureBlock(task,error);
    }];
}
#pragma mark --广告弹窗
- (void)ios_ad_manage:(NSString *)userid sucess:(sucessCompleteBlock)sucessBlock failure:(failureCompleteBlock)failureBlock{
    NSString *idfa = [[HRUtilts sharedInstance] idfa];
    NSString *date = [NSDate timeInterval];
    NSString *verify = [[HRUtilts sharedInstance] verify:date];
    NSString *url = [NSString stringWithFormat:@"%@/ios_ad_manage",LOTTERY_HOST_NAME];
    NSDictionary *parameters = @{@"idfa":idfa,@"verify":verify,@"u_time":date,@"userid":userid,@"appid":appid,@"stype":app_type,@"userid":userid};
    [[HRNetworkTools sharedNetworkTools]GET:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        sucessBlock(task,responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureBlock(task,error);
    }];
}
#pragma mark - 支付宝
- (void)alipayOrde:(NSString *)userid total_fee:(NSString *)total_fee subject:(NSString *)subject sucess:(sucessCompleteBlock)sucessBlock failure:(failureCompleteBlock)failureBlock{
    NSString *idfa = [[HRUtilts sharedInstance] idfa];
    NSString *date = [NSDate timeInterval];
    NSString *verify = [[HRUtilts sharedInstance] verify:date];
    NSString *url = [NSString stringWithFormat:@"%@/alipay/order_string",LOTTERY_HOST_NAME];
    NSDictionary *parameters = @{@"idfa":idfa,@"verify":verify,@"u_time":date,@"userid":userid,@"appname":appname,@"subject":subject,@"total_fee":total_fee};
    [[HRNetworkTools sharedNetworkTools]POST:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
       sucessBlock(task,responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
       failureBlock(task,error); 
    }];
}
- (void)account_bind:(NSDictionary *)weiInfo weixinid:(NSString *)weixin phone:(NSString *)phone sucess:(sucessCompleteBlock)sucessBlock failure:(failureCompleteBlock)failureBlock{
    NSString *idfa = [[HRUtilts sharedInstance] idfa];
    NSString *date = [NSDate timeInterval];
    NSString *verify = [[HRUtilts sharedInstance] verify:date];
    NSString *url = [NSString stringWithFormat:@"%@/user/account_bind",LOTTERY_HOST_NAME];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:idfa forKey:@"idfa"];
    [dict setObject:date forKey:@"u_time"];
    [dict setObject:verify forKey:@"verify"];
    [dict setObject:phone forKey:@"phone_number"];
    if (weixin) {
        [dict setObject:weixin forKey:@"weixin_id[unionid]"];
    }else{
      [dict setObject:weiInfo forKey:@"weixin_id"];
    }
    
   
    [[HRNetworkTools sharedNetworkTools]POST:url parameters:dict progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        sucessBlock(task,responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureBlock(task,error);
    }];
}
#pragma mark-- 资讯页面接口
- (void)newsCategory:(NSString *)categoryid page:(NSInteger)page sucess:(sucessCompleteBlock)sucessBlock failure:(failureCompleteBlock)failureBlock{
    NSString *idfa = [[HRUtilts sharedInstance] idfa];
    NSString *date = [NSDate timeInterval];
    NSString *verify = [[HRUtilts sharedInstance] verify:date];
    NSString *url = [NSString stringWithFormat:@"%@/news/category",LOTTERY_HOST_NAME];
    NSNumber *pageNum = [NSNumber numberWithInteger:page];
    NSDictionary *parameters = @{@"idfa":idfa,@"verify":verify,@"u_time":date,@"caipiaoid":categoryid,@"page":pageNum};
    [[HRNetworkTools sharedNetworkTools]GET:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        sucessBlock(task,responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureBlock(task,error); 
    }];
}
#pragma mark--排行榜页面
- (void)expert_rank:(NSDictionary *)dict sucess:(sucessCompleteBlock)sucessBlock failure:(failureCompleteBlock)failureBlock{
    NSString *idfa = [[HRUtilts sharedInstance] idfa];
    NSString *date = [NSDate timeInterval];
    NSString *verify = [[HRUtilts sharedInstance] verify:date];
    NSString *url = [NSString stringWithFormat:@"%@/expert_rank",LOTTERY_HOST_NAME];
    NSString *playtype = [dict objectForKey:@"playtype"];
    NSString *caipiaoid = [dict objectForKey:@"caipiaoid"];
    NSString *jisu_api_id = [dict objectForKey:@"jisu_api_id"];
    NSDictionary *parameters = @{@"idfa":idfa,@"verify":verify,@"u_time":date,@"caipiaoid":caipiaoid,@"playtype":playtype,@"jisu_api_id":jisu_api_id};
    [[HRNetworkTools sharedNetworkTools]POST:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        sucessBlock(task,responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failureBlock(task,error); 
    }];
}
@end
