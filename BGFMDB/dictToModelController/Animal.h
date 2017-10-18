//
//  Animal.h
//  BGFMDB
//
//  Created by huangzhibiao on 17/3/14.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BGFMDB.h"//引入所需头文件.

@class Dog;

@interface Animal : NSObject
@property(nonatomic,strong)NSArray* foods;
@property(nonatomic,strong)NSDictionary* body;


@end

@interface Dog : Animal

@property(nonatomic,copy)NSString* name;
@property(nonatomic,strong)NSNumber* age;
@property(nonatomic,copy)NSString* specy;

@end

@interface Body:NSObject

@property(nonatomic,copy)NSString* hand;
@property(nonatomic,copy)NSString* leg;
@property(nonatomic,strong)Dog* dog;

@end

@interface My : NSObject

@property(nonatomic,copy)NSString* name;
@property(nonatomic,copy)NSString* intro;
@property(nonatomic,copy)NSString* sex;
@property(nonatomic,strong)NSArray* dogs;
@property(nonatomic,strong)NSArray* bodys;
@property(nonatomic,strong)NSArray* foods;
@property(nonatomic,strong)Body* body;
@property(nonatomic,strong)Dog* dog;
@end
