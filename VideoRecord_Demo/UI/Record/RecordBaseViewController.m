//
//  RecordBaseViewController.m
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/9.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import "RecordBaseViewController.h"

@interface RecordBaseViewController ()

@end

@implementation RecordBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self createRecordView];
    [self createFiltersView];
    
    self.hideControls = @[self.recordView.closeBtn,
                          self.recordView.flashBtn,
                          self.recordView.delayBtn,
                          self.recordView.cameraBtn,
                          self.recordView.photoLibraryBtn,
                          self.recordView.seconds15Btn,
                          self.recordView.seconds60Btn,
                          self.recordView.specialEffectsBtn,
                          self.recordView.filterBtn,];
}

- (void)createRecordView {
    _recordView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([RecordView class]) owner:self options:nil] objectAtIndex:0];
    [self.view addSubview:_recordView];
    [_recordView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.size.equalTo(self.view);
    }];
}

- (void)createFiltersView {
    _filtersView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([FiltersView class]) owner:self options:nil] objectAtIndex:0];
    [self.view addSubview:_filtersView];
    CGFloat height = 150.0f;
    
    [_filtersView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.height.equalTo(@(height));
        make.bottom.equalTo(self.view).offset(height); //height
    }];
}

- (void)hideForStartRecord:(RecordStatus)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL hide = NO;
        if (status == RecordStatusRecording) {
            hide = YES;
        }
        for (UIView *control in self.hideControls) {
            control.hidden = hide;
        }
        self.recordView.timeLbl.hidden = !hide;
    });
}

//隐藏状态栏
- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
