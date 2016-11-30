//
//  people.h
//  BGFMDB
//
//  Created by huangzhibiao on 16/9/27.
//  Copyright © 2016年 Biao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface people : NSObject
{
    @public
    int testAge;
    NSString* testName;
}

@property(nonatomic,copy)NSString* name;
@property(nonatomic,strong)NSNumber* num;
@property(nonatomic,assign)int age;
@property(nonatomic,copy)NSString* sex;
@property(nonatomic,copy)NSString* sex_old;
@property(nonatomic,strong)NSArray* students;
@property(nonatomic,strong)NSDictionary* info;


-(void)test;

@end
