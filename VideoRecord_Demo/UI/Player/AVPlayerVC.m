//
//  AVPlayerVC.m
//  VideoRecord_Demo
//
//  Created by chencheng on 2018/3/1.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import "AVPlayerVC.h"
#import "CCPlayer.h"
#import "CCRecord.h"

@interface AVPlayerVC ()

@property(nonatomic,strong) CCPlayer *player;

@end

@implementation AVPlayerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    if (self.fileUrl == nil) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Movie.m4v" ofType:nil];
        self.fileUrl = [NSURL fileURLWithPath:path];
    }
    
    [self createCCPlayer];
    [self controlsCallback];
}

- (void)createCCPlayer {
    
    NSLog(@"创建播放器对象: %@",self.fileUrl);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.fileUrl.path]) {
        NSLog(@"文件不存在~~~");
    }
    
    _player = [[CCPlayer alloc] initWithURL:self.fileUrl];
    _player.containerView = self.containerView;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.playBtn.selected = YES;
        [_player play];
    });
    [self playerCallback];
}

- (void)controlsCallback {
    CCWeakSelf(weakSelf)
    self.playEventBlock = ^(UIButton *btn) {
        if (btn.selected) {
            [weakSelf.player play];
        }else {
            [weakSelf.player pause];
        }
    };
    
    self.sliderDragBlock = ^(CGFloat currentProgress) {
        [weakSelf.player jumpProgressWith:currentProgress];
    };
}

- (void)playerCallback {
    CCWeakSelf(weakSelf)
    _player.playBlock = ^{
        
    };
    _player.pauseBlock = ^{
        
    };
    _player.finishBlock = ^{
        
    };
    _player.progressBlock = ^(CGFloat progress, CGFloat currentTime, CGFloat totalTime) {
        weakSelf.slider.value = progress;
    };
    _player.bufferBlock = ^(CGFloat progress) {
        
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
