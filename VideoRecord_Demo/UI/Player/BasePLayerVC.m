//
//  BasePLayerVC.m
//  VideoRecord_Demo
//
//  Created by chencheng on 2018/3/1.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import "BasePLayerVC.h"

#import "CCRecord.h"

@interface BasePLayerVC ()

@end

@implementation BasePLayerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self createUI];
}

- (void)createUI {
    
    self.view.backgroundColor = [UIColor blackColor];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;   //从导航栏底部开始计算坐标
    
    _containerView = [[UIView alloc] init];
    _containerView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_containerView];
    
    CGFloat containerViewHeight = SCREEN_HEIGHT * 0.6f;
    CGFloat containerViewWidth = SCREEN_WIDTH / SCREEN_HEIGHT * containerViewHeight;
    [_containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(20.0f);
        make.centerX.equalTo(self.view);
        make.width.equalTo(@(containerViewWidth));
        make.height.equalTo(@(containerViewHeight));
    }];
    
    _slider = [[UISlider alloc] init];
    [self.view addSubview:_slider];
    [_slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20.0f);
        make.right.equalTo(self.view).offset(-20.0f);
        make.bottom.equalTo(self.view);
        make.height.equalTo(@50.0f);
    }];
    _slider.layer.cornerRadius = 8.0f;
    [_slider addTarget:self action:@selector(sliderDragEvent:) forControlEvents:UIControlEventValueChanged];
    
    _playBtn = [[UIButton alloc] init];
    [self.view addSubview:_playBtn];
    [_playBtn setTitle:@"播放" forState:UIControlStateNormal];
    [_playBtn setTitle:@"暂停" forState:UIControlStateSelected];
    [_playBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_playBtn setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    [_playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20.0f);
        make.right.equalTo(self.view).offset(-20.0f);
        make.bottom.equalTo(self.slider.mas_top).offset(-10.0f);
        make.height.equalTo(@50.0f);
    }];
    _playBtn.layer.cornerRadius = 8.0f;
    
    [_playBtn addTarget:self action:@selector(playBtnEvent:) forControlEvents:UIControlEventTouchUpInside];

    _backBtn = [[UIButton alloc] init];
    [self.view addSubview:_backBtn];
    [_backBtn setTitle:@"返回" forState:UIControlStateNormal];
    [_playBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(10.0f);
        make.top.equalTo(self.view).offset(20.0f);
        make.width.equalTo(@(50.0f));
        make.height.equalTo(@30.0f);
    }];
    _backBtn.layer.cornerRadius = 8.0f;
    
    [_backBtn addTarget:self action:@selector(backBtnEvent:) forControlEvents:UIControlEventTouchUpInside];
    
    for (UIView *subView in self.view.subviews) {
        subView.backgroundColor = [UIColor lightGrayColor];
    }
}

# pragma mark - Interaction Event
- (void)playBtnEvent:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (self.playEventBlock) {
        self.playEventBlock(sender);
    }
}

- (void)backBtnEvent:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)sliderDragEvent:(UISlider *)sender {
    if (self.sliderDragBlock) {
        self.sliderDragBlock(sender.value);
    }
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
