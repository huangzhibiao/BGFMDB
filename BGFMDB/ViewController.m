//
//  ViewController.m
//  BGFMDB
//
//  Created by huangzhibiao on 16/4/28.
//  Copyright © 2016年 Biao. All rights reserved.
//

#import "ViewController.h"
#import "stockController.h"
#import "people.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *showImage;
- (IBAction)insertAction:(id)sender;
- (IBAction)deleteAction:(id)sender;
- (IBAction)updateAction:(id)sender;
- (IBAction)registerChangeAction:(id)sender;
- (IBAction)removeChangeAction:(id)sender;

- (IBAction)stockAction:(id)sender;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    People* p = [self people];
    
    /**
     存储
     */
    [p save];
   
    /**
     获取该类的数据库版本号;
     */
    //NSInteger version = [People version];
    
    /**
     如果类'变量名'或'唯一约束'发生改变,则调用此API刷新该类数据库,不需要新旧映射的情况下使用此API.
     */
    //[People updateVersion:version];
    
    /**
     如果类'变量名'或'唯一约束'发生改变,则调用此API刷新该类数据库.data2是新变量名,data是旧变量名,即将旧的值映射到新的变量名,其他不变的变量名会自动复制,只管写出变化的对应映射即可.
     */
    //[People updateVersion:version keyDict:@{@"data2":@"data"}];
    
    /**
     事务操作,返回YES提交事务,返回NO则会滚事务.
     */
//    [NSObject inTransaction:^BOOL{
//        [p save];//存储
//        [p save];
//        return NO;
//    }];
    
    /**
     将People类数据中name=@"标哥"，num=220.88的数据更新为当前对象的数据.
     */
    //[p updateWhere:@[@"name",@"=",@"标哥",@"num",@"=",@(220.88)]];

    
    /**
     清除People表的所有数据
     */
    //[People clear];
    
    /**
     删除People的数据表
     */
    //[People drop];
    
    /**
     覆盖掉原来People类的所有数据,只存储当前对象的数据.
     */
    //[p cover];
    
    /**
     将People类中user1.name包含@“小明”字符串 和 user.student.human.sex中等于@“女”的数据 更新为当前对象的数据.
     */
    //BOOL updateResult = [p updateForKeyPathAndValues:@[@"user1.name",Contains,@"小明",@"user.student.human.sex",Equal,@"女"]];
    
    /**
     删除People类数据中主键ID=3的数据.
     */
    //[People deleteWhere:@[@"ID",@"=",@(3)]];
    
    /**
     将People类中name等于"马云爸爸"的数据的name设为"马化腾",此接口是为了方便开发者自由扩展更深层次的查询条件逻辑.
     */
    //[People updateFormatSqlConditions:@"set %@=%@ where %@=%@",sqlKey(@"name"),sqlValue(@"马化腾"),sqlKey(@"name"),sqlValue(@"马云爸爸")];
    
    /**
     将People类数据中name等于"马化腾"的数据更新为当前对象的数据.
     */
    //[p updateFormatSqlConditions:@"where %@=%@",sqlKey(@"name"),sqlValue(@"爸爸")];
    
    /**
     将People类数据中user.student.human.body等于"小芳"的数据更新为当前对象的数据.
     */
    //[p updateFormatSqlConditions:@"where %@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];
    
    /**
     删除People类中name等于"美国队长"的数据,此接口是为了方便开发者自由扩展更深层次的查询条件逻辑.
     */
    //[People deleteFormatSqlConditions:@"where %@=%@",sqlKey(@"name"),sqlValue(@"美国队长")];
    
    /**
     删除People类中user.student.human.body等于"小芳"的数据
     */
    //[People deleteFormatSqlConditions:@"where %@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];
    
    /**
     删除People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据
     */
    //[People deleteFormatSqlConditions:@"where %@=%@ and %@",sqlKey(@"name"),sqlValue(@"美国队长"),keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];
    
    /**
     查询People类中name等于"美国队长"的数据条数,此接口是为了方便开发者自由扩展更深层次的查询条件逻辑.
     */
    //NSInteger count = [People countFormatSqlConditions:@"where %@=%@",sqlKey(@"name"),sqlValue(@"美国队长")];
    
    /**
     查询People类中user.student.human.body等于"小芳"的数据条数.
     */
    //NSInteger count = [People countFormatSqlConditions:@"where %@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];
    
    /**
     查询People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据条数.
     */
    //NSInteger count = [People countFormatSqlConditions:@"where %@=%@ and %@",sqlKey(@"name"),sqlValue(@"美国队长"),keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];
    
    //NSLog(@"数量 = %ld",count);
    
    /**
     同步查询People类所有数据.
     */
    NSArray* finfAlls = [People findAll];
    People* lastObj = finfAlls.lastObject;
    _showImage.image = [UIImage imageWithData:lastObj.data2];
    self.view.backgroundColor = lastObj.color?lastObj.color:[UIColor whiteColor];
    for(People* obj in finfAlls){
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
    
    /**
     查询name等于爸爸和age等于45,或者name等于马哥的数据.  此接口是为了方便开发者自由扩展更深层次的查询条件逻辑.
     */
//    NSArray* arrayConds1 = [People findFormatSqlConditions:@"where %@=%@ and %@=%@ or %@=%@",sqlKey(@"age"),sqlValue(@(45)),sqlKey(@"name"),sqlValue(@"爸爸"),sqlKey(@"name"),sqlValue(@"马哥")];
//
    
    /**
     查询user.student.human.body等于小芳 和 user1.name中包含fuck这个字符串的数据.
     */
//    NSArray* arrayConds2 = [People findFormatSqlConditions:@"where %@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳",@"user1.name",Contains,@"fuck"])];
    
    /**
    查询user.student.human.body等于小芳,user1.name中包含fuck这个字符串 和 name等于爸爸的数据.
    */
//    NSArray* arrayConds3 = [People findFormatSqlConditions:@"where %@ and %@=%@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳",@"user1.name",Contains,@"fuck"]),sqlKey(@"name"),sqlValue(@"爸爸")];
    
    /**
     将People的name拷贝给Man的Man_name，其他同理.
     */
//    [People copyToClass:[Man class] keyDict:@{@"name":@"Man_name",
//                                                       @"num":@"Man_num",
//                                                       @"age":@"Man_age",
//                                                       @"image":@"image"}
//               append:NO];
    /**
     异步查询Man的所有数据.
     */
//    NSArray* mans = [Man findAll];
//    for(Man* man in mans){
//        NSLog(@"Man_name = %@  , Man_num = %@ , Man_age = %d",man.Man_name,man.Man_num,man.Man_age);
//    }

    /**
     异步查询People类的数据,查询限制3条,通过age降序排列.
     */
//    [People findAllAsyncWithLimit:3 orderBy:@"age" desc:YES complete:^(NSArray * _Nullable array) {
//        for(People* p in array){
//            NSLog(@"查询结果： name = %@，testAge = %d,testName = %@,num = %@,age = %d,students = %@,info = %@,eye = %@,user.name = %@,user.密码 = %@ , user.student.num = %@,user.student.names[0] = %@, user.student.humane.sex = %@,p.user.student.human.body = %@",p.name,p->testAge,p->testName,p.num,p.age,p.students,p.info,p.eye,p.user.name,p.user.attri[@"密码"],p.user.student.num,p.user.student.names[0],p.user.student.human.sex,p.user.student.human.body);
//        }
//    }];
    
    /**
     查询People类中age>=21,name=@"马哥"的数据条数.
     */
    //NSLog(@"数量 = %ld",[People countWhere:@[@"age",@">=",@(21),@"name",@"=",@"马哥"]]);
    
    /**
     查询People类中所有数据的条数.
     */
    //NSLog(@"数量 = %ld",[People countWhere:nil]);
    
    /**
     异步查询People类的数据,查询范围从第10处开始的后面5条,不排序.
     */
//    [People findAllAsyncWithRange:NSMakeRange(10,5) orderBy:nil desc:NO complete:^(NSArray * _Nullable array) {
//        for(People* p in array){
//            NSLog(@"查询结果： name = %@，testAge = %d,testName = %@,num = %@,age = %d,students = %@,info = %@,eye = %@,user.name = %@,user.密码 = %@ , user.student.num = %@,user.student.names[0] = %@, user.student.humane.sex = %@,p.user.student.human.body = %@",p.name,p->testAge,p->testName,p.num,p.age,p.students,p.info,p.eye,p.user.name,p.user.attri[@"密码"],p.user.student.num,p.user.student.names[0],p.user.student.human.sex,p.user.student.human.body);
//        }
//    }];

}

