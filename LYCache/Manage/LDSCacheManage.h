//
//  LDCacheManage.h
//  LYCache
//
//  Created by LastDays on 16/5/21.
//  Copyright © 2016年 LastDays. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LDSImageDownloader.h"
#import "LDSImageCache.h"

@interface LDSCacheManage : NSObject

/**
 *  LDCacheManage的单例
 *
 *  @return LDCacheManage
 */
+(LDSCacheManage *)shareLDCacheManage;

/**
 *  根据URL下载图片
 *
 *  @param url            url地址
 *  @param progressBlock  下载进度回调
 *  @param completedBlock 下载完成回调
 */
-(void)downImageWithURL:(NSString *)url DownloaderProgressBlock:(DownloaderProgressBlock)progressBlock DownloaderCompletedBlock:(DownloaderCompletedBlock)completedBlock;

@end
