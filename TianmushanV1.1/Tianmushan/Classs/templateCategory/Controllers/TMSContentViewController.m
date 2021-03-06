/**************************************************************************
 *
 *  Created by shushaoyong on 2016/10/27.
 *    Copyright © 2016年 踏潮. All rights reserved.
 *
 * 项目名称：浙江踏潮-天目山-h5模版制作软件
 * 版权说明：本软件属浙江踏潮网络科技有限公司所有，在未获得浙江踏潮网络科技有限公司正式授权
 *           情况下，任何企业和个人，不能获取、阅读、安装、传播本软件涉及的任何受知
 *           识产权保护的内容。
 ***************************************************************************/

#import "TMSContentViewController.h"
#import "TianmushanAPI.h"
#import "TMSHomeCell.h"
#import "TMSCategoryItem.h"
#import "TMSDetailViewController.h"
#import "TMSHomeMode.h"
#import "TMSRefreshFooter.h"
#import "TMSRefreshHeader.h"
#import "TMSCreateTideController.h"
#import "TMSNoLoginViewController.h"
#import "TMSWaveLoadView.h"


@interface TMSContentViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,TMSHomeCellDelegate,TMSLoginViewDelegate,TMSNoLoginViewControllerDelegate>

/**datas*/
@property(nonatomic,strong)NSMutableArray *datas;

/**当前页*/
@property(nonatomic,assign)NSInteger currentPage;

/**总个数*/
@property(nonatomic,assign)NSInteger totalCount;

/**是否是上拉加载更多*/
@property(nonatomic,assign)BOOL pullUp;

/***/
@property(nonatomic,strong)UICollectionView *collectionView;

/**缓存文件名*/
@property(nonatomic,copy)NSString *TMSContentViewControllerCachePath;

/**加载失败提醒*/
@property(nonatomic,strong)UIView *homeNullHUD;

/**loadview*/
@property (nonatomic, strong) TMSWaveLoadView *loadingView;

/**提示文字*/
@property(nonatomic,weak) UILabel *hudLabel;

/**操作按钮*/
@property(nonatomic,weak)UIButton *doneBtn;

/**保存当前点击cell对应的模型*/
@property(nonatomic,strong)TMSHomeMode *mode;

/**记录开始加载数据时间*/
@property(nonatomic,strong)NSDate *startDate;


@end

@implementation TMSContentViewController

static NSString * const reuseIdentifier = @"TMSHomeCell";

static NSString * const TMSContentViewControllerReuseIdentifier = @"TTMSContentViewControllerHeader";

/**
 *  没有数据 提示视图
 *
 *  @return 视图对象
 */
- (UIView *)homeNullHUD
{
    if (!_homeNullHUD) {
        
        _homeNullHUD = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height)];
        _homeNullHUD.hidden = YES;
        [self.collectionView addSubview:_homeNullHUD];
        
        UILabel *hudLabel = [[UILabel alloc] init];
        hudLabel.text = @"数据加载失败了~";
        hudLabel.textColor = UIColorFromRGB(0x999999);
        hudLabel.textAlignment = NSTextAlignmentCenter;
        hudLabel.font = [UIFont systemFontOfSize:16];
        [_homeNullHUD addSubview:hudLabel];
        hudLabel.sd_layout.centerYEqualToView(_homeNullHUD).offset(-65).centerXEqualToView(_homeNullHUD).widthRatioToView(_homeNullHUD,0.98).heightIs(35);
        self.hudLabel = hudLabel;
        
        UIButton *doneBtn = [[UIButton alloc] init];
        [doneBtn setTitle:@"重新加载" forState:UIControlStateNormal];
        [doneBtn setTitleColor:UIColorFromRGB(0x30cdad) forState:UIControlStateNormal];
        doneBtn.layer.borderColor = UIColorFromRGB(0x30c0ad).CGColor;
        doneBtn.layer.borderWidth = 1;
        [doneBtn addTarget:self action:@selector(nullHUDDidClicked) forControlEvents:UIControlEventTouchDown];
        [_homeNullHUD addSubview:doneBtn];
        self.doneBtn = doneBtn;
        doneBtn.sd_cornerRadius = @20;
        doneBtn.sd_layout.topSpaceToView(hudLabel,15).centerXEqualToView(_homeNullHUD).widthIs(150).heightIs(40);
    }
    return _homeNullHUD;
}

/**
 *  加载动画
 *
 *  @return <#return value description#>
 */
- (TMSWaveLoadView *)loadingView
{
    if (!_loadingView) {
        _loadingView = [TMSWaveLoadView loadingView];
        [self.view addSubview:_loadingView];
        _loadingView.center = CGPointMake(self.view.center.x, self.view.center.y-64);
    }
    return _loadingView;
}


