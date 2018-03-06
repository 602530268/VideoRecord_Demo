//
//  FileOutputRecordVC.m
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/9.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import "FileOutputRecordVC.h"

#import "RecordView.h"
#import "CCRecordFileOutput.h"

@interface FileOutputRecordVC ()

@property(nonatomic,strong) CCRecordFileOutput *fileOutputRecord;

@end

@implementation FileOutputRecordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self createFileOutputRecord];
    [self controlsCallback];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.recordView cancelProgressView];
}

- (void)createFileOutputRecord {
    NSString *path = [NSString stringWithFormat:@"%@/Documents/video.mp4",NSHomeDirectory()];
    unlink([path UTF8String]);  //删除已存在文件
    
    _fileOutputRecord = [[CCRecordFileOutput alloc] initWithPath:path containerView:self.recordView.containerView];
    _fileOutputRecord.recordType = RecordVideo | RecordAudio;
    [self.view layoutIfNeeded];
    _fileOutputRecord.cameraInput = CameraInputFront;
//    _fileOutputRecord.containerView = self.recordView.containerView;
    
    CCWeakSelf(weakSelf)
    _fileOutputRecord.startRecordBlock = ^(NSURL *fileURL) {
        NSLog(@"开始录制");
        [weakSelf hideForStartRecord:weakSelf.fileOutputRecord.recordStatus];
    };
    
    _fileOutputRecord.pauseRecordBlock = ^(NSURL *fileURL) {
        NSLog(@"暂停录制");
        [weakSelf hideForStartRecord:weakSelf.fileOutputRecord.recordStatus];
    };
    
    _fileOutputRecord.stopRecordBlock = ^(NSURL *fileURL) {
        NSLog(@"结束录制");
        [weakSelf hideForStartRecord:weakSelf.fileOutputRecord.recordStatus];
        AVPlayerVC *playVC = [[AVPlayerVC alloc] init];
        playVC.fileUrl = fileURL;
        [weakSelf presentViewController:playVC animated:YES completion:nil];
//        [weakSelf.navigationController pushViewController:playVC animated:YES];
    };
    
    [_fileOutputRecord startRunning];
}

- (void)controlsCallback {
    __weak typeof(self) weakSelf = self;
    self.recordView.closeBlock = ^(id obj) {
        //返回
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    };
    self.recordView.flashBlock = ^(id obj) {
        //闪光灯
        static BOOL flash = YES;
        if (flash) [weakSelf.fileOutputRecord switchFlashMode:AVCaptureTorchModeOn];
        else [weakSelf.fileOutputRecord switchFlashMode:AVCaptureTorchModeOff];
        flash = !flash;
    };
    self.recordView.delayBlock = ^(id obj) {
        //延迟
    };
    self.recordView.cameraBlock = ^(id obj) {
        //切换摄像头
        [weakSelf.fileOutputRecord switchCamera];
    };
    
    self.recordView.photoLibraryBlock = ^(id obj) {
        //打开相册
    };
    self.recordView.seconds15Block = ^(id obj) {
        //最大录制时间15秒
    };
    self.recordView.seconds60Block = ^(id obj) {
        //最大录制时间60秒
    };
    
    self.recordView.specialEffectsBlock = ^(id obj) {
        //特效
    };
    self.recordView.filterBlock = ^(id obj) {
        //滤镜
    };
    
    self.recordView.recordBlock = ^(id obj) {
        //录制
        if (weakSelf.fileOutputRecord.recordStatus == RecordStatusRecording) {
            [weakSelf.recordView pauseProgressView];
            [weakSelf.fileOutputRecord pauseRecording];
        }else {
            [weakSelf.recordView startProgressView];
            [weakSelf.fileOutputRecord startRecording];
        }
    };
    self.recordView.finishBlock = ^(id obj) {
        //完成
        [weakSelf.fileOutputRecord finishRecording];
    };
    
    self.recordView.cancelBlock = ^(id obj) {
        //取消
        NSLog(@"取消该段录制");
        [weakSelf.fileOutputRecord stopRecording];
        [weakSelf.fileOutputRecord cancelRecord];
        [weakSelf.recordView cancelProgressView];
        [weakSelf hideForStartRecord:weakSelf.fileOutputRecord.recordStatus];
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