-(People*)people{
    //存储对象使用示例
    [NSObject setDebug:YES];//打开调试模式,输出SQL语句.
    People* p = [People new];
    p.name = @"美国队长";
    p.num = @(220.88);
    p.age = 50;
    p.eye = @"末世眼皮";
    p.Url = [NSURL URLWithString:@"http://www.gmjk.com"];
    p.range = NSMakeRange(0,10);
    p.rect = CGRectMake(0,0,10,20);
    p.size = CGSizeMake(50,50);
    p.point = CGPointMake(2.55,3.14);
    p.color = [UIColor colorWithRed:245 green:245 blue:245 alpha:1.0];
    p.image = [UIImage imageNamed:@"MarkMan"];
    p.data2 = UIImageJPEGRepresentation(p.image, 1);
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
    human.sex = @"女";
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
    p.user1.name = @"小明_fuck2222";
    p.bfloat = 8.88;
    p.user.userAge = 1.024;
    p.user.userNumer = @(3.14);
    p.user.student.human.humanAge = 9999;
    
    p.hashTable = hashTable;
    p.mapTable = mapTable;
    p.nsset = set1;
    p.setM = set2;
    return p;
}
- (IBAction)insertAction:(id)sender {
    People* p = [self people];
    [p save];
}

- (IBAction)deleteAction:(id)sender{
    [People deleteWhere:@[@"ID",@"=",@(3)]];
}

- (IBAction)updateAction:(id)sender {
    People* p = [self people];
    [p updateWhere:@[@"ID",@"=",@(4)]];
}

- (IBAction)registerChangeAction:(id)sender{
    [People registerChangeWithName:@"insert" block:^(changeState result) {
        switch (result) {
            case Insert:
                NSLog(@"有数据插入");
                break;
            case Update:
                NSLog(@"有数据更新");
                break;
            case Delete:
                NSLog(@"有数据删删除");
                break;
            case Drop:
                NSLog(@"有表删除");
                break;
            default:
                break;
        }
    }];
}

- (IBAction)removeChangeAction:(id)sender{
    [People removeChangeWithName:@"insert"];
}

- (IBAction)stockAction:(id)sender {
    stockController* con = [stockController new];
    [self presentViewController:con animated:YES completion:nil];
}
@end