/**
 *  设置当前的控制器对应的名称和分类id
 *
 *  @param item <#item description#>
 */
- (void)setItem:(TMSCategoryItem *)item
{
    _item = item;
    
    //缓存路径
    self.TMSContentViewControllerCachePath = [@"TMSContentViewController" stringByAppendingString:item.name];
    
    self.title = item.nick;
    
}

/**
 *  模型数组
 *
 *  @return 模型数组
 */
- (NSMutableArray *)datas
{
    if (!_datas) {
        
        _datas = [NSMutableArray array];
    
    }
    return _datas;
}


/**
 *  控制器view加载完成
 */
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.currentPage = 1;
    
    [self createCollectionView];
    
}

/**
 *  创建内容视图
 */
- (void)createCollectionView
{
    self.view.backgroundColor = GLOBALCOLOR;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT-64) collectionViewLayout:[[TMSContentViewLayout alloc] init]];
    collectionView.contentInset = UIEdgeInsetsMake(15, 13, 0, 13);
    collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(15, 0, 0, 0);
    collectionView.dataSource = self;
    collectionView.delegate = self;
    [self.view addSubview:collectionView];
    self.collectionView = collectionView;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.scrollsToTop = NO;
    
    [self.collectionView registerClass:[TMSHomeCell class] forCellWithReuseIdentifier:reuseIdentifier];
    [self.collectionView registerClass:[TMSContentViewControllerHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:TMSContentViewControllerReuseIdentifier];
    
    //配置刷新控件
    TMSRefreshHeader *header = [TMSRefreshHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewData)];
    header.automaticallyChangeAlpha = YES;
    header.arrowView.image = [UIImage imageNamed:@"newRefresh"];
    header.stateLabel.text = @"下拉加载最新";
    header.lastUpdatedTimeLabel.hidden = YES;
    [header setTitle:@"刷新数据中" forState:MJRefreshStateRefreshing];
    header.stateLabel.textColor = UIColorFromRGB(0xb9b9b9);
    self.collectionView.mj_header = header;

    TMSRefreshFooter *footer = [TMSRefreshFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
    [footer setTitle:@"没有更多模板了" forState:MJRefreshStateNoMoreData];
    footer.stateLabel.textColor = UIColorFromRGB(0xb9b9b9);
    footer.stateLabel.font = [UIFont systemFontOfSize:13];
    self.collectionView.mj_footer = footer;
    
    //加载数据
    [self loadData];
    
}




/**
 *  加载最新数据
 */
