//
//  DownlodImage.m
//  LYCache
//
//  Created by LastDays on 16/4/14.
//  Copyright © 2016年 LastDays. All rights reserved.
//

#import "LDSImageDownloader.h"
#import "LDSDownloaderOperation.h"


@interface LYImageDownloader ()

/**
 *  下载队列
 */
@property(strong,nonatomic) NSOperationQueue *downloadQueue;

/**
 *  将所有的下载回调信息存储在这里，Key是URL，Value是多组回调信息
 */
@property(strong,nonatomic) NSMutableDictionary *downloaderCallBack;

@property(strong,nonatomic) dispatch_queue_t concurrentQueue;


@end

@implementation LYImageDownloader

- (instancetype)init
{
    self = [super init];
    if (self) {
        _downloadQueue = [[NSOperationQueue alloc] init];
        _downloadQueue.maxConcurrentOperationCount = 4;
        _concurrentQueue = dispatch_queue_create("com.lastdays.LYCache.ForBarrier", DISPATCH_QUEUE_CONCURRENT);
        _downloaderCallBack = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+(instancetype)shareDownloader{
    
    static LYImageDownloader *lyImageDownloader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lyImageDownloader = [[LYImageDownloader alloc] init];
    });
    return lyImageDownloader;
}




/**
 *  下载管理器对于下载请求的管理
 *
 *  @param progressBlock  DownloaderProgressBlock
 *  @param completedBlock DownloaderCompletedBlock
 *  @param url            url
 */
-(void)downloaderImageWithDownloaderWithURL:(NSURL *)url DownloaderProgressBlock:(DownloaderProgressBlock)progressBlock DownloaderCompletedBlock:(DownloaderCompletedBlock)completedBlock{
    
    __weak __typeof(self)myself = self;
    __block LYDownloaderOperation *operation;
    
    
    [self addWithDownloaderProgressBlock:progressBlock DownloaderCompletedBlock:completedBlock URL:url DownloaderCreateBlock:^{
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy: NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
        
        operation = [[LYDownloaderOperation alloc] initWithRequest:request
                                                 DownloaderOptions:1
                                           DownloaderProgressBlock:^(NSInteger alreadyReceiveSize,NSInteger expectedContentLength){
    
                                               __block NSArray *urlCallBacks;
                                               
                                               dispatch_sync(self.concurrentQueue, ^{
                                                   urlCallBacks = [myself.downloaderCallBack[url] copy];
                                               });
                                               for (NSDictionary *callbacks in urlCallBacks) {
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                       DownloaderProgressBlock progress = callbacks[@"progress"];
                                                       if (progress) {
                                                           progress(alreadyReceiveSize,expectedContentLength);
                                                       }
                                                   });
                                               }
                                           }
                                          DownloaderCompletedBlock:^(NSData *data,UIImage *image,NSError *error,BOOL finished){
                                              __block NSArray *urlCallBacks;
                                              dispatch_barrier_sync(myself.concurrentQueue, ^{
                                                  urlCallBacks = [myself.downloaderCallBack[url] copy];
                                                  if (finished) {
                                                      [myself.downloaderCallBack removeObjectForKey:url];
                                                  }
                                              });
                                              
                                              for (NSDictionary *callBack in urlCallBacks) {
                                                  dispatch_sync(self.concurrentQueue,^{
                                                      DownloaderCompletedBlock completed = callBack[@"completed"];
                                                      if (completed) {
                                                          completed(data,image,error,finished);
                                                      }
                                                  });
                                                  
                                              }
                                          }
                                                         cancelled:^{
                                                             dispatch_barrier_sync(myself.concurrentQueue, ^{
                                                                 NSLog(@"取消操作");
                                                                 [myself.downloaderCallBack removeObjectForKey:url];
                                                             });
                                                             
                                                         }];
        [myself.downloadQueue addOperation:operation];
        
    }];
}


/**
 *  添加回调信息
 *
 *  @param progressBlock         DownloaderProgressBlock
 *  @param completedBlock        DownloaderCompletedBlock
 *  @param url                   url
 *  @param DownloaderCreateBlock DownloaderCreateBlock
 */
-(void)addWithDownloaderProgressBlock:(DownloaderProgressBlock)progressBlock DownloaderCompletedBlock:(DownloaderCompletedBlock)completedBlock URL:(NSURL *)url DownloaderCreateBlock:(DownloaderCreateBlock)downloaderCreateBlock{
    
    /**
     *  判断url是否为空
     */
    if ([url isEqual:nil]) {
        completedBlock(nil,nil,nil,NO);
    }
    
    /**
     *  设置屏障，保证在同一时间，只有一个线程可以操作downloaderCallBack属性,保证在并行多个处理的时候，对downloaderCallBack属性的读写操作保持一致
     */
    dispatch_barrier_sync(self.concurrentQueue, ^{
        
        BOOL firstDownload = NO;
        /**
         *  添加回调信息，处理同同一个url信息。
         */
        if(!self.downloaderCallBack[url]){
            self.downloaderCallBack[url] = [NSMutableArray new];
            firstDownload = YES;
        }
        
        NSMutableArray *callBacksArray = self.downloaderCallBack[url];
        NSMutableDictionary *callBacks = [[NSMutableDictionary alloc] init];
        if (progressBlock) {
            callBacks[@"progress"] = [progressBlock copy];
        }
        if (completedBlock) {
            callBacks[@"completed"] = [completedBlock copy];
        }
        [callBacksArray addObject:callBacks];
        self.downloaderCallBack[url] = callBacksArray;
                
        if (firstDownload) {
            downloaderCreateBlock();
        }
    });
}

@end
