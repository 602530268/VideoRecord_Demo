//
//  CCRecordAssetWriter.h
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/3.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import "CCRecord.h"

typedef void(^VideoImageCallback)(UIImage *img);
typedef void(^VideoDataCallback)(NSData *data);
typedef void(^SampleBufferRefCallback)(CMSampleBufferRef sampleBuffer);

@interface CCRecordAssetWriter : CCRecord

@property(nonatomic,copy) VideoImageCallback videoImageBlock;
@property(nonatomic,copy) VideoDataCallback videoDataBlock;
@property(nonatomic,copy) SampleBufferRefCallback sampleBufferBlock;

@end
