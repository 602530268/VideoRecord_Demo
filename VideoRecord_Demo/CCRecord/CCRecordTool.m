//
//  CCRecordTool.m
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/27.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import "CCRecordTool.h"
#import <AVFoundation/AVFoundation.h>

@interface CCRecordTool ()

//@property(nonatomic,strong) dispatch_queue_t toolQueue;
//
# pragma mark - GPUImage
@property(nonatomic,strong) GPUImageMovie *movieFile;
@property(nonatomic,strong) GPUImageOutput<GPUImageInput> *filter;
@property(nonatomic,strong) GPUImageMovieWriter *movieWriter;

@end

@implementation CCRecordTool

+ (CCRecordTool *)shareInstance {
    static CCRecordTool *tool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tool = [[CCRecordTool alloc] init];
    });
    return tool;
}

//拼接视频片段
+ (void)videoCompositionWith:(NSArray <NSURL *> *)urls
                   outputUrl:(NSURL *)outputUrl
                     success:(void(^)(NSURL *url))success
                        fail:(void(^)(NSString *error))fail {
    
    unlink([outputUrl.path UTF8String]);    //移除已存在文件
    
    if (urls.count == 0) {
        NSLog(@"没有可以拼接的视频");
        if (fail) {
            fail(@"没有可以拼接的视频");
        }
        return;
    }
    
    if (urls.count == 1) {
        NSLog(@"只有一段视频，不需要拼接");
        if (success) {
//            success(urls.firstObject);
//            return;
            
            NSError *error = nil;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager moveItemAtURL:urls.firstObject toURL:outputUrl error:&error];
            if (error) {
                fail(@"视频移动失败");
            }else {
                success(outputUrl);
            }
        }
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSURL *url in urls) {
        NSString *path = url.path;
        if ([fileManager fileExistsAtPath:path]) {
            NSLog(@"文件存在");
        }else {
            NSLog(@"文件不存在");
        }
        NSLog(@"path: %@",path);
    }
    
    NSLog(@"输出路径: %@",outputUrl);
    if ([fileManager fileExistsAtPath:outputUrl.path]) {
        NSLog(@"输出路径已存在");
    }
    
    
    //剪辑操作类
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    //视音频轨道的插入、删除和拓展接口,如果不需要插入视频或音频，不要创建对象，因为addMutableTrackWithMediaType之后不使用会导致合成失败
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    /*
     开始插入视音频
     fromTime:从视音频哪里开始，一般为kCMTimeZero，除非需要截取
     toTime:到视音频哪里结束，一般为asset.duration，说明播放到结束
     ofTrack:插入的媒体类型
     atTime:从哪里开始插入
     */
    CMTime indexTime = kCMTimeZero;
    
    for (NSURL *url in urls) {
        AVAsset *asset = [AVAsset assetWithURL:url];    //获取资源
        
        NSError *error = nil;
        //插入视频
        [videoTrack insertTimeRange:CMTimeRangeFromTimeToTime(kCMTimeZero, asset.duration) ofTrack:[asset tracksWithMediaType:AVMediaTypeVideo].firstObject atTime:indexTime error:&error];
        if (error) {
            NSLog(@"插入视频失败: %@",error);
            error = nil;
        }
        
        //插入音频
        [audioTrack insertTimeRange:CMTimeRangeFromTimeToTime(kCMTimeZero, asset.duration) ofTrack:[asset tracksWithMediaType:AVMediaTypeAudio].firstObject atTime:indexTime error:&error];
        if (error) {
            NSLog(@"插入音频失败: %@",error);
            error = nil;
        }
        
        indexTime = CMTimeAdd(indexTime, asset.duration);   //记录索引
    }
    
    //导出
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetMediumQuality];
    exporter.outputURL = outputUrl;
    exporter.outputFileType = AVFileTypeQuickTimeMovie; //AVFileTypeMPEG4 AVFileTypeQuickTimeMovie
    //    exporter.audioMix = videoAudioMixTools;
    exporter.shouldOptimizeForNetworkUse = YES;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"导出完成");
            
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:outputUrl.path]) {
                NSLog(@"文件存在");
                CGFloat fileSize = [[NSData dataWithContentsOfURL:outputUrl] length]/1024.00 /1024.00;
                NSLog(@"压缩完毕,压缩后大小 %f MB",fileSize);
                
                if (success) {
                    success(outputUrl);
                }
            }else {
                NSLog(@"文件不存在");
                if (fail) {
                    fail(@"文件不存在");
                }
            }
            
            switch ([exporter status]) {
                case AVAssetExportSessionStatusFailed: {
                    NSLog(@"合成失败：%@",[[exporter error] description]);
                }
                    break;
                    
                case AVAssetExportSessionStatusCancelled: {
                }
                    break;
                    
                case AVAssetExportSessionStatusCompleted: {
                }
                    break;
                    
                default: {
                }
                    break;
            }
        });
    }];
    
}

