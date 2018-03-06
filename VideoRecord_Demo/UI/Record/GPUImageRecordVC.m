//
//  GPUImageRecordVC.m
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/9.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import "GPUImageRecordVC.h"

#import "RecordView.h"
#import "CCGPUImageRecord.h"
#import "FiltersView.h"
#import "CCSystemCamera.h"

@interface GPUImageRecordVC ()
{
    NSURL *_fileURL;
}

@property(nonatomic,strong) GPUImageVideoCamera *videoCamera;
@property(nonatomic,strong) GPUImageView *preView;
@property(nonatomic,strong) GPUImageFilterGroup *filterGroup;
@property(nonatomic,strong) GPUImageMovieWriter *movieWriter;

@property(nonatomic,strong) CCGPUImageRecord *gpuRecord;

@end

@implementation GPUImageRecordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor blackColor];
    

    [self createGPUImageRecord];
    [self controlsCallback];
    [self filterViewControlsCallback];
    
    self.hideControls = @[self.recordView.closeBtn,
                      self.recordView.flashBtn,
                      self.recordView.delayBtn,
                      self.recordView.cameraBtn,
                      self.recordView.photoLibraryBtn,
                      self.recordView.seconds15Btn,
                      self.recordView.seconds60Btn,
                      self.recordView.specialEffectsBtn,
                      self.recordView.filterBtn,];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.recordView cancelProgressView];
}

- (void)filterViewControlsCallback {
    CCWeakSelf(weakSelf)
    self.filtersView.filterCallback = ^(id obj) {
        [weakSelf.gpuRecord updateGPUImageFilters:@[obj]];
    };
}

- (void)createGPUImageRecord {
    NSString *path = [NSString stringWithFormat:@"%@/Documents/video.mp4",NSHomeDirectory()];
    unlink([path UTF8String]);  //删除已存在文件
    _fileURL = [NSURL fileURLWithPath:path];
    
    CCWeakSelf(weakSelf)
    _gpuRecord = [[CCGPUImageRecord alloc] initWithURL:_fileURL containerView:self.recordView.containerView];
    [_gpuRecord startRunning];
    
    _gpuRecord.startRecordBlock = ^(NSURL *fileURL) {
        NSLog(@"开始录制");
        [weakSelf hideForStartRecord:weakSelf.gpuRecord.recordStatus];
    };
    _gpuRecord.pauseRecordBlock = ^(NSURL *fileURL) {
        NSLog(@"暂停录制");
        [weakSelf hideForStartRecord:weakSelf.gpuRecord.recordStatus];
    };
    _gpuRecord.stopRecordBlock = ^(NSURL *fileURL) {
        NSLog(@"结束录制");
        [weakSelf hideForStartRecord:weakSelf.gpuRecord.recordStatus];
        AVPlayerVC *playVC = [[AVPlayerVC alloc] init];
        playVC.fileUrl = fileURL;
        [weakSelf presentViewController:playVC animated:YES completion:nil];
//        [weakSelf.navigationController pushViewController:playVC animated:YES];
    };
}

- (void)controlsCallback {
    CCWeakSelf(weakSelf)
    self.recordView.closeBlock = ^(id obj) {
        //返回
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    };
    self.recordView.flashBlock = ^(id obj) {
        //闪光灯
        static BOOL flash = YES;
        if (flash) [weakSelf.gpuRecord switchFlashMode:AVCaptureTorchModeOn];
        else [weakSelf.gpuRecord switchFlashMode:AVCaptureTorchModeOff];
        flash = !flash;
    };
    self.recordView.delayBlock = ^(id obj) {
        //延迟
    };
    self.recordView.cameraBlock = ^(id obj) {
        //切换摄像头
        [weakSelf.gpuRecord switchCamera];
    };
    
    self.recordView.photoLibraryBlock = ^(id obj) {
        //打开相册,
        CCSystemCamera *camera = [CCSystemCamera shareInstance];
        camera.mediaTypes = @[(NSString *)kUTTypeMovie];
        [camera showPhotoLibraryWith:weakSelf photo:^(id obj) {
            NSLog(@"obj: %@",obj);
            NSDictionary *info = obj;
            NSURL *url = info[@"UIImagePickerControllerMediaURL"];
            NSLog(@"url: %@",url.path);
        } cancel:^{
            
        }];
    };
    self.recordView.seconds15Block = ^(id obj) {
        //最大录制时间15秒
        weakSelf.recordView.maxRecordTime = 15.0f;
    };
    self.recordView.seconds60Block = ^(id obj) {
        //最大录制时间60秒
        weakSelf.recordView.maxRecordTime = 60.0f;
    };
    
    self.recordView.specialEffectsBlock = ^(id obj) {
        //特效
    };
    self.recordView.filterBlock = ^(id obj) {
        //滤镜
        CGFloat offsetY = 0;
        CGFloat originY = CGRectGetMinY(weakSelf.filtersView.frame) + 1;
        if (originY > CGRectGetHeight(weakSelf.view.bounds)) {
            offsetY = 0;
        }else {
            offsetY = 150.0f;
        }
                
        [UIView animateWithDuration:0.25 animations:^{
            [weakSelf.filtersView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(weakSelf.view).offset(offsetY);
            }];
            [weakSelf.view layoutIfNeeded];
        }];
    };
    
    self.recordView.recordBlock = ^(id obj) {
        //录制
        if (weakSelf.gpuRecord.recordStatus == RecordStatusRecording) {
            [weakSelf.recordView pauseProgressView];
            [weakSelf.gpuRecord pauseRecording];
        }else {
            [weakSelf.recordView startProgressView];
            [weakSelf.gpuRecord startRecording];
        }
    };
    self.recordView.finishBlock = ^(id obj) {
        //完成
        NSLog(@"录制完成");
        [weakSelf.gpuRecord finishRecording];
    };
    self.recordView.cancelBlock = ^(id obj) {
      //取消
        NSLog(@"取消该段录制");
        [weakSelf.gpuRecord stopRecording];
        [weakSelf.gpuRecord cancelRecord];
        [weakSelf.recordView cancelProgressView];
        [weakSelf hideForStartRecord:weakSelf.gpuRecord.recordStatus];
    };
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
