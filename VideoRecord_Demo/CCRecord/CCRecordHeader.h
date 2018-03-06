
//
//  CCRecordHeader.h
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/10.
//  Copyright © 2018年 double chen. All rights reserved.
//

#ifndef CCRecordHeader_h
#define CCRecordHeader_h

/*
 测试发现，默认是不支持暂停录制的，所谓的pause函数也只是导致暂停时段卡帧，并不是真正意义上的暂停，所以暂停功能可以通过视频拼接来实现
 */
typedef void(^StartRecordCallback)(NSURL *fileURL);
typedef void(^StopRecordCallback)(NSURL *fileURL);
typedef void(^PauseRecordCallback)(NSURL *fileURL);

#define CCWeakSelf(weakSelf) __weak typeof(self) weakSelf = self;   //弱引用self

typedef NS_ENUM(NSInteger,CameraInput) {
    CameraInputBack,    //default
    CameraInputFront,
};

typedef NS_ENUM(NSInteger,RecordStatus) {
    RecordStatusNone,
    RecordStatusRecording,
    RecordStatusRecordPause,
    RecordStatusRecordFinish,  
};

#endif /* CCRecordHeader_h */
