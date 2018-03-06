//
//  CCRecordAssetWriter.m
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/3.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import "CCRecordAssetWriter.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <GPUImage.h>

@interface CCRecordAssetWriter ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
{
    BOOL _canWrite;
    NSURL *_currentUrl; //当前录制文件的路径
    
    CGFloat _videoWidth;
    CGFloat _videoHeight;
}

/*
 设备输出时需要控制在同一个线程内
 */
@property(nonatomic,strong) dispatch_queue_t recordQueue;
@property(nonatomic,strong) AVCaptureVideoDataOutput *videoOutput;
@property(nonatomic,strong) AVCaptureAudioDataOutput *audioOutput;

@property(nonatomic,strong) AVCaptureConnection *fileConnection;

@property(nonatomic,strong) AVAssetWriter *assetWriter;
@property(nonatomic,strong) AVAssetWriterInput *assetWriterVideoInput;
@property(nonatomic,strong) AVAssetWriterInput *assetWriterAudioInput;

@property(nonatomic,strong) NSDictionary *videoWriterSetting;   //视频属性
@property(nonatomic,strong) NSDictionary *audioWriterSetting;   //音频属性

@end

@implementation CCRecordAssetWriter

# pragma mark - Super
- (void)startRunning {

    //播放前的设置
    //视频
    if (self.recordType & RecordVideo) {
        [self addDeviceInput:self.videoInput];
        [self addDeviceOutput:self.videoOutput];
        
        //预览图层和视频方向保持一致
        self.fileConnection.videoOrientation = self.previewLayer.connection.videoOrientation;
    }
    //音频
    if (self.recordType & RecordAudio) {
        [self addDeviceInput:self.audioInput];
        [self addDeviceOutput:self.audioOutput];
    }
    
    [self.session startRunning];
    
    _videoWidth = CGRectGetWidth(self.containerView.bounds);
    _videoHeight = CGRectGetHeight(self.containerView.bounds);
}

- (void)initializeAssetWriter {

    if (self.videoArr.count == 0) {
        [self cancelRecord];
    }
    
    _currentUrl = [self abailableFileUrl];
    NSLog(@"获取可用的文件路径: %@",_currentUrl);
    
    //必须删除已存在的路径，否则无法写入
    unlink([self.fileUrl.path UTF8String]);
    
    NSString *path = _currentUrl.path;
    unlink([path UTF8String]);
    
    self.recordStatus = RecordStatusNone;
    
    //视频
    if (self.recordType & RecordVideo) {
        if ([self.assetWriter canAddInput:self.assetWriterVideoInput]) {
            [self.assetWriter addInput:self.assetWriterVideoInput];
        }
    }
    //音频
    if (self.recordType & RecordAudio) {
        if ([self.assetWriter canAddInput:self.assetWriterAudioInput]) {
            [self.assetWriter addInput:self.assetWriterAudioInput];
        }
    }
}

- (void)stopRunning {
    [self stopRecording];
    [self.session stopRunning];
}

- (void)startRecording {
    
    dispatch_async(self.recordQueue, ^{

        _canWrite = YES;
        
        if (_assetWriter == nil) {
            [self initializeAssetWriter];
        }
        
        if (self.recordStatus == RecordStatusRecordPause) {
            self.recordStatus = RecordStatusRecording;
            return;  //属于恢复录制
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.recordStatus = RecordStatusRecording;
            if (self.startRecordBlock) {
                self.startRecordBlock(_currentUrl);
            }
        });
    });
}

- (void)pauseRecording {
    dispatch_async(self.recordQueue, ^{
        self.recordStatus = RecordStatusRecordPause;
        [self stopRecording];
    });
}

- (void)stopRecording {
    
    dispatch_async(self.recordQueue, ^{
        _canWrite = NO;
        if (![self.videoArr containsObject:_currentUrl] && _currentUrl) {
            [self.videoArr addObject:_currentUrl];
        }
        
        [self stopWrite];
    });
}

- (void)finishRecording {
    self.recordStatus = RecordStatusRecordFinish;
    [self stopRecording];
}

