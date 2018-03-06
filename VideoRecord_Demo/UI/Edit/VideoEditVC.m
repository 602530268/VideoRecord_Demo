//
//  VideoEditVC.m
//  VideoRecord_Demo
//
//  Created by chencheng on 2018/3/1.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import "VideoEditVC.h"
#import "CCPlayer.h"
#import "CCRecord.h"

@interface VideoEditVC ()<UIScrollViewDelegate>

@property(nonatomic,strong) CCPlayer *player;

@end

@implementation VideoEditVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Movie.m4v" ofType:nil];
    self.fileUrl = [NSURL fileURLWithPath:path];
    
    [self createUI];
    [self createCCPlayer];
    [self updateScrollView];
}

- (void)createUI {
    self.view.backgroundColor = [UIColor blackColor];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;   //从导航栏底部开始计算坐标
    
//    UIBarButtonItem *nextBtnItem = [[UIBarButtonItem alloc] initWithTitle:@"下一步" style:(UIBarButtonItemStylePlain) target:self action:@selector(nextBtnItem)];
//    self.navigationItem.rightBarButtonItem = nextBtnItem;
    
    _containerView = [[UIView alloc] init];
    [self.view addSubview:_containerView];
    
    CGFloat containerViewHeight = SCREEN_HEIGHT * 0.5f;
    CGFloat containerViewWidth = SCREEN_WIDTH / SCREEN_HEIGHT * containerViewHeight;
    [_containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(20.0f);
        make.centerX.equalTo(self.view);
        make.width.equalTo(@(containerViewWidth));
        make.height.equalTo(@(containerViewHeight));
    }];
    
    _playBtn = [[UIButton alloc] init];
    [_playBtn setTitle:@"播放" forState:UIControlStateNormal];
    [_playBtn setTitle:@"暂停" forState:UIControlStateSelected];
    [_playBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_playBtn setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    [self.view addSubview:_playBtn];
    [_playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_containerView.mas_bottom).offset(20.0f);
        make.left.equalTo(self.view).offset(10.0f);
        make.width.height.equalTo(@(50.0f));
    }];
    [_playBtn addTarget:self action:@selector(playBtnEvent:) forControlEvents:UIControlEventTouchUpInside];
    
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.delegate = self;
    _scrollView.bounces = NO;
    [self.view addSubview:_scrollView];
    [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_playBtn.mas_right).offset(10.0f);
        make.centerY.equalTo(_playBtn);
        make.right.equalTo(self.view);
        make.height.equalTo(_playBtn);
    }];
    
    _segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"配音",@"滤镜",@"水印"]];
    [self.view addSubview:_segmentedControl];
    [_segmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.playBtn.mas_bottom).offset(20.0f);
        make.left.equalTo(self.playBtn);
        make.width.equalTo(self.view).multipliedBy(0.5f);
        make.height.equalTo(@(50.0f));
    }];
    [_segmentedControl addTarget:self action:@selector(segmentedControlEvent:) forControlEvents:UIControlEventValueChanged];
    
    for (UIView *subView in self.view.subviews) {
        subView.backgroundColor = [UIColor lightGrayColor];
    }
}

- (void)createCCPlayer {
    _player = [[CCPlayer alloc] initWithURL:self.fileUrl];
    _player.containerView = self.containerView;
    _player.videoGravity = AVLayerVideoGravityResize;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.playBtn.selected = YES;
        [_player play];
    });
    [self playerCallback];
}

- (void)playerCallback {
    CCWeakSelf(weakSelf)
    _player.playBlock = ^{
        
    };
    _player.pauseBlock = ^{
        
    };
    _player.finishBlock = ^{
        [weakSelf.player jumpProgressWith:0];
        [weakSelf.player play];
    };
    _player.progressBlock = ^(CGFloat progress, CGFloat currentTime, CGFloat totalTime) {

    };
    _player.bufferBlock = ^(CGFloat progress) {
        
    };
    
}

# pragma mark - Interaction Event
- (void)nextBtnItem {
    NSLog(@"下一步");
}

- (void)playBtnEvent:(UIButton *)sender {
    sender.selected = !sender.selected;
    
    if (sender.selected) {
        [self.player play];
    }else {
        [self.player pause];
    }
}

