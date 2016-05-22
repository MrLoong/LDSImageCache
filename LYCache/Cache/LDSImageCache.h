//
//  LDImageCache.h
//  LYCache
//
//  Created by LastDays on 16/4/20.
//  Copyright © 2016年 LastDays. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef NS_ENUM(NSInteger,ImageCacheType){
    /**
     * 无类型
     */
    ImageCacheTypeNone,
    /**
     * 磁盘中缓存
     */
    ImageCacheTypeDisk,
    /**
     * 内存中缓存
     */
    ImageCacheTypeMemory
};

/**
 *  CompletedBlock
 *
 *  @param image 图片
 *  @param error 错误信息
 *  @param type  读取类型
 */
typedef void(^CompletedBlock)(UIImage *image,NSError *error,ImageCacheType type);

/**
 *  无参Block
 */
typedef void(^NoParamsBlock)();

@interface LDSImageCache : NSObject

/**
 *  最大缓存大小
 */
@property (assign, nonatomic) NSUInteger maxCacheSize;


/**
 *  单例方法
 *
 *  @return LDImageCache实例
 */
+(LDSImageCache *)shareLDImageCache;

/**
 *  对图片进行缓存
 *
 *  @param memoryCache  内存缓存
 *  @param image        图片
 *  @param imageData    图片Data
 *  @param urlKey       key值
 *  @param isSaveToDisk 是否存入Disk
 */
-(void)saveImageWithMemoryCache:(NSCache *)memoryCache image:(UIImage *)image imageData:(NSData *)imageData urlKey:(NSString *)urlKey isSaveToDisk:(BOOL)isSaveToDisk;

/**
 *  查询图片
 *
 *  @param urlKey    urlkey
 *  @param completed CompletedBlock
 */
-(void)selectImageWithKey:(NSString *)urlKey completedBlock:(CompletedBlock)completed;


/**
 *  清空全部
 *
 *  @param completion completion
 */
- (void)clearDiskOnCompletion:(NoParamsBlock)completion;

-(void)clearDiskWithNoParamsBlock:(NoParamsBlock)noParamsBlock;


- (instancetype)initWithCacheSpace:(NSString *)path;

@end
