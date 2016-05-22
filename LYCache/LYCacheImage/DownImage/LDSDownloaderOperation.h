//
//  LYDownloaderOperation.h
//  LYCache
//
//  Created by LastDays on 16/4/15.
//  Copyright © 2016年 LastDays. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LDSImageDownloader.h"

@interface LYDownloaderOperation : NSOperation

/**
 *  回调信息
 */
@property (copy, nonatomic) DownloaderProgressBlock progressBlock;
@property (copy, nonatomic) DownloaderCompletedBlock completedBlock;
@property (copy, nonatomic) DownloaderCreateBlock cancelBlock;

/**
 *  未接收大小
 */
@property(assign,nonatomic) NSInteger expectedContentLength;

/**
 *  下载操作
 */
@property(assign,nonatomic) DownloaderOptions options;

@property(strong,nonatomic) NSMutableURLRequest *request;


- (instancetype)initWithRequest:(NSMutableURLRequest *)request
              DownloaderOptions:(DownloaderOptions)options
       DownloaderProgressBlock :(DownloaderProgressBlock)ProgressBlock
       DownloaderCompletedBlock:(DownloaderCompletedBlock)completedBlock
                      cancelled:(DownloaderCreateBlock)cancelledBlock;

@end
