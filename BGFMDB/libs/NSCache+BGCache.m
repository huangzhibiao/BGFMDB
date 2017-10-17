//
//  NSCache+BGCache.m
//  BGFMDB
//
//  Created by biao on 2017/10/17.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import "NSCache+BGCache.h"

static NSCache* keyCaches;
@implementation NSCache (BGCache)

+(instancetype)bg_cache{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keyCaches = [NSCache new];
    });
    return keyCaches;
}

@end
