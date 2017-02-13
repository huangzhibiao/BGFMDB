//
//  people.h
//  BGFMDB
//
//  Created by huangzhibiao on 16/9/27.
//  Copyright © 2016年 Biao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BGManageObject.h"

//提示: 所有新建的模型要继承BGManageObject类,用于类中变量的嵌套解析等.
@interface Human : BGManageObject

@property(nonatomic,copy)NSString* sex;
@property(nonatomic,copy)NSString* body;

@end

@interface Student : BGManageObject

@property(nonatomic,copy)NSString* num;
@property(nonatomic,strong)NSArray* names;
@property(nonatomic,strong)Human* human;

@end

@interface User : BGManageObject

@property(nonatomic,copy)NSString* name;
@property(nonatomic,strong)NSDictionary* attri;
@property(nonatomic,strong)Student* student;//第二层类嵌套 , 可以无穷嵌套...

@end

@interface People : BGManageObject
{
    @public
    int testAge;
    NSString* testName;
}


@property(nonatomic,copy)NSString* name;
@property(nonatomic,strong)NSNumber* num;
@property(nonatomic,assign)int age;
//@property(nonatomic,copy)NSString* sex;
@property(nonatomic,copy)NSString* eye;
@property(nonatomic,copy)NSString* sex_old;
@property(nonatomic,strong)NSArray* students;
@property(nonatomic,strong)NSDictionary* info;
@property(nonatomic,strong)User* user;//第一层类嵌套


-(void)test;

@end
