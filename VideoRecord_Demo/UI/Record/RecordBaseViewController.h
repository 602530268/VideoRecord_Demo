//
//  RecordBaseViewController.h
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/9.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVPlayerVC.h"

#import "RecordView.h"
#import "FiltersView.h"

#import "CCRecordHeader.h"

@interface RecordBaseViewController : UIViewController

@property(nonatomic,strong) NSArray *hideControls;  //录制时隐藏的控件

@property(nonatomic,strong) RecordView *recordView;
@property(nonatomic,strong) FiltersView *filtersView;

- (void)hideForStartRecord:(RecordStatus)status;

@end
