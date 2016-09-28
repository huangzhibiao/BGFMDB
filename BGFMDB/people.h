//
//  people.h
//  BGFMDB
//
//  Created by huangzhibiao on 16/9/27.
//  Copyright © 2016年 Biao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface people : NSObject

@property(nonatomic,copy)NSString* name;
@property(nonatomic,strong)NSNumber* num;
@property(nonatomic,assign)int age;

-(void)test;

@end
