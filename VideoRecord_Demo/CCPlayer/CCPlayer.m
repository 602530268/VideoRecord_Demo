//
//  CCPlayer.m
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/5.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import "CCPlayer.h"

static CGFloat playerProgressTime = 1.0f;   //隔多久监听播放进度

@interface CCPlayer ()

@property(nonatomic,strong) AVPlayer *player;   //播放器
@property(nonatomic,strong) AVPlayerLayer *playerLayer; //player需要在playerLayer上才能展示

@end

@implementation CCPlayer

- (instancetype)initWithPath:(NSString *)path {
    NSURL *url = [NSURL fileURLWithPath:path];
    return [self initWithURL:url];
}

- (instancetype)initWithURLString:(NSString *)urlString {
    urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *url = [NSURL URLWithString:urlString];
    return [self initWithURL:url];
}

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        self.fileUrl = url;
        _videoGravity = AVLayerVideoGravityResizeAspect;
    }
    return self;
}

//播放
- (void)play {
    [self buffer];
    if (_player && _player.rate == 0) {
        [_player play];
        [self callbackWith:CCPlayerStatusPlaying];
    }
}

//暂停
- (void)pause {
    if (_player && _player.rate != 0) {
        [_player pause];
        [self callbackWith:CCPlayerStatusPause];
    }
}

//缓存
- (void)buffer {
    if (_playerLayer == nil && self.fileUrl) {
        [self initializedPlayerWith:self.fileUrl];
    }
}

//跳转进度
- (void)jumpProgressWith:(CGFloat)value {
    if (_playerLayer == nil) return;
    CMTime time = CMTimeMakeWithSeconds(value * CMTimeGetSeconds(_player.currentItem.duration), _player.currentItem.currentTime.timescale);
    [self jumpProgressWithTime:time];
}

- (void)jumpProgressWithTime:(CMTime)time {
    if (_playerLayer == nil) return;
//    [_player seekToTime:time];    //该方法无法进行精确的跳转，只能跳转大于1秒后的进度
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];   //这样才可以进行1秒内的精确跳转
}

/*
 视频填充模式
 AVLayerVideoGravityResizeAspect    默认，按视频比例显示，直到宽或高占满，未达到的地方显示父视图
 AVLayerVideoGravityResizeAspectFill    按原比例显示视频，直到两边屏幕占满，但视频部分内容可能无法显示
 AVLayerVideoGravityResize  按父视图尺寸显示，可能与原视频比例不同
 */
- (void)setupVideoGravity:(AVLayerVideoGravity)videoGravity {
    if (_playerLayer == nil) return;
    _playerLayer.videoGravity = videoGravity;
}

//更新playerLayer的frame，当containerView的约束发生变化时，调用该函数
- (void)updatePlayerLayerFrame {
    if (_playerLayer == nil) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        _playerLayer.frame = _containerView.bounds;
    });
}

# pragma mark - Setter/Getter
/*
 视频填充模式
 AVLayerVideoGravityResizeAspect    默认，按视频比例显示，直到宽或高占满，未达到的地方显示父视图
 AVLayerVideoGravityResizeAspectFill    按原比例显示视频，直到两边屏幕占满，但视频部分内容可能无法显示
 AVLayerVideoGravityResize  按父视图尺寸显示，可能与原视频比例不同
 */
- (void)setVideoGravity:(AVLayerVideoGravity)videoGravity {
    _videoGravity = videoGravity;
}

- (void)setFileUrl:(NSURL *)fileUrl {
    _fileUrl = fileUrl;
    [self initializedPlayerWith:self.fileUrl];
}

