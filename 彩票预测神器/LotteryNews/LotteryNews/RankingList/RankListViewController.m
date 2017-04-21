//
//  RankListViewController.m
//  LotteryNews
//
//  Created by 邹壮壮 on 2016/12/20.
//  Copyright © 2016年 邹壮壮. All rights reserved.
//

#import "RankListViewController.h"
#import <MJRefresh/MJRefresh.h>
#import "LNLotteryCategories.h"
#import "LiuXSegmentView.h"
#import "LNLottoryConfig.h"
#import "UserStore.h"

#import "RankListModel.h"
#import "RankListCell.h"

#import <SVProgressHUD/SVProgressHUD.h>
#import "PersonalHomePageViewController.h"
static NSString *rankListCellCellWithIdentifier = @"rankListCellCellWithIdentifier";
@interface RankListViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, strong)LiuXSegmentView *segement;


@end

NSDictionary *dictionary;
@implementation RankListViewController


- (NSMutableArray *)dataArray{
    if (_dataArray == nil) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = LRRandomColor;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kLotteryDateSuccessedNotification:) name:kLotteryDateSuccessedNotification object:nil];
    [self configUI];
    // Do any additional setup after loading the view.
}
- (void)configUI{
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 44, kScreenWidth, SCREEN_HEIGHT-44-kTabBarH-kStatusBarH-kNavigationBarH) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    [self.view addSubview:_tableView];
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:rankListCellCellWithIdentifier];
    [_tableView registerNib:[UINib nibWithNibName:NSStringFromClass([RankListCell class]) bundle:nil] forCellReuseIdentifier:rankListCellCellWithIdentifier];
    _tableView.tableFooterView = [[UIView alloc]init];
    _tableView.rowHeight =  UITableViewAutomaticDimension;
    _tableView.estimatedRowHeight = 50;//必须设置好预估值
    
        [self refreshHeader];
   
    //[self refreshFooter];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [MobClick beginLogPageView:@"RankListViewController"];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self segmentView:[LNLotteryCategories sharedInstance].categoryPlayArray];
    
}
- (void)kLotteryDateSuccessedNotification:(NSNotification *)notification{
    id value = notification.object;
    if ([value isKindOfClass:[NSDictionary class]]) {
        [self segmentView:[LNLotteryCategories sharedInstance].categoryPlayArray];
    }
}

//滚动
- (void)segmentView:(NSArray *)arr{
    if (_segement) {
        [_segement removeFromSuperview];
    }
    kWeakSelf(self)
    _segement=[[LiuXSegmentView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, 44) titles:arr clickBlick:^(NSInteger index) {
        if (_dataArray.count > 0) {
            [_dataArray removeAllObjects];
        }
        [SVProgressHUD showWithStatus:@"Loading..."];
         [weakself.tableView setContentOffset:CGPointMake(0, 0) animated:NO];
        LottoryPlaytypemodel *playModel = [arr objectAtIndex:index-1];
        LottoryCategoryModel *lottoryModel = [LNLotteryCategories sharedInstance].currentLottoryModel;
        NSDictionary *dict = @{@"playtype":playModel.playtype,@"caipiaoid":lottoryModel.caipiaoid,@"jisu_api_id":lottoryModel.jisu_api_id};
        dictionary = dict;
        [self loadNewData];
        
        
    }];
    [self.view addSubview:_segement];
}


- (void)refreshHeader{
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewData)];
    // 设置文字
    [header setTitle:@"下拉刷新" forState:MJRefreshStateIdle];
    [header setTitle:@"刷新数据" forState:MJRefreshStatePulling];
    [header setTitle:@"加载中..." forState:MJRefreshStateRefreshing];
    
    // 设置字体
    header.stateLabel.font = [UIFont systemFontOfSize:15];
    header.lastUpdatedTimeLabel.font = [UIFont systemFontOfSize:14];
    
    // 设置颜色
    header.stateLabel.textColor = [UIColor grayColor];
    header.lastUpdatedTimeLabel.textColor = [UIColor grayColor];
    
    // 马上进入刷新状态
    [header beginRefreshing];
    
    // 设置刷新控件
    self.tableView.mj_header = header;
}

- (void)refreshFooter{
    // 添加默认的上拉刷新
    // 设置回调（一旦进入刷新状态，就调用target的action，也就是调用self的loadMoreData方法）
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
    
    // 设置文字
    [footer setTitle:@"Click or drag up to refresh" forState:MJRefreshStateIdle];
    [footer setTitle:@"Loading more ..." forState:MJRefreshStateRefreshing];
    [footer setTitle:@"No more data" forState:MJRefreshStateNoMoreData];
    
    // 设置字体
    footer.stateLabel.font = [UIFont systemFontOfSize:17];
    
    // 设置颜色
    footer.stateLabel.textColor = [UIColor blueColor];
    
    // 设置footer
    self.tableView.mj_footer = footer;
}
- (void)loadNewData{
   
    [self loadData:dictionary];
    
}
- (void)loadData:(NSDictionary *)dict{
    kWeakSelf(self);
    
    [[UserStore sharedInstance]expert_rank:dict sucess:^(NSURLSessionDataTask *task, id responseObject) {
        [SVProgressHUD dismiss];
        //NSLog(@"%@",responseObject);
        NSNumber *codeNum = [responseObject objectForKey:@"code"];
        NSInteger code= [codeNum integerValue];
        if (code == 1) {
            NSArray *datas = [responseObject objectForKey:@"data"];
            for (NSDictionary *dict in datas) {
                RankListModel *model = [[RankListModel alloc]initWithDictionary:dict error:nil];
                [weakself.dataArray addObject:model];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.tableView.mj_header endRefreshing];
            [weakself.tableView reloadData];
           
            
        });
        

    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
    }];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    RankListCell *cell = [tableView dequeueReusableCellWithIdentifier:rankListCellCellWithIdentifier]
    ;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (_dataArray.count > indexPath.row) {
        RankListModel *model = [_dataArray objectAtIndex:indexPath.row];
        cell.rankListModel = model;
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (_dataArray.count > indexPath.row) {
        RankListModel *model = [_dataArray objectAtIndex:indexPath.row];
        PersonalHomePageViewController *personalHomeVC = [[PersonalHomePageViewController alloc]init];
        personalHomeVC.expert_id = model.expert_id;
        personalHomeVC.nickname = model.nickname;
        personalHomeVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:personalHomeVC animated:YES];
    }
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
     [SVProgressHUD dismiss];
    [MobClick endLogPageView:@"RankListViewController"];
}
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
