//
//  UIImage+Cache.m
//  LYCache
//
//  Created by LastDays on 16/5/22.
//  Copyright © 2016年 LastDays. All rights reserved.
//

#import "UIImageView+Cache.h"

@implementation UIImageView(WebImage)

- (void)lds_setImageWithURL:(NSString *)url progressBlock:(DownloaderProgressBlock)progressBlock completed:(DownloaderCompletedBlock)completedBlock{
    __weak __typeof(self)wself = self;
    [[LDSCacheManage shareLDCacheManage] downImageWithURL:url
                                 DownloaderProgressBlock:^(NSInteger aleradyReceiveSize,NSInteger expectedContentLength){
                                     if (progressBlock) {
                                         progressBlock(aleradyReceiveSize,expectedContentLength);
                                     }
                                     
                                 }DownloaderCompletedBlock:^(NSData *data,UIImage *image,NSError *error,BOOL finished){
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         wself.image = image;
                                         
                                         NSLog(@"%@",wself.image);
                                         
                                         [wself setNeedsLayout];
                                         if (completedBlock) {
                                             completedBlock(data, image, error, YES);
                                         }
                                     });
                                     
                                 }];
}

@end
