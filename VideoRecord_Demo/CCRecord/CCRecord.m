//
//  CCRecord.m
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/3.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import "CCRecord.h"

@interface CCRecord ()

@property(nonatomic,strong) AVCaptureDeviceInput *backCameraInput;   //后置摄像头
@property(nonatomic,strong) AVCaptureDeviceInput *frontCameraInput;  //前置摄像头

@end

@implementation CCRecord

//创建录制对象
- (instancetype)initWithPath:(NSString *)path containerView:(UIView *)containerView {
    return [self initWithURL:[NSURL fileURLWithPath:path] containerView:containerView];
}

- (instancetype)initWithURL:(NSURL *)url containerView:(UIView *)containerView {
    if (self = [super init]) {
        _fileUrl = url;
        _recordType = RecordVideo;
        _cameraInput = CameraInputBack;
        self.containerView = containerView;
    }
    return self;
}


# pragma mark - Record
- (void)startRunning {
    [self.session startRunning];
}
- (void)stopRunning {
    [self.session stopRunning];
}

# pragma mark - Recording
- (void)startRecording {}
- (void)stopRecording {}
- (void)pauseRecording {}

- (void)finishRecording {
    self.recordStatus = RecordStatusRecordFinish;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:self.fileUrl.path]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.stopRecordBlock) {
                self.stopRecordBlock(self.fileUrl);
            }
        });
        NSLog(@"视频录制文件已存在,%@",self.fileUrl.path);
        return;
    }
    
    NSLog(@"videos: %@",self.videoArr);
    
    [CCRecordTool videoCompositionWith:self.videoArr
                                outputUrl:self.fileUrl
                                  success:^(NSURL *url) {
                                      NSLog(@"完成视频录制: %@",url);
                                      
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          [self cancelRecord];
                                          if (self.stopRecordBlock) {
                                              self.stopRecordBlock(url);
                                          }
                                      });
                                  } fail:^(NSString *error) {
                                      NSLog(@"录制失败: %@",error);
                                  }];
}

# pragma mark - Add device puts
- (void)addDeviceInput:(AVCaptureInput *)input {
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }
}

- (void)addDeviceOutput:(AVCaptureOutput *)output {
    if ([self.session canAddOutput:output]) {
        [self.session addOutput:output];
    }
}

# pragma mark - Other
- (NSURL *)abailableFileUrl {
    
    NSString *filePaths = [NSString stringWithFormat:@"%@/Documents/cc_tmp_videos",NSHomeDirectory()];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePaths]) {
        [fileManager createDirectoryAtPath:filePaths withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    static NSString *tmpFileName = @"cc_video_file";
    NSString *path = [NSString stringWithFormat:@"%@/Documents/cc_tmp_videos/%@%ld.mp4",NSHomeDirectory(),tmpFileName,self.videoArr.count];
    return [NSURL fileURLWithPath:path];
}

- (void)cancelRecord {

    NSLog(@"删除初始视频文件");
    
    @synchronized(self) {
        [_videoArr removeAllObjects];
        _videoArr = @[].mutableCopy;
        
        NSString *path = [NSString stringWithFormat:@"%@/Documents/cc_tmp_videos",NSHomeDirectory()];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        [fileManager removeItemAtPath:path error:&error];
        if (error) {
            NSLog(@"删除失败，error：%@",error);
        }
    }
}

//开始写入前需要判断路径是否已存在，路径已存在的话是无法写入的，
- (void)removeFilePathIfExist:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        [fileManager removeItemAtPath:path error:&error];
        if (error) {
            NSLog(@"文件存在但是删除失败: %@",error);
        }
    }
}

# pragma mark - Tools
//切换闪光灯模式
- (void)switchFlashMode:(AVCaptureTorchMode)mode {
    if (!self.videoInput) return;
    
    //前置摄像头没有闪光灯
    if ([self.videoInput.device hasTorch]) {
        [self.videoInput.device lockForConfiguration:nil];
        [self.videoInput.device setTorchMode:mode];
        [self.videoInput.device unlockForConfiguration];
    }
}

