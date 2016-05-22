//
//  UIImage+Cache.h
//  LYCache
//
//  Created by LastDays on 16/5/22.
//  Copyright © 2016年 LastDays. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LDSCacheManage.h"

@interface UIImageView (WebImage)

- (void)lds_setImageWithURL:(NSString *)url progressBlock:(DownloaderProgressBlock)progressBlock completed:(DownloaderCompletedBlock)completedBlock;

@end
