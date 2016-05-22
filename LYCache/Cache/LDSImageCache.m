//
//  LDImageCache.m
//  LYCache
//
//  Created by LastDays on 16/4/20.
//  Copyright © 2016年 LastDays. All rights reserved.
//

#import "LDSImageCache.h"
#import <CommonCrypto/CommonDigest.h>


@interface LDSImageCache ()

@property(strong,nonatomic) NSCache *memoryCache;
@property(strong,nonatomic) NSString *diskCachePath;
@property(strong,nonatomic) dispatch_queue_t ioSerialQueue;
@property(strong,nonatomic) NSFileManager *fileMange;


@end

@implementation LDSImageCache


+(LDSImageCache *)shareLDImageCache{
    static LDSImageCache *ldImageCache;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        ldImageCache = [[LDSImageCache alloc] init];
    });
    return ldImageCache;
}

- (id)init
{
    return [self initWithCacheSpace:@"default"];
}


- (instancetype)initWithCacheSpace:(NSString *)path
{
    self = [super init];
    if (self) {
        
        /**
         *  文件路径
         */
        NSString *fullPath = [@"com.LastDays.LYCache." stringByAppendingString:path];
        
        //创建IO串行队列
        _ioSerialQueue = dispatch_queue_create("com.LDImageCache.ioSerialQueue", DISPATCH_QUEUE_SERIAL);
        
        //初始化内存缓存
        _memoryCache = [[NSCache alloc] init];
        _memoryCache.name = fullPath;
        
        //获取Cache目录路径,初始化磁盘缓存路径
        NSArray *cacPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _diskCachePath = [[cacPath objectAtIndex:0] stringByAppendingPathComponent:fullPath];

        //初始化fileMange
        dispatch_sync(self.ioSerialQueue, ^{
            _fileMange = [NSFileManager defaultManager];
        });
    }
    return self;
}

/**
 *  进行缓存
 *
 *  @param memoryCache  内存
 *  @param image        图片
 *  @param imageData    图片data
 *  @param urlKey       key值就用来唯一标记数据
 *  @param isSaveTOdisk 是否进行沙箱缓存
 */
