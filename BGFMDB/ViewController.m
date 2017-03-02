//
//  ViewController.m
//  BGFMDB
//
//  Created by huangzhibiao on 16/4/28.
//  Copyright © 2016年 Biao. All rights reserved.
//

#import "ViewController.h"
#import "people.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *showImage;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //存储对象使用示例
    [NSObject setDebug:YES];//打开调试模式,输出SQL语句.
    People* p = [People new];
    p.name = @"马哥";
    p.num = @(220.88);
    p.age = 28;
    p.eye = @"双眼皮";
    p.Url = [NSURL URLWithString:@"http://www.gmjk.com"];
    p.range = NSMakeRange(0,10);
    p.rect = CGRectMake(0,0,10,20);
    p.size = CGSizeMake(50,50);
    p.point = CGPointMake(2.55,3.14);
    p.color = [UIColor colorWithRed:11.1 green:22.2 blue:33 alpha:0.5];
    p.image = [UIImage imageNamed:@"MarkMan"];
    p.data = UIImageJPEGRepresentation(p.image, 1);

    [p setValue:@(110) forKey:@"testAge"];
    p->testName = @"测试名字";
    p.sex_old = @"新名";
    User* user = [[User alloc] init];
    user.name = @"测试用户名字...重复吗?";
    user.attri = @{@"用户名":@"黄芝标",@"密码":@(123456),@"数组":@[@"数组1",@"数组2"],@"集合":@{@"集合1":@"集合2"}};
    Student* student = [[Student alloc] init];
    student.num = @"测试学生数量...标哥";
    student.names = @[@"小哥哥",@"小红",@(110),@[@"数组元素1",@"数组元素2"],@{@"集合key":@"集合value"}];
    Human* human = [[Human alloc] init];
    human.sex = @"人妖";
    human.body = @"小芳";
    student.human = human;
    user.student = student;
    p.students = @[@(1),@"呵呵",@[@"数组元素1",@"数组元素2"],@{@"集合key":@"集合value"},student];
    p.info = @{@"name":@"标哥",@"年龄":@(1),@"数组":@[@"数组1",@"数组2"],@"集合":@{@"集合1":@"集合2"},@"user":user};
    
    NSHashTable* hashTable = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    [hashTable addObject:@"h1"];
    [hashTable addObject:@"h2"];
    [hashTable addObject:student];
    NSMapTable* mapTable = [NSMapTable  weakToWeakObjectsMapTable];
    [mapTable setObject:@"m_key1" forKey:@"m_value1"];
    [mapTable setObject:@"m_key2" forKey:@"m_value2"];
    [mapTable setObject:@"m_key3" forKey:user];
    NSSet* set1 = [NSSet setWithObjects:@"1",@"2",student, nil];
    NSMutableSet* set2 = [NSMutableSet set];
    [set2 addObject:@{@"key1":@"value"}];
    [set2 addObject:@{@"key2":user}];
    p.user = user;
    p.user1 = [User new];
    p.user1.name = @"芳姐";
    p.bfloat = 8.88;
    p.user.userAge = 1.024;
    p.user.userNumer = @(3.14);
    p.user.student.human.humanAge = 9999;
    
    p.hashTable = hashTable;
    p.mapTable = mapTable;
    p.nsset = set1;
    p.setM = set2;
//    for(int i=0;i<20;i++){
//        p.age = i;
//        [p save];//存储
//    }
    //[People refreshAsync:NO complete:nil];
    BOOL saveState = [p save];//存储
    //NSArray* array = [People findAll];
//    p.name = @"标哥更新...13_2";
//    [p updateWhere:@[@"name",@"=",@"标哥",@"num",@"=",@(220.88)]];
//    [p updateAsync:YES where:@[@"age",@"=",@"14",@"num",@"=",@(220.88)] complete:^(BOOL isSuccess) {
//        !isSuccess?:NSLog(@"更新成功!");
//    }];
    //[People clear];//清除
    //[People drop];//删类表