# pragma mark - APIs (private)
- (void)initializedPlayerWith:(NSURL *)url {
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];    //资源管理器
    
    if (_player.currentItem != nil) {
        [self removeObserverFromPlayerItem:_player.currentItem];    //移除之前的监听
        [_player replaceCurrentItemWithPlayerItem:playerItem];  //切换资源
        [self pause];
    }else {
        _player = [AVPlayer playerWithPlayerItem:playerItem];
    }
    
    [_playerLayer removeFromSuperlayer];
    _playerLayer = nil;
    
    if (_containerView != nil) {
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        _playerLayer.videoGravity = _videoGravity;    //视频填充模式
        _playerLayer.frame = _containerView.bounds;
        [_containerView.layer addSublayer:_playerLayer];
    }
    
    //监听播放器
    [self addObserverFromPlayerItem:playerItem];
    [self addProgressNotification];
    [self addPlayerFinishNotification];
}

- (void)callbackWith:(CCPlayerStatus)status {
    _status = status;

    dispatch_async(dispatch_get_main_queue(), ^{
        switch (status) {
            case CCPlayerStatusDisNotPlay:
                break;
            case CCPlayerStatusPlaying:
                if (_playBlock) {
                    _playBlock();
                }
                break;
            case CCPlayerStatusPause:
                if (_pauseBlock) {
                    _pauseBlock();
                }
                break;
            case CCPlayerStatusFinish:
                if (_finishBlock) {
                    _finishBlock();
                }
                break;
            default:
                break;
        }
    });
}

# pragma mark - Observer
- (void)addObserverFromPlayerItem:(AVPlayerItem *)playerItem {
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];    //开始或暂停
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];  //缓存进度
}

- (void)removeObserverFromPlayerItem:(AVPlayerItem *)playerItem {
    [playerItem removeObserver:self forKeyPath:@"status"];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
}

//监听播放器信息
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change valueForKey:@"new"] integerValue];
        if (status ==AVPlayerStatusReadyToPlay) {
            CGFloat totalTime = CMTimeGetSeconds(playerItem.duration);
            NSLog(@"正在播放，视频总长度为 %.2f",totalTime);
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSArray *array = playerItem.loadedTimeRanges;
        //本次缓冲时间范围
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        CGFloat startSecond = CMTimeGetSeconds(timeRange.start);
        CGFloat durationSecond = CMTimeGetSeconds(timeRange.duration);
        CGFloat totalTime = CMTimeGetSeconds(playerItem.duration);
        //缓冲总长度
        NSTimeInterval totalBuffer = startSecond + durationSecond;
        CGFloat bufferProgress = totalBuffer / totalTime;
        if (_bufferBlock) {
            _bufferBlock(bufferProgress);
        }
    }
}

//监听播放进度
- (void)addProgressNotification {
    AVPlayerItem *playerItem = _player.currentItem;
    if (playerItem == nil) return;
    
    id playProgressObserver; //播放进度监听对象
    
    //先移除上一个视频的监听
    if (playProgressObserver) {
        [_player removeTimeObserver:playProgressObserver];
    }
    
    //每秒监听一次播放进度
    __weak typeof(self) weekSelf = self;
    /*
     CMTimeMake(value,timeScale):
     value表示第几帧，timeScale表示帧率，即每秒多少帧
     CMTimeMake(1,10):第一帧，帧率为每秒10帧，转换为时间公式:value/timeScale,即1/10=0.1,表示在视频的0.1秒时刻
     CMTimeMakeWithSeconds的第一个参数可以使float，其他都一样,不过因为这个比较好用，所以我一般用这个
     */
    playProgressObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(playerProgressTime, playerProgressTime) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        CGFloat currentTime = CMTimeGetSeconds(time);
        CGFloat totalTime = CMTimeGetSeconds(playerItem.duration);
        
        if (currentTime) {
            CGFloat playProgress = currentTime / totalTime;
            if (weekSelf.progressBlock) {
                weekSelf.progressBlock(playProgress,currentTime,totalTime);
            }
        }
    }];
}

//播放完成通知
- (void)addPlayerFinishNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFinishNotification) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
}

- (void)playFinishNotification {
    [self callbackWith:CCPlayerStatusFinish];
}

#pragma mark ----------Other----------
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserverFromPlayerItem:self.player.currentItem];
    
    NSLog(@"dealloc: %@",[self class]);
}

@end