-(void)saveImageWithMemoryCache:(NSCache *)memoryCache image:(UIImage *)image imageData:(NSData *)imageData urlKey:(NSString *)urlKey isSaveToDisk:(BOOL)isSaveToDisk{

    //内存缓存
    if (memoryCache == nil) {
        
        [self.memoryCache setObject:image forKey:urlKey];
        
    }else{
        [memoryCache setObject:image forKey:urlKey];
    }
    
    //磁盘缓存
    if (isSaveToDisk) {
        dispatch_sync(self.ioSerialQueue, ^{
            if (![_fileMange fileExistsAtPath:_diskCachePath]) {
                [_fileMange createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            NSString *pathForKey = [self defaultCachePathForKey:urlKey];
            
            NSLog(@"%@",pathForKey);
            
            [_fileMange createFileAtPath:pathForKey contents:imageData attributes:nil];
        });
    }
}



//查询图片
-(void)selectImageWithKey:(NSString *)urlKey completedBlock:(CompletedBlock)completed{
    UIImage *image = [self.memoryCache objectForKey:urlKey];
    if (image != nil) {
        NSLog(@"ok");
        completed(image,nil,ImageCacheTypeMemory);
        
    }else{
        
        NSString *pathForKey = [self defaultCachePathForKey:urlKey];
        NSLog(@"%@",pathForKey);
        NSData *imageData = [NSData dataWithContentsOfFile:pathForKey];
        UIImage *diskImage = [UIImage imageWithData:imageData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completed(diskImage,nil,ImageCacheTypeDisk);
        });
    }
}




/**
 *  清空全部
 *
 *  @param completion completion
 */
- (void)clearDiskOnCompletion:(NoParamsBlock)completion
{
    dispatch_async(self.ioSerialQueue, ^{
        [_fileMange removeItemAtPath:self.diskCachePath error:nil];
        [_fileMange createDirectoryAtPath:self.diskCachePath
              withIntermediateDirectories:YES
                               attributes:nil
                                    error:NULL];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    });
}


/**
 *  按条件进行清空(主要是时间)
 *
 *  @param noParamsBlock completion
 */
-(void)clearDiskWithNoParamsBlock:(NoParamsBlock)noParamsBlock{
    
    dispatch_async(self.ioSerialQueue, ^{
        
        NSURL *diskCache = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];
        NSArray *resourcKeys = @[NSURLIsDirectoryKey,NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey];
        
        
        
        // 1. 该枚举器预先获取缓存文件的有用的属性
        NSDirectoryEnumerator *fileEnumerator = [_fileMange enumeratorAtURL:diskCache
                                                 includingPropertiesForKeys:resourcKeys
                                                                    options:NSDirectoryEnumerationSkipsHiddenFiles
                                                               errorHandler:NULL];
        
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-60 * 60 * 24 * 7];
        NSMutableDictionary *cacheFiles = [NSMutableDictionary dictionary];
        NSInteger currentCacheSize = 0;
        
        NSMutableArray *urlsToDelete = [[NSMutableArray alloc] init];
        
        for (NSURL *fileURL in fileEnumerator) {
            NSDictionary *resourceValues = [fileURL resourceValuesForKeys:resourcKeys error:NULL];
            
            
            // 3. 跳过文件夹
            if ([resourceValues[NSURLIsDirectoryKey] boolValue]) {
                continue;
            }
            
            NSDate *modificationDate = resourceValues[NSURLContentModificationDateKey];
            if ([[modificationDate laterDate:expirationDate] isEqualToDate:expirationDate]) {
                [urlsToDelete addObject:fileURL];
                
                continue;
            }
            
            
            // 5. 存储文件的引用并计算所有文件的总大小，以备后用
            NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
            currentCacheSize += [totalAllocatedSize unsignedIntegerValue];
            [cacheFiles setObject:resourceValues forKey:fileURL];
            
        }
        
        for (NSURL *fileURL in urlsToDelete) {
            [self.fileMange removeItemAtURL:fileURL error:NULL];
        }
        
        if (self.maxCacheSize > 0 && currentCacheSize > self.maxCacheSize) {
            const NSUInteger desiredCacheSize = self.maxCacheSize / 2;
            
            // Sort the remaining cache files by their last modification time (oldest first).
            NSArray *sortedFiles = [cacheFiles keysSortedByValueWithOptions:NSSortConcurrent
                                                            usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                                return [obj1[NSURLContentModificationDateKey] compare:obj2[NSURLContentModificationDateKey]];
                                                            }];
            
            // Delete files until we fall below our desired cache size.
            for (NSURL *fileURL in sortedFiles) {
                if ([_fileMange removeItemAtURL:fileURL error:nil]) {
                    NSDictionary *resourceValues = cacheFiles[fileURL];
                    NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
                    currentCacheSize -= [totalAllocatedSize unsignedIntegerValue];
                    
                    if (currentCacheSize < desiredCacheSize) {
                        break;
                    }
                }
            }
        }
        if (noParamsBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                noParamsBlock();
            });
        }
        
    });
    
}



/**
 *  盗用了SDWebImage的设计,将文件名按照MD5进行命名，保持唯一性
 *
 *  @param key urlKey
 *
 *  @return 文件名是对key值做MD5摘要后的串
 */
#pragma mark LDSImageCache (private)

- (NSString *)cachePathForKey:(NSString *)key inPath:(NSString *)path {
    NSString *filename = [self cachedFileNameForKey:key];
    return [path stringByAppendingPathComponent:filename];
}

- (NSString *)defaultCachePathForKey:(NSString *)key {
    return [self cachePathForKey:key inPath:self.diskCachePath];
}

- (NSString *)cachedFileNameForKey:(NSString *)key {
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[16];
    CC_MD5(str, (uint32_t)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    
    return filename;
}
@end
