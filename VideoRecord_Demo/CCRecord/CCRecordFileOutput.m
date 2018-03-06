//
//  CCRecordFileOutput.m
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/3.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import "CCRecordFileOutput.h"

@interface CCRecordFileOutput ()<AVCaptureFileOutputRecordingDelegate>

@property(nonatomic,strong) AVCaptureMovieFileOutput *fileOutput;
@property(nonatomic,strong) AVCaptureConnection *fileConnection;

@end

@implementation CCRecordFileOutput

# pragma mark - Super
- (void)startRunning {
    //播放前的设置
    if (self.recordType & RecordVideo) {
        [self addDeviceInput:self.videoInput];
    }
    if (self.recordType & RecordAudio) {
        [self addDeviceInput:self.audioInput];
    }
    if ([self.session canAddOutput:self.fileOutput]) {
        [self.session addOutput:self.fileOutput];
    }
    
    //预览图层和视频方向保持一致
    self.fileConnection.videoOrientation = [self.previewLayer connection].videoOrientation;
    
    [self.session startRunning];
}

- (void)stopRunning {
    [super stopRunning];
}

//开始录制
- (void)startRecording {
    NSLog(@"startRecording");
    
    //在session运行后以及不在录制状态时才能进行录制
    if ([self.session isRunning] && self.fileOutput.isRecording == NO) {
        self.recordStatus = RecordStatusRecording;
        unlink([self.fileUrl.path UTF8String]);
        NSURL *fileUrl = [self abailableFileUrl];
        unlink([fileUrl.path UTF8String]);
        [self.fileOutput startRecordingToOutputFileURL:fileUrl recordingDelegate:self];
    }else {
        NSAssert([self.session isRunning], @"session must be running");
    }
}

//暂停录制
- (void)pauseRecording {
    NSLog(@"pauseRecording");
    self.recordStatus = RecordStatusRecordPause;
    [self.fileOutput stopRecording];
}

//停止录制
- (void)stopRecording {
    NSLog(@"stopRecording");
    if (self.fileOutput.isRecording == YES) {
        [self.fileOutput stopRecording];
    }else {
        [super finishRecording];
    }
}

//完成录制
- (void)finishRecording {
    NSLog(@"finishRecording");
    self.recordStatus = RecordStatusRecordFinish;
    [self stopRecording];
}

# pragma mark - Lazy load
- (AVCaptureMovieFileOutput *)fileOutput {
    if (!_fileOutput) {
        _fileOutput = [[AVCaptureMovieFileOutput alloc] init];
    }
    return _fileOutput;
}

- (AVCaptureConnection *)fileConnection {
    if (!_fileConnection) {
        _fileConnection = [self.fileOutput connectionWithMediaType:AVMediaTypeVideo];
        //开启防抖，如果支持防抖就开启，有的用就用，实测效果还不错
        if ([_fileConnection isVideoStabilizationSupported]) {
            _fileConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
    }
    return _fileConnection;
}

# pragma mark - AVCaptureFileOutputRecordingDelegate
//开始录制回调函数
- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    NSLog(@"didStartRecordingToOutputFileAtURL");
    self.recordStatus = RecordStatusRecording;
    if (self.startRecordBlock) {
        self.startRecordBlock(fileURL);
    }
}

//结束录制回调函数，注意，[self.session stopRunning]将会停止录制
- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(nullable NSError *)error {
    NSLog(@"didFinishRecordingToOutputFileAtURL");
    
    if (![self.videoArr containsObject:outputFileURL]) {
        [self.videoArr addObject:outputFileURL];
    }
    
    if ((self.recordStatus == RecordStatusRecordPause)) { 
        if (self.pauseRecordBlock) {
            self.pauseRecordBlock(self.fileUrl);
        }
    }
    
    if ((self.recordStatus == RecordStatusRecordFinish)) { //停止录制
        [super finishRecording];
    }
}


@end