//    [p coverAsync:NO complete:^(BOOL isSuccess) {
//        if (isSuccess) {
//            NSLog(@"成功覆盖");
//        }else{
//            NSLog(@"覆盖失败!");
//        }
//    }];
//    [People findAsync:NO forKeyPath:@"user.student.human.sex" value:@"人妖" complete:^(NSArray * _Nullable array) {
//        NSLog(@"结果 = %@",array);
//    }];
    //[People deleteWhere:@[@"ID",@"=",@(3)]];
    NSArray* finfAlls = [People findAll];
    for(People* obj in finfAlls){
        _showImage.image = [UIImage imageWithData:obj.data];
        for(id value in obj.nsset){
            NSLog(@"NSSet = %@",value);
        }

        for(id value in obj.mapTable.objectEnumerator.allObjects){
            NSLog(@"mapTable = %@",value);
        }
        for(id value in obj.hashTable){
            NSLog(@"hashTable = %@",value);
        }
        NSLog(@"主键ID = %@",obj.ID);
        NSLog(@"查询结果： name = %@，testAge = %d,testName = %@,num = %@,age = %d,students = %@,info = %@,eye = %@,user.name = %@,user.密码 = %@ , user.student.num = %@,user.student.names[0] = %@, user.student.humane.sex = %@,p.user.student.human.body = %@",obj.name,obj->testAge,obj->testName,obj.num,obj.age,obj.students,obj.info,obj.eye,obj.user.name,obj.user.attri[@"密码"],obj.user.student.num,obj.user.student.names[0],obj.user.student.human.sex,obj.user.student.human.body);
    }
//    [People findAsync:NO where:@[@"name",@"=",@"标哥"] complete:^(NSArray * _Nullable array) {
//        for(People* p in array){
//            NSLog(@"查询结果： name = %@，testAge = %d,testName = %@,num = %@,age = %d,students = %@,info = %@,eye = %@,user.name = %@,user.密码 = %@ , user.student.num = %@,user.student.names[0] = %@, user.student.humane.sex = %@,p.user.student.human.body = %@",p.name,p->testAge,p->testName,p.num,p.age,p.students,p.info,p.eye,p.user.name,p.user.attri[@"密码"],p.user.student.num,p.user.student.names[0],p.user.student.human.sex,p.user.student.human.body);
//        }
//
//    }];
//    [Man findAllAsync:NO complete:^(NSArray * _Nullable array) {
//        NSLog(@"结果 = %@",array);
//    }];
    //[Man refreshAsync:NO complete:nil];
    //将People的name拷贝给Man的Man_name，其他同理.
//    [People copyAsync:NO toClass:[Man class] keyDict:@{@"name":@"Man_name",
//                                                       @"num":@"Man_num",
//                                                       @"age":@"Man_age",
//                                                       @"image":@"image"}
//               append:NO complete:^(dealState result) {
//                 NSLog(@"拷贝状态 = %ld",result);
//             }];
//    [Man findAllAsync:NO complete:^(NSArray * _Nullable array) {
//        for(Man* man in array){
//            NSLog(@"Man_name = %@  , Man_num = %@ , Man_age = %d",man.Man_name,man.Man_num,man.Man_age);
//        }
//        Man* mm = [array lastObject];
//        _showImage.image = mm.image;
//    }];
    //当类里面的变量名时,调用此API刷新一下这个类的数据.
//    [People refreshAsync:NO complete:^(dealState result) {
//        NSLog(@"刷新状态 = %ld",result);
//    }];
//    [People findAllAsync:YES limit:0 orderBy:@"age" desc:YES complete:^(NSArray * _Nullable array) {
//        for(People* p in array){
//            NSLog(@"查询结果： name = %@，testAge = %d,testName = %@,num = %@,age = %d,students = %@,info = %@,eye = %@,user.name = %@,user.密码 = %@ , user.student.num = %@,user.student.names[0] = %@, user.student.humane.sex = %@,p.user.student.human.body = %@",p.name,p->testAge,p->testName,p.num,p.age,p.students,p.info,p.eye,p.user.name,p.user.attri[@"密码"],p.user.student.num,p.user.student.names[0],p.user.student.human.sex,p.user.student.human.body);
//        }
//    }];
    //NSLog(@"数量 = %ld",[People countWhere:@[@"age",@">=",@(21),@"name",@"=",@"马哥"]]);
    //NSLog(@"数量 = %ld",[People countWhere:nil]);
    NSLog(@".....");
//    [People findAllAsync:NO range:NSMakeRange(10,5) orderBy:nil desc:NO complete:^(NSArray * _Nullable array) {
//        for(People* p in array){
//            NSLog(@"查询结果： name = %@，testAge = %d,testName = %@,num = %@,age = %d,students = %@,info = %@,eye = %@,user.name = %@,user.密码 = %@ , user.student.num = %@,user.student.names[0] = %@, user.student.humane.sex = %@,p.user.student.human.body = %@",p.name,p->testAge,p->testName,p.num,p.age,p.students,p.info,p.eye,p.user.name,p.user.attri[@"密码"],p.user.student.num,p.user.student.names[0],p.user.student.human.sex,p.user.student.human.body);
//        }
//    }];

}

@end
