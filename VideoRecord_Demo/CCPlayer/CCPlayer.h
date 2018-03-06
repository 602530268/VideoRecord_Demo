//
//  CCPlayer.h
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/5.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger,CCPlayerStatus) {
    CCPlayerStatusDisNotPlay,    //未播放
    CCPlayerStatusPlaying,   //正在播放
    CCPlayerStatusPause, //暂停
    CCPlayerStatusFinish,    //播放完成
};

typedef void(^PlayCallback)(void); //播放回调
typedef void(^PauseCallback)(void);    //暂停回调
typedef void(^FinishCallback)(void);   //播放完成回调
typedef void(^ProgressCallback)(CGFloat progress,CGFloat currentTime,CGFloat totalTime);   //播放进度回调
typedef void(^BufferCallback)(CGFloat progress);   //缓冲进度回调,在新建对象后就已经开始缓存了

@interface CCPlayer : NSObject

- (instancetype)initWithPath:(NSString *)path;
- (instancetype)initWithURLString:(NSString *)urlString;
- (instancetype)initWithURL:(NSURL *)url;

@property(nonatomic,assign) CCPlayerStatus status;
@property(nonatomic,strong) NSURL *fileUrl;
@property(nonatomic,strong) UIView *containerView;  //视频承载View
@property(nonatomic,assign) AVLayerVideoGravity videoGravity;

# pragma mark - callback
@property(nonatomic,copy) PlayCallback playBlock;
@property(nonatomic,copy) PauseCallback pauseBlock;
@property(nonatomic,copy) FinishCallback finishBlock;
@property(nonatomic,copy) ProgressCallback progressBlock;   //播放进度
@property(nonatomic,copy) BufferCallback bufferBlock;   //缓存进度

//播放
- (void)play;

//暂停
- (void)pause;

//缓存
- (void)buffer;

//跳转进度
- (void)jumpProgressWith:(CGFloat)value;
- (void)jumpProgressWithTime:(CMTime)time;

//更新playerLayer的frame，当containerView的约束发生变化时，调用该函数
- (void)updatePlayerLayerFrame;



@end