//获取指定的视频帧
+ (void)getVideoFrameWith:(NSURL *)fileUrl
                        atTime:(CGFloat)atTime
                         block:(void(^)(UIImage *image))block
                     fail:(void(^)(NSString *error))fail {
    
    if (!fileUrl) return;
    
    AVAsset *asset = [AVAsset assetWithURL:fileUrl];
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    
    CGFloat totalTime = asset.duration.value / asset.duration.timescale;
    if (totalTime < 0) {
        fail(@"视频总时长小于0");
        return;
    }
    
    //如果不设置这两个属性为kCMTimeZero，则实际生成的图片和需要生成的图片会有时间差
    imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    
    imageGenerator.appliesPreferredTrackTransform = YES;    //截图的时候调整到正确的方向
    
    CGFloat value = totalTime * atTime;    //第几秒
    CGFloat timeScale = asset.duration.timescale; //帧率
    
    value = MAX(value, 0);
    value = MIN(value, asset.duration.value);
    
    CMTime requestTime = CMTimeMakeWithSeconds(value, timeScale);   //时间
    
    NSError *error = nil;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:requestTime actualTime:NULL error:&error];
    if (error) {
        fail(error.debugDescription);
    }else {
        UIImage *img = [UIImage imageWithCGImage:imageRef];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block(img);
            }
        });
    }
    
}

//给视频配音,startTime 0-1
+ (void)dubForVideoWith:(NSURL *)fileUrl
               audioUrl:(NSURL *)audioUrl
              startTime:(CGFloat)startTime
                success:(void(^)(NSURL *url))success
                   fail:(void(^)(NSString *error))fail {
    //先检测文件是否存在
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:fileUrl.path] || ![fileManager fileExistsAtPath:audioUrl.path]) {
        if (fail) {
            fail(@"不存在该资源，无法合成");
        }
        return;
    }
    
    //开始合成
    
    //获取资源
    AVAsset *videoAsset = [AVAsset assetWithURL:fileUrl];
    AVAsset *audioAsset = [AVAsset assetWithURL:audioUrl];
    
    //剪辑操作类
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    //视音频轨道的插入、删除和拓展接口
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    //插入视频，此时视频是没有声音的，只有画面
    [videoTrack insertTimeRange:CMTimeRangeFromTimeToTime(kCMTimeZero, videoAsset.duration) ofTrack:[videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject atTime:kCMTimeZero error:nil];
        
    //有声音
    if ([[videoAsset tracksWithMediaType:AVMediaTypeAudio] count] > 0){
        //声音采集
        AVURLAsset * originAudioAsset = [[AVURLAsset alloc] initWithURL:fileUrl options:nil];
        //音频采集通道
        AVAssetTrack * audioAssetTrack = [[originAudioAsset tracksWithMediaType:AVMediaTypeAudio] lastObject];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, originAudioAsset.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    }
    
    //插入音频,当音频时长小于视频时长时候会导致视频后半段没有声音
    CGFloat totalTime = audioAsset.duration.value / audioAsset.duration.timescale;  //音频总时长
    CGFloat startValue = totalTime * startTime;    //第几秒开始
    CGFloat timeScale = audioAsset.duration.timescale;  //帧率
    
    //保护
    startValue = MAX(startValue, 0);
    startValue = MIN(startValue, audioAsset.duration.value);
    
    //计算出插入时间
    CMTime atTime = CMTimeMakeWithSeconds(startValue, timeScale);
    
    //在计算出的插入时间开始插入音频
    [audioTrack insertTimeRange:CMTimeRangeFromTimeToTime(kCMTimeZero, audioAsset.duration) ofTrack:[audioAsset tracksWithMediaType:AVMediaTypeAudio].firstObject atTime:atTime error:nil];
    
    //输出路径
    NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
    NSString *outputPath = [NSString stringWithFormat:@"%@/tmp/%ld.mp4",NSHomeDirectory(),(NSInteger)current];  //临时文件路径
    unlink([outputPath UTF8String]);
    NSURL *outputUrl = [NSURL fileURLWithPath:outputPath];

    //导出
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=outputUrl;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"导出操作完成");
            
            if ([fileManager fileExistsAtPath:outputPath]) {
                NSLog(@"合成成功");
                if (success) {
                    success(outputUrl);
                }
            }else {
                if (fail) {
                    fail(@"文件不存在，合成失败,请在合成代码中寻找原因");
                }
            }
            
        });
    }];
}

