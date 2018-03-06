//
//  CCGPUImageRecord.h
//  Doupai_Demo
//
//  Created by chencheng on 2018/2/10.
//  Copyright © 2018年 double chen. All rights reserved.
//

#import "CCRecord.h"

@interface CCGPUImageRecord : CCRecord

//更新滤镜
- (void)updateGPUImageFilters:(NSArray <GPUImageOutput<GPUImageInput> *>*)filters;


@end