# pragma mark - Delegate
//在这里可以获取视频帧，可以在此实现滤镜等效果
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (sampleBuffer == NULL) {
        NSLog(@"empty sampleBuffer");
        return;
    }
    
    if (_canWrite == NO) {
        return;
    }
    
    if (connection == [_videoOutput connectionWithMediaType:AVMediaTypeVideo]) {
        //视频
        
        if (self.videoImageBlock) {
            UIImage *img = [self imageFromSampleBuffer:sampleBuffer];
            self.videoImageBlock(img);
        }
        if (self.videoDataBlock) {
            UIImage *img = [self imageFromSampleBuffer:sampleBuffer];
            NSData *data = UIImageJPEGRepresentation(img, 1.0f);
            self.videoDataBlock(data);
        }
        if (self.sampleBufferBlock) {
            self.sampleBufferBlock(sampleBuffer);
        }
        
        if (_assetWriter == nil) {
            NSLog(@"_assetWriter 为空.");
            [self destoryWrite];
            return;
        }
        
        if (_assetWriter.status == AVAssetWriterStatusFailed) {
            NSLog(@"Error: %@", _assetWriter.error);
            [self stopWrite];
            return;
        }
        
        if (_assetWriter.status == AVAssetWriterStatusUnknown) {
            NSLog(@"开始写入");
            [_assetWriter startWriting];
            [_assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        }
        
        if (_assetWriterVideoInput.readyForMoreMediaData) {
            BOOL success = [_assetWriterVideoInput appendSampleBuffer:sampleBuffer];    //如果报错请检查是否已存在文件
            if (!success) {
                NSLog(@"append sampleBuffer fail~");
                
                @synchronized(self) {
                    [self stopRecording];
                }
            }
        }
    }
    
    if (connection == [_audioOutput connectionWithMediaType:AVMediaTypeAudio]) {
        //音频
        if (self.assetWriterAudioInput.readyForMoreMediaData) {
            BOOL success = [_assetWriterAudioInput appendSampleBuffer:sampleBuffer];
            if (!success) {
                NSLog(@"append sampleBuffer fail~");
                @synchronized(self) {
                    [self stopRecording];
                }
            }
        }
    }
    
}

//- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
//    NSLog(@"丢失帧");
//}

# pragma mark - APIs (private)
- (void)stopWrite {
    
    dispatch_async(self.recordQueue, ^{
        if (_assetWriter) {
            [_assetWriter finishWritingWithCompletionHandler:^{
                [self destoryWrite];
            }];
        }else {
            NSLog(@"writer对象为空");
        }
        
        if ((self.recordStatus == RecordStatusRecordPause)) { 
            if (self.pauseRecordBlock) {
                self.pauseRecordBlock(self.fileUrl);
            }
        }
        
        if (self.recordStatus == RecordStatusRecordFinish) {
            [super finishRecording];
        }
    });

}

/*
 writer对象只能使用一次，再次写入需要重新创建对象，参考链接:
 https://stackoverflow.com/questions/4911534/avassetwriter-multiple-sessions-and-the-status-property
*/
- (void)destoryWrite {
    dispatch_async(self.recordQueue, ^{
        @synchronized(self) {
            _assetWriter = nil;
            _assetWriterVideoInput = nil;
            _assetWriterAudioInput = nil;
            NSLog(@"摧毁写入对象~");
            self.recordStatus = RecordStatusNone;
        }
    });
}

//CMSampleBufferRef转UIImage
-(UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    // 释放context和颜色空间
    CGContextRelease(context); CGColorSpaceRelease(colorSpace);
    // 用Quartz image创建一个UIImage对象image
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1 orientation:UIImageOrientationUp];
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    return (image);
}

# pragma mark - Lazy load
- (dispatch_queue_t)recordQueue {
    if (!_recordQueue) {
        _recordQueue = dispatch_queue_create("media_writer", DISPATCH_QUEUE_SERIAL);
    }
    return _recordQueue;
}