//给视频添加水印
- (void)watermarkForVideoWith:(NSURL *)fileUrl
                    videoRect:(CGRect)videoRect
                watermarkView:(UIView *)watermarkView
         frameProcessingBlock:(void(^)(GPUImageOutput *output, CMTime time))frameProcessingBlock
                      success:(void(^)(NSURL *url))success
                         fail:(void(^)(NSString *error))fail {
    //滤镜混合模块
    _filter = [[GPUImageNormalBlendFilter alloc] init];

    AVAsset *asset = [AVAsset assetWithURL:fileUrl];
    _movieFile = [[GPUImageMovie alloc] initWithAsset:asset];
    /**
     *  控制GPUImageView预览视频时的速度是否要保持真实的速度。
     *  如果设为NO，则会将视频的所有帧无间隔渲染，导致速度非常快。
     *  设为YES，则会根据视频本身时长计算出每帧的时间间隔，然后每渲染一帧，就sleep一个时间间隔，从而达到正常的播放速度。
     */
    _movieFile.playAtActualSpeed = NO;

    CGSize videoSize = CGSizeZero;
    for (AVAssetTrack *track in asset.tracks) {

        if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
            videoSize = track.naturalSize;
            NSLog(@"视频尺寸为: %@",[NSValue valueWithCGSize:videoSize]);
            break;
        }
    }

    if (CGSizeEqualToSize(videoSize, CGSizeZero)) {
        if (fail) {
            fail(@"添加水印失败，无法解析出视频尺寸");
        }
        return;
    }

    //输出路径
    NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
    NSString *outputPath = [NSString stringWithFormat:@"%@/tmp/%ld.mp4",NSHomeDirectory(),(NSInteger)current];  //临时文件路径
    unlink([outputPath UTF8String]);
    NSURL *outputUrl = [NSURL fileURLWithPath:outputPath];

    //视频写入模块
    _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:outputUrl size:videoSize];

    //承载View，不能修改
    UIView *containerView = [[UIView alloc] init];
    containerView.backgroundColor = [UIColor clearColor];
    containerView.frame = videoRect;

    if (watermarkView) {
        [containerView addSubview:watermarkView];
    }

    //水印展示模块
    GPUImageUIElement *uielement = [[GPUImageUIElement alloc] initWithView:containerView];

    //绘制模块
    GPUImageFilter *progressFilter = [[GPUImageFilter alloc] init];

    [progressFilter addTarget:_filter];
    [_movieFile addTarget:progressFilter];
    [uielement addTarget:_filter];
    _movieWriter.shouldPassthroughAudio = YES;   //是否使用原声

    [progressFilter useNextFrameForImageCapture];

    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] > 0) {
        _movieFile.audioEncodingTarget = _movieWriter;
    }else {
        _movieFile.audioEncodingTarget = nil;
    }

    [_movieFile enableSynchronizedEncodingUsingMovieWriter:_movieWriter];

    //显示到界面
    [_filter addTarget:_movieWriter];

    [_movieWriter startRecording];
    [_movieFile startProcessing];

    //水印绘制过程回调，可以在这里进行水印的定制变化
    [progressFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (frameProcessingBlock) {
                frameProcessingBlock(output,time);
            }
        });
        [uielement update];
    }];

    //完成
    [_movieWriter setCompletionBlock:^{
        if (success) {
            success(outputUrl);
        }
    }];
}

