//
//  BasicViewController.h
//  LotteryNews
//
//  Created by 邹壮壮 on 2016/12/20.
//  Copyright © 2016年 邹壮壮. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BasicViewController : UIViewController
@property (nonatomic, copy) NSString *navigationTitle;/**<导航栏名称*/
+ (BasicViewController *)sharedInstance;
@end
