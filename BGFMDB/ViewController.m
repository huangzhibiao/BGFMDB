//
//  ViewController.m
//  BGFMDB
//
//  Created by huangzhibiao on 16/4/28.
//  Copyright © 2016年 Biao. All rights reserved.
//

#import "ViewController.h"
#import "people.h"
#import "BGFMDB.h"

#define tableName @"TestTable"

@interface ViewController ()


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //存储对象使用示例
    [People setDebug:YES];//打开调试模式,输出SQL语句.
    People* p = [[People alloc] init];
    p.name = @"标哥";
    p.num = @(220.88);
    p.age = rand();
    p.eye = @"单眼皮";
    //p.sex = @"男";
    [p setValue:@(110) forKey:@"testAge"];
    p->testName = @"测试名字";
    p.sex_old = @"新名";
    p.students = @[@(1),@"呵呵"];
    p.info = @{@"name":@"标哥",@"年龄":@(1)};
    User* user = [[User alloc] init];
    user.name = @"测试用户名字...重复吗?";
    user.attri = @{@"用户名":@"黄芝标",@"密码":@(123456)};
    Student* student = [[Student alloc] init];
    student.num = @"测试学生数量...标哥";
    student.names = @[@"小哥哥",@"小红",@(110)];
    Human* human = [[Human alloc] init];
    human.sex = @"女生";
    human.body = @"小芳";
    student.human = human;
    user.student = student;
    p.user = user;
    p.user1 = [User new];
    p.user1.name = @"用户名1";
    p.bfloat = 8.88;
    p.user.userAge = 1.024;
    p.user.userNumer = @(3.14);
    p.user.student.human.humanAge = 9999;
    p.addName = @"addName";
    for(int i=0;i<20;i++){
        p.age = i;
        p.addAge = i;
        [p save];//存储
    }
    //NSArray* array = [People findAll];
//    p.name = @"标哥更新...13_2";
    //[p updateWhere:@[@"age",@"=",@"13",@"num",@"=",@(220.88)]];更新
//    [p updateAsync:YES where:@[@"age",@"=",@"14",@"num",@"=",@(220.88)] complete:^(BOOL isSuccess) {
//        !isSuccess?:NSLog(@"更新成功!");
//    }];
    //[People clear];//清除
    //[People drop];//删类表
//    [People findAsync:NO where:nil complete:^(NSArray * _Nullable array) {
//        for(People* p in array){
//            NSLog(@"查询结果： name = %@，testAge = %d,testName = %@,num = %@,age = %d,students = %@,info = %@,eye = %@,user.name = %@,user.密码 = %@ , user.student.num = %@,user.student.names[0] = %@, user.student.humane.sex = %@,p.user.student.human.body = %@",p.name,p->testAge,p->testName,p.num,p.age,p.students,p.info,p.eye,p.user.name,p.user.attri[@"密码"],p.user.student.num,p.user.student.names[0],p.user.student.human.sex,p.user.student.human.body);
//        }
//
//    }];
//    [Man findAllAsync:NO complete:^(NSArray * _Nullable array) {
//        NSLog(@"结果 = %@",array);
//    }];
    //即将People的name拷贝给Man的Man_name，其他同理.
//    [People copyAsync:NO toClass:[Man class] keyDict:@{@"name":@"Man_name",
//                                                       @"num":@"Man_num",
//                                                       @"age":@"Man_age"}
//               append:NO complete:^(dealState result) {
//                 NSLog(@"拷贝状态 = %ld",result);
//             }];
//    //当类里面的变量名时,调用此API刷新一下这个类的数据.
//    [People refreshAsync:NO complete:^(refreshState result) {
//        NSLog(@"刷新状态 = %ld",result);
//    }];
//    [People findAllAsync:YES limit:0 orderBy:@"age" desc:YES complete:^(NSArray * _Nullable array) {
//        for(People* p in array){
//            NSLog(@"查询结果： name = %@，testAge = %d,testName = %@,num = %@,age = %d,students = %@,info = %@,eye = %@,user.name = %@,user.密码 = %@ , user.student.num = %@,user.student.names[0] = %@, user.student.humane.sex = %@,p.user.student.human.body = %@",p.name,p->testAge,p->testName,p.num,p.age,p.students,p.info,p.eye,p.user.name,p.user.attri[@"密码"],p.user.student.num,p.user.student.names[0],p.user.student.human.sex,p.user.student.human.body);
//        }
//    }];
    //NSLog(@"数量 = %ld",[People countWhere:@[@"age",@">=",@(18),@"name",@"=",@"标哥"]]);
    
    NSLog(@".....");
//    [People findAllAsync:NO range:NSMakeRange(10,5) orderBy:@"age" desc:NO complete:^(NSArray * _Nullable array) {
//        for(People* p in array){
//            NSLog(@"查询结果： name = %@，testAge = %d,testName = %@,num = %@,age = %d,students = %@,info = %@,eye = %@,user.name = %@,user.密码 = %@ , user.student.num = %@,user.student.names[0] = %@, user.student.humane.sex = %@,p.user.student.human.body = %@",p.name,p->testAge,p->testName,p.num,p.age,p.students,p.info,p.eye,p.user.name,p.user.attri[@"密码"],p.user.student.num,p.user.student.names[0],p.user.student.human.sex,p.user.student.human.body);
//        }
//    }];

}

@end