- (AVCaptureVideoDataOutput *)videoOutput {
    if (!_videoOutput) {
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        _videoOutput.alwaysDiscardsLateVideoFrames = YES;   //立即丢弃旧帧，节省内存，默认YES
        
        //这里遇到个坑，在解析每帧数据的时候一直报CGBitmapContextCreate相关错误，加上下面代码就可以了，具体参考https://www.jianshu.com/p/61ca3a917fe5
        NSDictionary *videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
        [_videoOutput setVideoSettings:videoSettings];
        [_videoOutput setSampleBufferDelegate:self queue:self.recordQueue];
    }
    return _videoOutput;
}

- (AVCaptureAudioDataOutput *)audioOutput {
    if (!_audioOutput) {
        _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        [_audioOutput setSampleBufferDelegate:self queue:self.recordQueue];
    }
    return _audioOutput;
}

- (AVCaptureConnection *)fileConnection {
    if (!_fileConnection) {
        _fileConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
        //开启防抖，如果支持防抖就开启，有的用就用，实测效果还不错
        if ([_fileConnection isVideoStabilizationSupported]) {
            _fileConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
    }
    return _fileConnection;
}

- (AVAssetWriter *)assetWriter {
    if (!_assetWriter) {
        NSError *error = nil;
        NSURL *fileUrl = _currentUrl;
        [self removeFilePathIfExist:fileUrl.path];
        _assetWriter = [AVAssetWriter assetWriterWithURL:fileUrl fileType:AVFileTypeMPEG4 error:&error];
        if (error) {
            NSLog(@"writer对象创建失败: %@",error);
        }
    }
    return _assetWriter;
}

- (AVAssetWriterInput *)assetWriterVideoInput {
    if (!_assetWriterVideoInput) {
        _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoWriterSetting];
        _assetWriterVideoInput.expectsMediaDataInRealTime = YES;    //必须设为YES，否则会丢帧
    }
    return _assetWriterVideoInput;
}

- (AVAssetWriterInput *)assetWriterAudioInput {
    if (!_assetWriterAudioInput) {
        _assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:self.audioWriterSetting];
        _assetWriterAudioInput.expectsMediaDataInRealTime = YES;
    }
    return _assetWriterAudioInput;
}

- (NSDictionary *)videoWriterSetting {
    
    CGFloat videoWidth = _videoWidth;
    CGFloat videoHeight = _videoHeight;
    
    //写入视频大小
    NSInteger numPixels = videoWidth * videoHeight;
    
    //每像素比特
    CGFloat bitsPerPixel = 6.0f;
    NSInteger bitsPerSecond = numPixels * bitsPerPixel;
    
    /*
     码率和帧率设置
     AVVideoCodecKey 编码方式：H.264编码
     AVVideoExpectedSourceFrameRateKey 帧率：每秒钟多少帧画面 
     AVVideoAverageBitRateKey 码率：单位时间内保存的数据量,码率: 编码效率, 码率越高,则画面越清晰, 如果码率较低会引起马赛克 --> 码率高有利于还原原始画面,但是也不利于传输)
     AVVideoMaxKeyFrameIntervalKey 关键帧（GOPsize)间隔：多少帧为一个GOP,
     */
    NSDictionary *compresstionProperties = @{AVVideoAverageBitRateKey:@(bitsPerSecond),
                                             AVVideoExpectedSourceFrameRateKey:@(30),
                                             AVVideoMaxKeyFrameIntervalKey:@(30),
                                             AVVideoProfileLevelKey:AVVideoProfileLevelH264BaselineAutoLevel,
                                             };
    
    return @{AVVideoCodecKey:AVVideoCodecH264,
             AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill,
             AVVideoWidthKey:@(videoWidth),
             AVVideoHeightKey:@(videoHeight),
             AVVideoCompressionPropertiesKey:compresstionProperties,
             };
}

- (NSDictionary *)audioWriterSetting {
    return @{AVEncoderBitRatePerChannelKey:@(28000),
             AVFormatIDKey:@(kAudioFormatMPEG4AAC),
             AVNumberOfChannelsKey:@(1),
             AVSampleRateKey:@(22050),
             };
}

@end
