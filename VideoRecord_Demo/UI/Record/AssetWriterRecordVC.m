//
//  AssetWriterRecordVC.m
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/9.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import "AssetWriterRecordVC.h"

#import "RecordView.h"
#import "CCRecordAssetWriter.h"

@interface AssetWriterRecordVC ()

@property(nonatomic,strong) CCRecordAssetWriter *assetWriterRecord;

@end

@implementation AssetWriterRecordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self createAssetWriterRecord];
    [self controlsCallback];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.recordView cancelProgressView];
}

- (void)createAssetWriterRecord {    
    NSString *path = [NSString stringWithFormat:@"%@/Documents/video.mp4",NSHomeDirectory()];
    unlink([path UTF8String]);  //删除已存在文件
    
    _assetWriterRecord = [[CCRecordAssetWriter alloc] initWithPath:path containerView:self.recordView.containerView];
    _assetWriterRecord.recordType = RecordVideo | RecordAudio;
    _assetWriterRecord.cameraInput = CameraInputFront;
    
    __weak typeof(self) weakSelf = self;
    _assetWriterRecord.startRecordBlock = ^(NSURL *fileURL) {
        NSLog(@"开始录制");
        [weakSelf hideForStartRecord:weakSelf.assetWriterRecord.recordStatus];
    };
    
    _assetWriterRecord.pauseRecordBlock = ^(NSURL *fileURL) {
        NSLog(@"暂停录制");
        [weakSelf hideForStartRecord:weakSelf.assetWriterRecord.recordStatus];
    };
    
    _assetWriterRecord.stopRecordBlock = ^(NSURL *fileURL) {
        NSLog(@"结束录制");
        [weakSelf hideForStartRecord:weakSelf.assetWriterRecord.recordStatus];
        AVPlayerVC *playVC = [[AVPlayerVC alloc] init];
        playVC.fileUrl = fileURL;
        [weakSelf presentViewController:playVC animated:YES completion:nil];
//        [weakSelf.navigationController pushViewController:playVC animated:YES];
    };
    [self.assetWriterRecord startRunning];
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
        if (flash) [weakSelf.assetWriterRecord switchFlashMode:AVCaptureTorchModeOn];
        else [weakSelf.assetWriterRecord switchFlashMode:AVCaptureTorchModeOff];
        flash = !flash;
    };
    self.recordView.delayBlock = ^(id obj) {
        //延迟
    };
    self.recordView.cameraBlock = ^(id obj) {
        //切换摄像头
        [weakSelf.assetWriterRecord switchCamera];
    };
    
    self.recordView.photoLibraryBlock = ^(id obj) {
        //打开相册
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
    };
    
    self.recordView.recordBlock = ^(id obj) {
        //录制
        if (weakSelf.assetWriterRecord.recordStatus == RecordStatusRecording) {
            [weakSelf.recordView pauseProgressView];
            [weakSelf.assetWriterRecord pauseRecording];
        }else {
            [weakSelf.recordView startProgressView];
            [weakSelf.assetWriterRecord startRecording];
        }
    };
    self.recordView.finishBlock = ^(id obj) {
        //完成
        [weakSelf.assetWriterRecord finishRecording];
    };
    self.recordView.cancelBlock = ^(id obj) {
        //取消
        NSLog(@"取消该段录制");
        [weakSelf.assetWriterRecord stopRecording];
        [weakSelf.assetWriterRecord cancelRecord];
        [weakSelf.recordView cancelProgressView];
        [weakSelf hideForStartRecord:weakSelf.assetWriterRecord.recordStatus];
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
