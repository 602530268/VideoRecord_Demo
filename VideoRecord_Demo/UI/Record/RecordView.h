//
//  RecordView.h
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/9.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ControlsCallback)(id obj);

@interface RecordView : UIView

# pragma mark - UI
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UILabel *timeLbl;

@property (weak, nonatomic) IBOutlet UIButton *closeBtn;
@property (weak, nonatomic) IBOutlet UIButton *flashBtn;
@property (weak, nonatomic) IBOutlet UIButton *delayBtn;
@property (weak, nonatomic) IBOutlet UIButton *cameraBtn;

@property (weak, nonatomic) IBOutlet UIButton *photoLibraryBtn;
@property (weak, nonatomic) IBOutlet UIButton *seconds15Btn;
@property (weak, nonatomic) IBOutlet UIButton *seconds60Btn;

@property (weak, nonatomic) IBOutlet UIButton *specialEffectsBtn;
@property (weak, nonatomic) IBOutlet UIButton *filterBtn;

@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UIButton *finishBtn;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;

# pragma mark - Callback
@property(nonatomic,copy) ControlsCallback closeBlock;
@property(nonatomic,copy) ControlsCallback flashBlock;
@property(nonatomic,copy) ControlsCallback delayBlock;
@property(nonatomic,copy) ControlsCallback cameraBlock;

@property(nonatomic,copy) ControlsCallback photoLibraryBlock;
@property(nonatomic,copy) ControlsCallback seconds15Block;
@property(nonatomic,copy) ControlsCallback seconds60Block;


@property(nonatomic,copy) ControlsCallback specialEffectsBlock;
@property(nonatomic,copy) ControlsCallback filterBlock;

@property(nonatomic,copy) ControlsCallback recordBlock;
@property(nonatomic,copy) ControlsCallback finishBlock;
@property(nonatomic,copy) ControlsCallback cancelBlock;

# pragma mark - Data
@property(nonatomic,assign) CGFloat maxRecordTime;  //最大录制时长

- (void)startProgressView;
- (void)pauseProgressView;
- (void)cancelProgressView;

@end
