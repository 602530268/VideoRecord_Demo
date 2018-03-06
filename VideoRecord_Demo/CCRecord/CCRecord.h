//
//  CCRecord.h
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/3.
//  Copyright © 2018年 double chen. All rights reserved.
//

/*
 录制功能封装
 视频录制:
    默认不带音频，可以设置视频画质、尺寸、录制方向，回调必要参数(开始、暂停、停止、视频帧)
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "CCRecordHeader.h"
#import "CCRecordTool.h"

typedef NS_OPTIONS(NSInteger,RecordContain) {
    RecordVideo = 1 << 0,    //视频录制,default
    RecordAudio = 1 << 1,
};

@interface CCRecord : NSObject

@property(nonatomic,strong) UIView *containerView;  //视频装载

@property(nonatomic,strong) NSMutableArray *videoArr;   //视频数组，录制完成后拼接成一个视频
@property(nonatomic,strong) NSURL *fileUrl; //视频存放路径

@property(nonatomic,assign) RecordContain recordType;   //视频音频的选择
@property(nonatomic,assign) CameraInput cameraInput;    //摄像头输入,前置或后置
@property(nonatomic,assign) RecordStatus recordStatus;  //录制状态

@property(nonatomic,strong) AVCaptureSession *session;
@property(nonatomic,strong) AVCaptureVideoPreviewLayer *previewLayer;
@property(nonatomic,strong) AVCaptureDeviceInput *videoInput;
@property(nonatomic,strong) AVCaptureDeviceInput *audioInput;

@property(nonatomic,copy) StartRecordCallback startRecordBlock;
@property(nonatomic,copy) StopRecordCallback stopRecordBlock;
@property(nonatomic,copy) PauseRecordCallback pauseRecordBlock;

//创建录制对象
- (instancetype)initWithPath:(NSString *)path containerView:(UIView *)containerView;
- (instancetype)initWithURL:(NSURL *)url containerView:(UIView *)containerView;

# pragma mark - Tools
//切换摄像头
- (void)switchCamera;

//切换闪光灯模式
- (void)switchFlashMode:(AVCaptureTorchMode)mode;

# pragma mark - Running
- (void)startRunning;   //开始采集
- (void)stopRunning;    //停止采集

# pragma mark - Recording
- (void)startRecording; //开始录制
- (void)stopRecording;  //停止录制
- (void)pauseRecording; //暂停录制
- (void)finishRecording;   //完成录制

# pragma mark - Add device puts
- (void)addDeviceInput:(AVCaptureInput *)input;
- (void)addDeviceOutput:(AVCaptureOutput *)output;

# pragma mark - Other
- (NSURL *)abailableFileUrl;    //获取一个可用的文件路径
- (void)cancelRecord;   //取消录制
- (void)removeFilePathIfExist:(NSString *)path; //删除已存在文件

@end