- (void)loadNewData
{
    self.pullUp = NO;
    self.currentPage = 1;
    
    [self.collectionView.mj_header beginRefreshing];
    
    //拼接url
    NSString *url = [[KRAPI_home stringByAppendingString:self.item.name?self.item.name:@""] stringByAppendingString:[NSString stringWithFormat:@"/%zd",self.currentPage]];
    
    //请求数据
    [[APIAgent sharedInstance] getFromUrl:url params:nil withCompletionBlockWithSuccess:^(NSDictionary *responseObject) {
        
        
        if ([responseObject[@"code"] longLongValue] != 0) {
            [self.homeNullHUD removeFromSuperview];
            self.homeNullHUD = nil;
            self.homeNullHUD.hidden = NO;
            self.hudLabel.text = @"当前类目下暂时没有模板";
            self.doneBtn.hidden = YES;
            [self.collectionView.mj_header endRefreshing];
            return;
        }
        
        
        //将结果集转换为json字符串 写入文件中
        NSString *json = [NSString jsonWithDictionary:responseObject];
        
        [json writeToFile:[self.TMSContentViewControllerCachePath  cachePath] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        [json writeToFile:@"/Users/shushaoyong/Desktop/图片素材/TMSContentViewController.json" atomically:YES encoding:NSUTF8StringEncoding error:nil];

        
        [self loadReportDatas:responseObject];
        
    } withFailure:^(NSString *error) {
        
        [self.loadingView stopLoading];
        
        [self.collectionView.mj_header endRefreshing];
        
        //加载缓存数据
        NSString *cacheJson = [NSString stringWithContentsOfFile:[self.TMSContentViewControllerCachePath  cachePath] encoding:NSUTF8StringEncoding error:nil];
        

        
        //有缓存加载缓存数据
        if (cacheJson) {
            NSDictionary *responseObject = [NSString dictionaryWithJson:cacheJson];
            [self loadReportDatas:responseObject];
        }
        
        
    }];

    
}



/**
 *  加载更多数据
 */
- (void)loadMoreData
{
    self.pullUp = YES;
    [self loadData];
}


/**
 *  加载数据
 */
- (void)loadData
{
    
    //记录开始时间
    self.startDate = [NSDate date];
    
    if (!self.pullUp) { //如果是下拉刷新 设置页数位1
        
        [self.loadingView startLoading];
                
        self.currentPage = 1;
    }else{
        self.currentPage++;
    }
    
    //加载缓存数据
    NSString *cacheJson = [NSString stringWithContentsOfFile:[self.TMSContentViewControllerCachePath  cachePath] encoding:NSUTF8StringEncoding error:nil];
    
    //有缓存加载缓存数据
    if (cacheJson) {
        NSDictionary *responseObject = [NSString dictionaryWithJson:cacheJson];
        [self loadReportDatas:responseObject];

    }
    

    //拼接url
    NSString *url = [[KRAPI_home stringByAppendingString:self.item.name?self.item.name:@""] stringByAppendingString:[NSString stringWithFormat:@"/%zd",self.currentPage]];
    
    //请求数据
    [[APIAgent sharedInstance] getFromUrl:url params:nil withCompletionBlockWithSuccess:^(NSDictionary *responseObject) {
        
        
        if ([responseObject[@"code"] longLongValue] != 0) {
            [self.homeNullHUD removeFromSuperview];
            self.homeNullHUD = nil;
            self.homeNullHUD.hidden = NO;
            self.hudLabel.text = @"当前类目下暂时没有模板";
            self.doneBtn.hidden = YES;
            [self.collectionView.mj_header endRefreshing];
            [self.loadingView stopLoading];

            return;
        }
        
       
        //如果是上拉加载更多 不需要缓存
        if (self.pullUp) {
        
            [self loadReportDatas:responseObject];

            return;
        }

        //判断当前请求的数据是否和缓存中的数据一样
        NSString *newJson = [NSString jsonWithDictionary:responseObject];
        
        if (![cacheJson isEqualToString:newJson]) {
            
            //将结果集转换为json字符串 写入文件中
            NSString *json = [NSString jsonWithDictionary:responseObject];
            
            [json writeToFile:[self.TMSContentViewControllerCachePath  cachePath] atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
            [self loadReportDatas:responseObject];

            return;
        }
     
        if (self.datas.count<=0) {
            self.homeNullHUD.hidden = NO;
            [self.loadingView stopLoading];
        }
    
        
    } withFailure:^(NSString *error) {
        
        
        [self.collectionView.mj_header endRefreshing];
        [self.collectionView.mj_footer endRefreshingWithNoMoreData];
        
        if (self.datas.count<=0) {
            self.homeNullHUD.hidden = NO;
        }
        
        //如果小于5秒
        [self closedLoadView];

    }];
    
    
    
}

/*
 *关闭加载动画
 *
 */
- (void)closedLoadView
{
    //如果小于5秒
    if ([NSDate dateDifferStartDate:self.startDate endDate:[NSDate date]]<5000) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self.loadingView stopLoading];
            
        });
        
    }else{
        
        [self.loadingView stopLoading];
        
    }

}


- (void)loadReportDatas:(NSDictionary*)responseObject
{
        //如果没有数据 就不处理
        if ([responseObject[@"rst"] isKindOfClass:[NSNull class]]) {


            if (self.datas.count<=0) {
                
                [self.collectionView.mj_footer endRefreshing];
                
                self.homeNullHUD.hidden = NO;
                
                [self.loadingView stopLoading];
                
            }else {
                
                [self.collectionView.mj_footer endRefreshingWithNoMoreData];
                
                [self closedLoadView];

            }
            
            return;
        }


        //上拉加载
        if (self.pullUp) {

            if ([(NSArray*)responseObject[@"rst"][@"templates"] count] > 0) {
                
                [self.loadingView stopLoading];

                NSMutableArray *temp = [NSMutableArray array];
                for (NSDictionary *dict in responseObject[@"rst"][@"templates"]) {
                    TMSHomeMode *model = [TMSHomeMode modalWithDict:dict];
                    if ([model.catalog isEqualToString:@"photo"]) {
                        model.photoCategory = YES;
                    }
                    [temp addObject:model];
                }
                [self.datas addObjectsFromArray:temp];
                
                [self.collectionView reloadData];
                
                if (self.datas.count >= self.totalCount) {
                    [self.collectionView.mj_footer endRefreshingWithNoMoreData];
                }else{
                    [self.collectionView.mj_footer endRefreshing];
                }
                
            }else{
                
                [self.collectionView.mj_footer endRefreshingWithNoMoreData];
                
            }



        }else{ //首次刷新

            self.pullUp = NO;

            self.totalCount = [responseObject[@"count"] longLongValue];

            //如果没有数据 就不处理
            if (![responseObject[@"rst"][@"templates"] isKindOfClass:[NSNull class]]) {
                
                
                if ([(NSArray*)responseObject[@"rst"][@"templates"] count] > 0) {
                    
                    
                    [self.homeNullHUD removeFromSuperview];
                    self.homeNullHUD = nil;
                    
                    //删除之前的数据
                    [self.datas removeAllObjects];
                    
            
                    for (NSDictionary *dict in responseObject[@"rst"][@"templates"]) {
                        
                        TMSHomeMode *model = [TMSHomeMode modalWithDict:dict];
                        
                        //如果是相册
                        if ([model.catalog isEqualToString:@"photo"]) {
                            model.photoCategory = YES;
                        }
                        [self.datas addObject:model];
                    }
                    
                    
//                    [self closedLoadView];

                    [self.loadingView stopLoading];

                    [self.collectionView.mj_header endRefreshing];
                    [self.collectionView reloadData];
                    
                    if (self.datas.count == self.totalCount) {
                        [self.collectionView.mj_footer endRefreshingWithNoMoreData];
                    }else{
                        [self.collectionView.mj_footer endRefreshing];
                    }
                    
                    
                    
                }else{
                    
                    [self closedLoadView];

                    [self.collectionView.mj_header endRefreshing];
                    self.homeNullHUD.hidden = NO;
                    
                }
                
            }else{
                
                [self closedLoadView];

                [self.collectionView.mj_header endRefreshing];
                [self.collectionView.mj_footer endRefreshing];
                self.homeNullHUD.hidden = NO;
            }

    }

}