//切换摄像头
- (void)switchCamera {
    
    BOOL sessionRunning = self.session.isRunning;
    if (sessionRunning) {
        [self.session stopRunning];
    }
    
    AVCaptureDeviceInput *oldInput = nil;
    
    if ([self.session.inputs containsObject:_backCameraInput]) {
        oldInput = _backCameraInput;
        self.videoInput = self.frontCameraInput;
    }else if ([self.session.inputs containsObject:_frontCameraInput]) {
        oldInput = _frontCameraInput;
        self.videoInput = self.backCameraInput;
    }
    if (!oldInput && !self.videoInput) {
        NSLog(@"没有设置摄像头，无法切换");
        return;
    }
    
    //在session中切换input
    [self.session beginConfiguration];
    [self.session removeInput:oldInput];
    [self.session addInput:self.videoInput];
    [self.session commitConfiguration];
    
    if (sessionRunning) {
        [self.session startRunning];
    }
}

# pragma mark - Setter/Getter
- (void)setContainerView:(UIView *)containerView {
    _containerView = containerView;
    
    if (_previewLayer != nil) {
        [_previewLayer removeFromSuperlayer];
        _previewLayer = nil;
    }
    [_containerView.superview layoutIfNeeded];
    self.previewLayer.frame = _containerView.bounds;
    [_containerView.layer addSublayer:self.previewLayer];
}

# pragma mark - Lazy load
- (AVCaptureSession *)session {
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
        /*
         sessionPreset:
         AVCaptureSessionPresetHigh: 高分辨率, 最终效果根据设备不同有所差异
         AVCaptureSessionPresetMedium: 中等分辨率, 适合Wi-Fi分享. 最终效果根据设备不同有所差异
         AVCaptureSessionPresetLow: 低分辨率, 适合3G分享, 最终效果根据设备不同有所差异
         AVCaptureSessionPreset640x480: 640x480, VGA
         AVCaptureSessionPreset1280x720: 1280x720, 720p HD
         AVCaptureSessionPresetPhoto: 全屏照片, 不能用来作为输出视频
         */
        if (![_session canSetSessionPreset:AVCaptureSessionPresetMedium]) {
            _session.sessionPreset = AVCaptureSessionPresetHigh;  //默认高画质
        }
    }
    return _session;
}

- (AVCaptureDeviceInput *)videoInput {
    if (!_videoInput) {
        if (_cameraInput == CameraInputBack) {
            _videoInput = self.backCameraInput;
        }else {
            _videoInput = self.frontCameraInput;
        }
    }
    return _videoInput;
}

- (AVCaptureDeviceInput *)audioInput {
    if (!_audioInput) {
        NSError *error = nil;
        AVCaptureDevice *mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        _audioInput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:&error];
        if (error) {
            NSLog(@"获取麦克风失败");
        }
    }
    return _audioInput;
}

//视频预览view
- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (!_previewLayer) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _previewLayer;
}

//后置摄像头输入
- (AVCaptureDeviceInput *)backCameraInput {
    if (!_backCameraInput) {
        NSError *error = nil;
        _backCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:&error];
        if (error) {
            NSLog(@"获取后置摄像头失败");
        }
    }
    return _backCameraInput;
}

//前置摄像头输入
- (AVCaptureDeviceInput *)frontCameraInput {
    if (!_frontCameraInput) {
        NSError *error = nil;
        _frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:&error];
        if (error) {
            NSLog(@"获取前置摄像头失败");
        }
    }
    return _frontCameraInput;
}

- (NSURL *)fileUrl {
    if (!_fileUrl) {
        //默认放到tmp文件夹内
        NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
        NSString *path = [NSString stringWithFormat:@"%@/%ld.mp4",NSTemporaryDirectory(),(NSInteger)(current)];
        _fileUrl = [NSURL fileURLWithPath:path];
    }
    return _fileUrl;
}

- (NSMutableArray *)videoArr {
    if (!_videoArr) {
        _videoArr = @[].mutableCopy;
    }
    return _videoArr;
}

//后置摄像头
- (AVCaptureDevice *)backCamera {
    return [self getCameraWithPosition:AVCaptureDevicePositionBack];
}

//前置摄像头
- (AVCaptureDevice *)frontCamera {
    return [self getCameraWithPosition:AVCaptureDevicePositionFront];
}

//返回指定设备
- (AVCaptureDevice *)getCameraWithPosition:(AVCaptureDevicePosition)position {
    
#if __IPHONE_10_0
    AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
    NSArray *devices = discoverySession.devices;
#else
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
#endif
    
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

@end
