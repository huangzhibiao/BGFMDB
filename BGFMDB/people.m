//
//  people.m
//  BGFMDB
//
//  Created by huangzhibiao on 16/9/27.
//  Copyright © 2016年 Biao. All rights reserved.
//

#import "people.h"

@implementation Man

@end

@implementation People

/**
 如果需要指定“唯一约束”字段,就实现该函数,这里指定 name和age 为“唯一约束”.
 */
//+(NSArray *)bg_uniqueKeys{
//    return @[@"name",@"age"];
//}

/**
 设置不需要存储的属性.
 */
//+(NSArray *)bg_ignoreKeys{
//   return @[@"eye",@"sex",@"num"];
//}

@end

@implementation User

@end

@implementation Student

@end

@implementation Human

@end
