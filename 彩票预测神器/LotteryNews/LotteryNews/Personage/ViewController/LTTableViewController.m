//
//  LTTableViewController.m
//  LotteryNews
//
//  Created by 邹壮壮 on 2016/12/26.
//  Copyright © 2016年 邹壮壮. All rights reserved.
//

#import "LTTableViewController.h"
#import "SGActionSheet.h"
#import "UserStore.h"
#import "LNLottoryConfig.h"
#import <AlipaySDK/AlipaySDK.h>
#import "ProgressHUD.h"
@class LTPayCell;

@protocol LTPayCellDelegate <NSObject>

- (void)LTPayCell:(LTPayCell *)cell onPayClick:(id)sender;

@end

@interface LTPayCell : UITableViewCell

{
    UIButton  *_payCashButton;//pay cash
}

@property (nonatomic, strong) NSDictionary *payDict;
@property (nonatomic, weak) id<LTPayCellDelegate> delegate;

+ (CGFloat)height;

@end

@implementation LTPayCell
@synthesize delegate;
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self customInit];
    }
    return self;
}
- (void)customInit
{
    self.backgroundColor = [UIColor whiteColor];
    
    //pay
    UIImage *image = [UIImage imageNamed:@"choosenumber_bg"];
    image = [image stretchableImageWithLeftCapWidth:image.size.width / 2 topCapHeight:image.size.height / 2];
    
    _payCashButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_payCashButton setBackgroundImage:image forState:UIControlStateNormal];
    _payCashButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_payCashButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_payCashButton addTarget:self action:@selector(onPayClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_payCashButton];
}

- (void)setPayDict:(NSDictionary *)payDict
{
    _payDict = payDict;
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [_payCashButton setTitle:[_payDict objectForKey:@"describe"] forState:UIControlStateNormal];
    
    CGFloat x = 15;
    CGFloat height = 45;
    
    
    _payCashButton.frame = CGRectMake(x, (CGRectGetHeight(self.frame) - height) / 2, CGRectGetWidth(self.frame) - x * 2, height);
}

+ (CGFloat)height
{
    return 60;
}

#pragma mark - on click

- (void)onPayClick:(id)sender
{
    if (delegate && [delegate respondsToSelector:@selector(LTPayCell:onPayClick:)]) {
        [delegate LTPayCell:self onPayClick:sender];
    }
}

@end
@interface LTTableViewController ()<LTPayCellDelegate,SGActionSheetDelegate>
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSDictionary *payDict;
@end

@implementation LTTableViewController
@synthesize items;
- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alipayResultStatus:) name:kAlipayResultStatusNotification object:nil];
    self.title = @"充值";
    UIView *headerView = [[UIView alloc] init];
    
    NSString *title = LSTR(@"金币说明，金币不可购买彩票，仅用于购买专家预测，购买后不可提现或退款。专家不保证100%准确");
    
    UILabel *headerLabel = [[UILabel alloc] init];
    headerLabel.text = title;
    headerLabel.font = [UIFont systemFontOfSize:16];
    headerLabel.textColor = [UIColor grayColor];
    headerLabel.numberOfLines = 0;
    [headerView addSubview:headerLabel];
    
    CGFloat x = 15;
    CGFloat y = 10;
    CGRect rect = [title boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.view.frame) -  x * 2, MAXFLOAT) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : headerLabel.font} context:NULL];
    headerLabel.frame = CGRectMake(x, y, CGRectGetWidth(self.view.frame) - x * 2, CGRectGetHeight(rect));
    
    headerView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(rect) + y * 2);
    
    self.tableView.tableHeaderView = headerView;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.items = kPayList;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}
#pragma mark - UITableView

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifier = @"cell";
    LTPayCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        cell = [[LTPayCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    if (self.items.count > indexPath.row) {
        NSDictionary *dict = [self.items objectAtIndex:indexPath.row];
        cell.payDict = dict;
    }
    
    
    return cell;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.items.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [LTPayCell height];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dict = [self.items objectAtIndex:indexPath.row];
    
    [self sheet:dict];
}
#pragma mark - LTPayCellDelegate

- (void)LTPayCell:(LTPayCell *)cell onPayClick:(id)sender
{
    NSDictionary *dict = cell.payDict;
    
    [self sheet:dict];
}
- (void)sheet:(NSDictionary *)dict{
    _payDict = dict;
    SGActionSheet *sheetAction = [[SGActionSheet alloc]initWithTitle:@"金币说明，金币不可购买彩票，仅用于购买专家预测，购买后不可提现或退款。专家不保证100%准确" delegate: self cancelButtonTitle:@"取消" otherButtonTitleArray:@[@"支付宝"
                                                                                                                                                                                      ]];
    [sheetAction show];
}
- (void)SGActionSheet:(SGActionSheet *)actionSheet didSelectRowAtIndexPath:(NSInteger)indexPath{
    if (indexPath == 0) {
        [self aplipay:_payDict];
    }
    //NSLog(@"%ld",(long)indexPath);
}
- (void)aplipay:(NSDictionary *)dict{
    NSString *userid = UserDefaultObjectForKey(LOTTORY_AUTHORIZATION_UID);
    NSString *total_fee = [dict objectForKey:@"money"];
    NSString *subject = [dict objectForKey:@"describe"];
    [[UserStore sharedInstance]alipayOrde:userid total_fee:total_fee subject:subject sucess:^(NSURLSessionDataTask *task, id responseObject) {
        NSNumber *codeNum = [responseObject objectForKey:@"code"];
        NSInteger code = [codeNum integerValue];
        if (code == 1) {
            NSString *ordeurl = [responseObject objectForKey:@"order_url"];
            [self openAplipay:ordeurl];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
    }];
    
}
- (void)openAplipay:(NSString *)payUrl{
    [[AlipaySDK defaultService] payOrder:payUrl  fromScheme:appSchemes callback:^(NSDictionary *resultDic) {
        NSLog(@"reslut =对对对 %@",resultDic);
    }];
}
- (void)alipayResultStatus:(NSNotification *)notifiaction{
    id value = notifiaction.object;
    if ([value isKindOfClass:[NSString class]]) {
        NSString *resultStatus = (NSString *)value;
        NSString *message = @"未知错误！";
        if ([resultStatus isEqualToString:@"9000"]) {
            message = @"订单支付成功";
            
        }else if ([resultStatus isEqualToString:@"8000"]){
            message = @"正在处理中";
        }else if ([resultStatus isEqualToString:@"4000"]){
            message = @"订单支付失败";
        }else if ([resultStatus isEqualToString:@"6001"]){
            message = @"用户中途取消";
        }else if ([resultStatus isEqualToString:@"6002"]){
            message = @"网络连接出错";
        }
        [self message:message];
    }
}
- (void)message:(NSString *)message{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ProgressHUD sharedInstance]showInfoWithStatus:message];
    });
}
- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
@end
