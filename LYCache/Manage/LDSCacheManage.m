//
//  LDCacheManage.m
//  LYCache
//
//  Created by LastDays on 16/5/21.
//  Copyright © 2016年 LastDays. All rights reserved.
//

#import "LDSCacheManage.h"

@implementation LDSCacheManage

+(LDSCacheManage *)shareLDCacheManage{
    static LDSCacheManage *lDSCacheManage;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        lDSCacheManage = [[LDSCacheManage alloc] init];
    });
    return lDSCacheManage;
}


-(void)downImageWithURL:(NSString *)urlString DownloaderProgressBlock:(DownloaderProgressBlock)progressBlock DownloaderCompletedBlock:(DownloaderCompletedBlock)completedBlock{
    NSURL *url = [NSURL URLWithString:urlString];
    if ([urlString isKindOfClass:NSString.class]) {
        url = [NSURL URLWithString:urlString];
    }
    if (![url isKindOfClass:NSURL.class]) {
        url = nil;
    }
    [[LDSImageCache shareLDImageCache] selectImageWithKey:urlString completedBlock:^(UIImage *image,NSError *error,ImageCacheType type){
        
        if (image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSData *data = UIImagePNGRepresentation(image);
                completedBlock(data,image,error,YES);
                NSLog(@"读取缓存");
                
            });
        }else{
            NSLog(@"进入下载");
            [[LYImageDownloader shareDownloader] downloaderImageWithDownloaderWithURL:url
                                                              DownloaderProgressBlock:^(NSInteger alreadyReceiveSize,NSInteger expectedContentLength){
                                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                                      progressBlock(alreadyReceiveSize,expectedContentLength);
                                                                  });
                                                              }
                                                             DownloaderCompletedBlock:^(NSData *data,UIImage *image,NSError *error,BOOL finished){
                                                                 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                                                     [[LDSImageCache shareLDImageCache] saveImageWithMemoryCache:nil image:image imageData:data urlKey:urlString isSaveToDisk:YES];
                                                                 });
                                                                 
                                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                                     completedBlock(data,image,error,YES);

                                                                 });
                                                             }];
        }
    }];
    

    
}

@end
