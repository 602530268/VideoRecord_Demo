//
//  GPUImagePlayerVC.m
//  VideoRecord_Demo
//
//  Created by chencheng on 2018/3/1.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import "GPUImagePlayerVC.h"
#import "CCRecord.h"

@interface GPUImagePlayerVC ()

@property(nonatomic,strong) GPUImageMovie *gpuMovie;    //接收视频数据
@property(nonatomic,strong) GPUImageView *gpuImageView; //预览视频内容
@property(nonatomic,strong) GPUImageOutput<GPUImageInput> *filter;  //视频滤镜

@end

@implementation GPUImagePlayerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (self.fileUrl == nil) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Movie.m4v" ofType:nil];
        self.fileUrl = [NSURL fileURLWithPath:path];
    }
    
    //GPUImage预览视频不支持播放声音，请自行添加AVPlayer进行播放
    dispatch_async(dispatch_get_main_queue(), ^{
        _gpuImageView = [[GPUImageView alloc] init];
        [self.containerView addSubview:_gpuImageView];
        [_gpuImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.containerView);
            make.size.equalTo(self.containerView);
        }];
        
        _gpuMovie = [[GPUImageMovie alloc] initWithURL:self.fileUrl];
        _gpuMovie.shouldRepeat = YES;   //循环播放
        [_gpuMovie addTarget:_gpuImageView];
        
        [_gpuMovie startProcessing];
    });
    
    [self controlsCallback];
    
    self.playBtn.hidden = YES;
    self.slider.hidden = YES;
}


- (void)controlsCallback {
//    CCWeakSelf(weakSelf)
    self.playEventBlock = ^(UIButton *btn) {
        if (btn.selected) {

        }else {

        }
    };
    
    self.sliderDragBlock = ^(CGFloat currentProgress) {

    };
    
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
