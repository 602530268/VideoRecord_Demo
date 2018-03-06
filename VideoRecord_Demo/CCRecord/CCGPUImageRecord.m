//
//  CCGPUImageRecord.m
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/10.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import "CCGPUImageRecord.h"
#import <GPUImage.h>

@interface CCGPUImageRecord ()
{
    NSURL *_currentUrl;
}

@property(nonatomic,strong) GPUImageVideoCamera *videoCamera;
@property(nonatomic,strong) GPUImageView *preView;
@property(nonatomic,strong) GPUImageFilterGroup *filterGroup;
@property(nonatomic,strong) GPUImageMovieWriter *movieWriter;

@property(nonatomic,strong) NSMutableArray *filters;

@end

@implementation CCGPUImageRecord

//创建录制对象
- (instancetype)initWithURL:(NSURL *)url containerView:(UIView *)containerView {
    if (self = [super initWithURL:url containerView:containerView]) {
        [self initializedCamera];
        [self setupContainerView:containerView];
    }
    return self;
}

- (void)initializedCamera {
    //视频源
    _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionFront];
    _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    _videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    
    //解决开始录制时相机闪烁的问题。在初始化时就添加声音输入
    [_videoCamera addAudioInputsAndOutputs];
    
    //滤镜组
    _filterGroup = [[GPUImageFilterGroup alloc] init];
    
    //滤镜
//    GPUImageBilateralFilter *bilateralFilter = [[GPUImageBilateralFilter alloc] init];  //磨皮滤镜
//    GPUImageBrightnessFilter *brightnessFilter = [[GPUImageBrightnessFilter alloc] init];   //美白滤镜
//
//    [self addGPUImageFilter:bilateralFilter filterGroup:_filterGroup];
//    [self addGPUImageFilter:brightnessFilter filterGroup:_filterGroup];
//
////    [_videoCamera addTarget:self.preView];
//
//    [_videoCamera addTarget:_filterGroup];
//    [_filterGroup addTarget:self.preView];
    
    _filters = @[].mutableCopy;
    [self updateCamera];
}

- (void)resetMovieWriter {
    if (_movieWriter) _movieWriter = nil;
    
    NSURL *url = [self abailableFileUrl];
    unlink([url.path UTF8String]);
    unlink([self.fileUrl.path UTF8String]);
    
    _currentUrl = url;
    
    _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:url size:self.preView.bounds.size];
    _movieWriter.encodingLiveVideo = YES;
    
//    [_videoCamera addTarget:_movieWriter];
//    [_filterGroup addTarget:_movieWriter];
    _videoCamera.audioEncodingTarget = _movieWriter;
}

# pragma mark - Tools
//切换摄像头
- (void)switchCamera {
    [self.videoCamera rotateCamera];
    if (self.videoCamera.inputCamera.position == AVCaptureDevicePositionBack) {
        self.cameraInput = CameraInputBack;
    }else {
        self.cameraInput = CameraInputFront;
    }
}

//切换闪光灯模式
- (void)switchFlashMode:(AVCaptureTorchMode)mode {
    //前置摄像头没有闪光灯
    if ([self.videoCamera.inputCamera hasTorch]) {
        [self.videoCamera.inputCamera lockForConfiguration:nil];
        [self.videoCamera.inputCamera setTorchMode:mode];
        [self.videoCamera.inputCamera unlockForConfiguration];
    }
}

# pragma mark - Running
- (void)startRunning {
    [self.videoCamera startCameraCapture];  //开始采集
}

- (void)stopRunning {
    [self.videoCamera stopCameraCapture];   //停止采集
}

# pragma mark - Recording
- (void)startRecording {
    self.recordStatus = RecordStatusRecording;

    [self resetMovieWriter];
    [self addMovieWriter];
    
    _videoCamera.audioEncodingTarget = _movieWriter;
    [_movieWriter startRecording];
    
    if (self.startRecordBlock) {
        self.startRecordBlock(self.fileUrl);
    }
}