- (void)segmentedControlEvent:(UISegmentedControl *)sender {
    [SVProgressHUD showWithStatus:@"正在合成视频..."];
    
    __block NSString *show = nil;
    switch (sender.selectedSegmentIndex) {
        case 0:
        {
            [CCRecordTool dubForVideoWith:self.fileUrl
                                 audioUrl:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"music.wav" ofType:nil]]
                                startTime:0
                                  success:^(NSURL *url) {
                                      NSLog(@"合成配音成功");
                                      show = @"合成配音成功";
                                      [self videoEditFinish:url successTitle:show failTitle:nil];
                                  } fail:^(NSString *error) {
                                      NSLog(@"合成配音失败: %@",error);
                                      show = [NSString stringWithFormat:@"合成配音失败: %@",error];
                                      [self videoEditFinish:nil successTitle:nil failTitle:show];
                                  }];
        }
            break;
        case 1:
        {
            
            [CCRecordTool filterForVideoWith:self.fileUrl
                                                     success:^(NSURL *url) {
                                                         NSLog(@"合成滤镜成功");
                                                         show = @"合成滤镜成功";
                                                         [self videoEditFinish:url successTitle:show failTitle:nil];
                                                     } fail:^(NSString *error) {
                                                         NSLog(@"合成滤镜失败: %@",error);
                                                         show = [NSString stringWithFormat:@"合成滤镜失败: %@",error];
                                                         [self videoEditFinish:nil successTitle:nil failTitle:show];
                                                     }];
        }
            break;
        case 2:
        {
            UIView *watermarkView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
            watermarkView.backgroundColor = [UIColor redColor];
            [[CCRecordTool shareInstance] watermarkForVideoWith:self.fileUrl
                                                      videoRect:self.containerView.bounds
                                                  watermarkView:watermarkView
                                           frameProcessingBlock:^(GPUImageOutput *output, CMTime time) {
                                               CGRect frame = watermarkView.frame;
                                               watermarkView.frame = CGRectMake(frame.origin.x + 1.0f, frame.origin.y + 1.0f, 50, 50);
                                           } success:^(NSURL *url) {
                                               NSLog(@"添加水印成功");
                                               show = @"添加水印成功";
                                               [self videoEditFinish:url successTitle:show failTitle:nil];
                                           } fail:^(NSString *error) {
                                               NSLog(@"添加水印失败: %@",error);
                                               show = [NSString stringWithFormat:@"添加水印失败: %@",error];
                                               [self videoEditFinish:nil successTitle:nil failTitle:show];
                                           }];
            
        }
            break;
        default:
            break;
    }
    
}

- (void)videoEditFinish:(NSURL *)url
           successTitle:(NSString *)successTitle
              failTitle:(NSString *)failTitle {
    
    if (successTitle) {
        [SVProgressHUD showSuccessWithStatus:successTitle];
    }else if (failTitle) {
        [SVProgressHUD showSuccessWithStatus:failTitle];
    }
    [SVProgressHUD dismissWithDelay:1.5f];
    
    if (url) {
        self.fileUrl = url;
        self.player.fileUrl = self.fileUrl;
        [self.player play];
    }

}

# pragma mark - APIs (public)
- (void)updateScrollView {
    if (self.fileUrl == nil) {
        return;
    }
    
    //获取视频总时长
    AVAsset *asset = [AVAsset assetWithURL:self.fileUrl];
    int totalTime = CMTimeGetSeconds(asset.duration);
    //间隔1s截取视频帧
    NSMutableArray *imgFrames = @[].mutableCopy;
    NSLog(@"视频总时长: %d",totalTime);
    
    [self.scrollView.superview layoutIfNeeded];
    
    CGFloat scrollWidth = CGRectGetWidth(self.scrollView.bounds);
    CGFloat scrollHeight = CGRectGetHeight(self.scrollView.bounds);
    CGFloat itemHeight = scrollHeight;
    CGFloat itemWidth = itemHeight/2.0f;
    
    [self.scrollView setContentSize:CGSizeMake(itemWidth * totalTime + scrollWidth, 0)];
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    UIView *lineView = [[UIView alloc] init];
    lineView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.scrollView);
        make.width.equalTo(@2.0f);
        make.height.equalTo(@(itemHeight + 5.0f));
    }];
    
    __block CGFloat originX = scrollWidth/2.0f;
    dispatch_queue_t queue = dispatch_queue_create("scroll_queue", DISPATCH_QUEUE_SERIAL);
    for (int i = 0; i < totalTime; i++) {
        dispatch_async(queue, ^{
            CGFloat atTime = (CGFloat)i / (CGFloat)totalTime;
            [CCRecordTool getVideoFrameWith:self.fileUrl
                                     atTime:atTime
                                      block:^(UIImage *image) {
                                          [imgFrames addObject:image];
                                          UIImageView *imgView = [[UIImageView alloc] initWithImage:image];
                                          //imgView.contentMode = UIViewContentModeScaleAspectFit;
                                          [self.scrollView addSubview:imgView];
                                          [imgView mas_makeConstraints:^(MASConstraintMaker *make) {
                                              make.left.equalTo(self.scrollView).offset(originX);
                                              make.centerY.equalTo(self.scrollView);
                                              make.height.equalTo(@(itemHeight));
                                              make.width.equalTo(@(itemWidth));
                                          }];
                                          originX += itemWidth;
                                      } fail:^(NSString *error) {
                                          NSLog(@"截取帧失败: %@",error);
                                      }];
        });
    }
}

- (void)updateScrollViewContentOffsetWith:(CGFloat)progress {
    CGFloat scrollWidth = CGRectGetWidth(self.scrollView.bounds);
    CGFloat sizeWidth = self.scrollView.contentSize.width;
    
    CGFloat total = sizeWidth - scrollWidth;    //总进度
    CGFloat offsetX = progress * total;
    
    self.scrollView.contentOffset = CGPointMake(offsetX, self.scrollView.contentOffset.y);
}

# pragma mark - UIScrollViewDelegate
//滑动时跳转到该进度
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat scrollWidth = CGRectGetWidth(scrollView.bounds);
    CGFloat sizeWidth = scrollView.contentSize.width;
    
    CGFloat total = sizeWidth - scrollWidth;    //总进度
    CGFloat currentProgress = scrollView.contentOffset.x / total; //当前进度
    
    self.playBtn.selected = NO;
    
//    if (self.scrollViewDragBlock) {
//        self.scrollViewDragBlock(self.scrollView,currentProgress);
//    }
    [self.player jumpProgressWith:currentProgress];
}

- (void)dealloc {
    NSLog(@"dealloc: %@",[self class]);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