+ (void)filterForVideoWith:(NSURL *)fileUrl
                   success:(void(^)(NSURL *url))success
                      fail:(void(^)(NSString *error))fail{
    
    //获取视频资源
    AVURLAsset* asset = [AVURLAsset assetWithURL:fileUrl];
    
    AVAssetTrack *assetTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    
    //输出路径
    NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
    NSString *outputPath = [NSString stringWithFormat:@"%@/tmp/%ld.m4v",NSHomeDirectory(),(NSInteger)current];  //临时文件路径
    unlink([outputPath UTF8String]);
    NSURL *outputUrl = [NSURL fileURLWithPath:outputPath];
    
    //传入视频文件
    GPUImageMovie *movieFile = [[GPUImageMovie alloc] initWithURL:fileUrl];
    
    movieFile.runBenchmark = NO;
    movieFile.playAtActualSpeed = NO;
    
    //添加滤镜
    struct GPUVector3  color;
    color.one = 38/255;
    color.two = 38/255;
    color.three = 38/255;
    
    GPUImageFilter *imageFilter = [[GPUImageFilter alloc]init];
    GPUImageMissEtikateFilter *filt = [[GPUImageMissEtikateFilter alloc]init];
    GPUImageVignetteFilter *filt1 = [[GPUImageVignetteFilter alloc]init];
    filt1.vignetteColor = color;
    filt1.vignetteStart = 0.45;
    filt1.vignetteEnd = 0.85;
    [movieFile addTarget:filt];
    [filt addTarget:filt1];
    [filt1 addTarget:imageFilter];

    GPUImageOutput<GPUImageInput> *filter = filt1;
    
    //视频尺寸
    CGSize videoSize = assetTrack.naturalSize;
    
    GPUImageMovieWriter *movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:outputUrl size:videoSize];
    if ((NSNull*)filter != [NSNull null] && filter != nil) {
        [filter addTarget:movieWriter];
    } else {
        [movieFile addTarget:movieWriter];
    }
    
    movieWriter.shouldPassthroughAudio = YES;
    movieFile.audioEncodingTarget = movieWriter;
    [movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
    
    //开始渲染
    [movieWriter startRecording];
    [movieFile startProcessing];
    
    __weak typeof(movieWriter) weakMovieWriter = movieWriter;
    //导出
    [movieWriter setCompletionBlock:^{
        if ((NSNull*)filter != [NSNull null] && filter != nil) {
            [filter removeTarget:weakMovieWriter];
        }else {
            [movieFile removeTarget:weakMovieWriter];
        }
        
        [weakMovieWriter finishRecordingWithCompletionHandler:^{
            // 完成后处理进度计时器 关闭、清空
            NSLog(@"完成");
            if (success) {
                success(outputUrl);
            }
        }];
        
    }];
}


# pragma mark - Lazy load
//- (dispatch_queue_t)toolQueue {
//    if (!_toolQueue) {
//        _toolQueue = dispatch_queue_create("ToolQueue", DISPATCH_QUEUE_SERIAL);
//    }
//    return _toolQueue;
//}


@end
