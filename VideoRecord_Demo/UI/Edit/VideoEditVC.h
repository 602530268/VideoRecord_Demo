//
//  VideoEditVC.h
//  VideoRecord_Demo
//
//  Created by chencheng on 2018/3/1.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoEditVC : UIViewController

# pragma mark - UI
@property(nonatomic,strong) UIView *containerView;
@property(nonatomic,strong) UIButton *playBtn;
@property(nonatomic,strong) UIScrollView *scrollView;
@property(nonatomic,strong) UISegmentedControl *segmentedControl;

# pragma mark - Data
@property(nonatomic,strong) NSURL *fileUrl;

@property(nonatomic,copy) void(^playEventBlock)(UIButton *btn); //播放
@property(nonatomic,copy) void(^nextEventBlock)(void);  //下一步
@property(nonatomic,copy) void(^scrollViewDragBlock)(UIScrollView *scrollView,CGFloat currentProgress); //滑动
@property(nonatomic,copy) void(^dubEventBlock)(void);   //配音
@property(nonatomic,copy) void(^watermarkEventBlock)(void); //水印
@property(nonatomic,copy) void(^filterEventBlock)(void);    //滤镜

- (void)updateScrollView;
- (void)updateScrollViewContentOffsetWith:(CGFloat)progress;

@end