#pragma mark datasource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
   
    return self.datas.count?self.datas.count:0;

}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    TMSHomeCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    if (self.datas.count>=indexPath.row) {
        cell.homeMode = self.datas[indexPath.row];
    }
    cell.delegate = self;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
 
    TMSDetailViewController *detail = [[TMSDetailViewController alloc] init];
    detail.watchTemplate = YES;
    if (self.datas.count>=indexPath.row) {
        TMSHomeMode *mode = self.datas[indexPath.row];
        detail.url = mode.h5Url;
        detail.mode = mode;
    }
    [self.navigationController pushViewController:detail animated:YES];
}

#pragma mark 没有数据view点击

#pragma mark TMSHomeCellDelegate
- (void)homeCell:(TMSHomeCell *)cell createTideBtnClicked:(TMSHomeMode *)mode
{
    self.mode = mode;
    
    //如果没有登录 提示用户登录
    if (![TMSCommonInfo accessToken]) {
        
        TMSLoginView *loginV = [TMSLoginView loginViewTitle:@"提示" message:@"你还没有登录 快去登录吧" delegate:self cancelButtonTitle:@"暂不登录" otherButtonTitle:@"立即登录"];
        
        [loginV show];
        
        return;
        
    }
    
    [self skipToEditTideController];

   
}

#pragma mark TMSLoginViewDelegate

- (void)loginView:(TMSLoginView *)view didClickedbuttonIndex:(NSInteger)index
{
    if (index == 0) {
        
        [view hide];
        
    }else if (index==1){
        
        [view hide];

        TMSNoLoginViewController *nologon = [[TMSNoLoginViewController alloc] init];
        nologon.delegate = self;
        [self.navigationController pushViewController:nologon animated:YES];
        
    }
}

#pragma mark TMSNoLoginViewControllerDelegate
- (void)noLoginViewControllerLoginSuccess:(TMSNoLoginViewController *)vc
{
    [self skipToEditTideController];
}

/**
 *  跳转到去制作界面
 */
- (void)skipToEditTideController
{
    TMSCreateTideController *createTide = [[TMSCreateTideController alloc] init];
    createTide.mode = self.mode;
    [self.navigationController pushViewController:createTide animated:YES];
}


/**
 *  没有数据 view点击
 */
- (void)nullHUDDidClicked
{
    if ([[AFNetworkReachabilityManager sharedManager] isReachable] == NO) {
        
        [self.view showError:@"网络无法连接，请稍后重试！"];
        
        return;
    }
    
    [self.loadingView stopLoading];
    self.loadingView = nil;
    [self.homeNullHUD removeFromSuperview];
    self.homeNullHUD = nil;
    [self loadData];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

@implementation TMSContentViewLayout

- (void)prepareLayout
{
    CGFloat margin = 13;
    self.minimumLineSpacing = 10;
    self.minimumInteritemSpacing = 9;
    CGFloat itemW = (SCREEN_WIDTH - 2*margin - 9)*0.5;
    self.itemSize = CGSizeMake(itemW, itemW+70);
    
}


@end


@implementation TMSContentViewControllerHeader


@end


