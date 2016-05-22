//
//  DownlodImage.h
//  LYCache
//
//  Created by LastDays on 16/4/14.
//  Copyright © 2016年 LastDays. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSInteger,DownloaderOptions) {
    
    //默认下载操作
    DownloaderDefault = 1,
    
    //允许后台操作
    DownloaderContinueInBackground = 2
};

typedef NS_ENUM(NSInteger,DownloaderOrder){
    
    //默认下载顺序，先进先出
    DownloaderFIFO,
    
    //先进后出
    DownloaderLIFO
};

/**
 *  无参数block
 */
typedef void(^DownloaderCreateBlock)();

/**
 *  下载回调信息，下载进度Block
 *
 *  @param AlreadyReceiveSize 已经接收大小
 *  @param NotReceiveSize     未接收大小
 */
typedef void(^DownloaderProgressBlock)(NSInteger alreadyReceiveSize,NSInteger expectedContentLength);

/**
 *  下载回调信息，完成下载Block
 *
 *  @param data     data
 *  @param image    图片
 *  @param error    错误信息
 *  @param finished 是否完成
 */
typedef void(^DownloaderCompletedBlock)(NSData *data,UIImage *image,NSError *error,BOOL finished);

@interface LYImageDownloader : NSObject


/**
 *  单例方法
 *
 *  @return 返回一个全局的LYDownlodImage
 */
+(instancetype)shareDownloader;



-(void)downloaderImageWithDownloaderWithURL:(NSURL *)url DownloaderProgressBlock:(DownloaderProgressBlock)progressBlock DownloaderCompletedBlock:(DownloaderCompletedBlock)completedBlock;



@end
