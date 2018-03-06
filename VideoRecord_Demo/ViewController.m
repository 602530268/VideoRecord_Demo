//
//  ViewController.m
//  VideoRecord_Demo
//
//  Created by chencheng on 2018/3/1.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import "ViewController.h"

#import "AVPlayerVC.h"
#import "GPUImagePlayerVC.h"

#import "FileOutputRecordVC.h"
#import "AssetWriterRecordVC.h"
#import "GPUImageRecordVC.h"

#import "VideoEditVC.h"

static NSString *TableViewCelIdentifier = @"TableViewCelIdentifier";
@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

@property(nonatomic,strong) UITableView *tableView;
@property(nonatomic,strong) NSMutableArray *datas;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    /*
     视频播放:
        AVFoundation
        GPUImage
     
     视频录制:
     AVFoundation:
        AVCaptureMovieFileOutput
        AVAssetWriter
     GPUImage:
     
     视频编辑页面:
        视频帧的获取
        视音频的剪辑
        视频配音
        视频添加水印
        视频添加滤镜(需要用GPUImage播放)
     */
    
    [self createUI];
    [self initData];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    });
}

- (void)createUI {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:TableViewCelIdentifier];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.size.equalTo(self.view);
    }];
}

- (void)initData {
    _datas = @[@[@"视频播放:AVFoundation",
                @"视频播放:GPUImage"],
               @[@"视频录制:AVCaptureMovieFileOutput",
                 @"视频录制:AVAssetWriter",
                 @"视频录制:GPUImage"],
               @[@"视频添加声音,水印，滤镜"],
               ].mutableCopy;
}

# pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_datas[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TableViewCelIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = _datas[indexPath.section][indexPath.row];
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _datas.count;
}

# pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *vc = nil;

    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                vc = [[AVPlayerVC alloc] init];
                break;
            case 1:
                vc = [[GPUImagePlayerVC alloc] init];
                break;
            default:
                break;
        }
    }else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                vc = [[FileOutputRecordVC alloc] init];
                break;
            case 1:
                vc = [[AssetWriterRecordVC alloc] init];
                break;
            case 2:
                vc = [[GPUImageRecordVC alloc] init];
            default:
                break;
        }
    }else if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 0:
                vc = [[VideoEditVC alloc] init];
                break;
            default:
                break;
        }
    }
    
    if (!vc) return;
    
    vc.title = _datas[indexPath.section][indexPath.row];
    if (indexPath.section == 0 || indexPath.section == 2) {
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        [self presentViewController:vc animated:YES completion:nil];
    }
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