- (void)pauseRecording {
    self.recordStatus = RecordStatusRecordPause;
    [self stopRecording];
}

- (void)stopRecording {
    
    if (![self.videoArr containsObject:_currentUrl]) {
        [self.videoArr addObject:_currentUrl];
    }
    
    [self removeMovieWriter];
    
    _videoCamera.audioEncodingTarget = nil;
    [_movieWriter finishRecording];
    
    if (self.pauseRecordBlock) {
        self.pauseRecordBlock(self.fileUrl);
    }
    
    if (self.recordStatus == RecordStatusRecordFinish) {
        [super finishRecording];
    }
}

- (void)finishRecording {
    self.recordStatus = RecordStatusRecordFinish;
    [self stopRecording];
}

//更新滤镜
- (void)updateGPUImageFilters:(NSArray <GPUImageOutput<GPUImageInput> *>*)filters {
    
    NSLog(@"update filters: %@",filters);
    
    if (filters.count == 0) {
        [self removeAllFilters];
        [self updateCamera];
        return;
    }
    
    [self removeAllFilters];
    _filterGroup = [[GPUImageFilterGroup alloc] init];
    
    for (GPUImageOutput<GPUImageInput> *target in filters) {
        [self addGPUImageFilter:target filterGroup:_filterGroup];
    }
    
    [_filters addObjectsFromArray:filters];
    [_filterGroup useNextFrameForImageCapture];
    
    [self updateCamera];    
}

//移除所有滤镜
- (void)removeAllFilters {
    [_filterGroup removeAllTargets];
    [_filters removeAllObjects];
    _filters = @[].mutableCopy;
}

//更新相机
- (void)updateCamera {
    [_videoCamera removeAllTargets];
    if (_filters.count == 0) {
        [_videoCamera addTarget:self.preView];
    }else {
        [_videoCamera addTarget:_filterGroup];
        [_filterGroup addTarget:self.preView];
    }
}

//添加视频写入target
- (void)addMovieWriter {
    if (self.filters.count == 0) {
        [_videoCamera addTarget:_movieWriter];
    }else {
        [_filterGroup addTarget:_movieWriter];
    }
}

//移除视频写入target
- (void)removeMovieWriter {
    if (self.filters.count == 0) {
        [_videoCamera removeTarget:_movieWriter];
    }else {
        [_filterGroup removeTarget:_movieWriter];
    }
}

# pragma mark - Other
//添加滤镜到filterGroup中并且设置初始滤镜和末尾滤镜
- (void)addGPUImageFilter:(GPUImageOutput<GPUImageInput> *)filter filterGroup:(GPUImageFilterGroup *)filterGroup {
    [filterGroup addFilter:filter];
    GPUImageOutput<GPUImageInput> *newTerminalFilter = filter;
    NSInteger count = filterGroup.filterCount;
    //设置初始滤镜
    if (count == 1) {
        filterGroup.initialFilters = @[newTerminalFilter];
    }else {
        GPUImageOutput<GPUImageInput> *terminalFilter = filterGroup.terminalFilter;
        NSArray *initialFilters = filterGroup.initialFilters;
        [terminalFilter addTarget:newTerminalFilter];
        filterGroup.initialFilters = @[initialFilters[0]];
    }
    //设置末尾滤镜
    filterGroup.terminalFilter = newTerminalFilter;
}

//设置承载view
- (void)setupContainerView:(UIView *)containerView {
    if (self.preView.superview) {
        [self.preView removeFromSuperview];
    }
    [containerView addSubview:self.preView];
    [self.preView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(containerView);
        make.center.equalTo(containerView);
    }];
    [containerView layoutIfNeeded];
}

- (GPUImageView *)preView {
    if (!_preView) {
        _preView = [[GPUImageView alloc] init];
        _preView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    }
    return _preView;
}

@end
