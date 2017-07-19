//
//  ViewController.m
//  BGFMDB
//
//  Created by huangzhibiao on 16/4/28.
//  Copyright © 2016年 Biao. All rights reserved.
//

#import "ViewController.h"
#import "stockController.h"
#import "dictToModelController.h"
#import "people.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *showImage;
@property (weak, nonatomic) IBOutlet UILabel *showLab;


- (IBAction)insertAction:(id)sender;
- (IBAction)deleteAction:(id)sender;
- (IBAction)updateAction:(id)sender;
- (IBAction)registerChangeAction:(id)sender;
- (IBAction)removeChangeAction:(id)sender;

- (IBAction)stockAction:(id)sender;
- (IBAction)dictToModelAction:(id)sender;



@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    //想测试更多功能,打开注释掉的代码即可.
    bg_setDebug(YES);//打开调试模式,打印输出调试信息.
    //自定义数据库名称，否则默认为BGFMDB
    //bg_setSqliteName(@"Tencent");
    //删除自定义数据库.
    //bg_deleteSqlite(@"Tencent");
    
    /**
     直接存储数组.
     */
    //[self testSaveArray];
    /**
     直接存储字典.
    */
    //[self testSaveDictionary];
    
    
    /**
     直接存储自定义对象.
     */
    People* p = [self people];
    
    /**
     存储
     */
    //[p bg_save];
    
    /**
     使用原生函数求某个整数类型的属性的总和，最大值，最小值，平均值等.
     */
//    NSInteger num = [People bg_sqliteMethodWithType:bg_sum key:@"age" where:@"where %@>20 and %@=%@",sqlKey(@"age"),sqlKey(@"name"),sqlValue(@"斯巴达")];
//    NSLog(@"sum(age) = %@",@(num));
    
    /**
     同步存储或更新.
     当自定义“唯一约束”时可以使用此接口存储更方便,当"唯一约束"的数据存在时，此接口会更新旧数据,没有则存储新数据.
     */
    //[p bg_saveOrUpdate];
    
    /**
     忽略存储，即忽略掉 user,info,students 这三个变量不存储.
     */
    //[p bg_saveIgnoredKeys:@[@"user",@"info",@"students"]];
   
    /**
     获取该类的数据库版本号;
     */
    //NSInteger version = [People bg_version];
    
    /**
     如果类'变量名'或'唯一约束'发生改变,则调用此API刷新该类数据库,不需要新旧映射的情况下使用此API.
     */
    //[People bg_updateVersion:[People version]+1];
    
    /**
     如果类'变量名'或'唯一约束'发生改变,则调用此API刷新该类数据库.data2是新变量名,data是旧变量名,即将旧的值映射到新的变量名,其他不变的变量名会自动复制,只管写出变化的对应映射即可.
     */
    //[People bg_updateVersion:version keyDict:@{@"data2":@"data"}];
    
    /**
     事务操作,返回YES提交事务,返回NO则回滚事务.
     */
//    [NSObject bg_inTransaction:^BOOL{
//        [p bg_save];//存储
//        [p bg_save];
//        [People bg_clear];//清除全部People的数据.
//        return YES;
//    }];
    
    /**
     将People类数据中name=@"标哥"，num=220.88的数据更新为当前对象的数据.
     */
    //[p bg_updateWhere:@[@"name",@"=",@"标哥",@"num",@"=",@(220.88)]];
    
    /**
     更新age=5的数据成当前对象数据,忽略name不用更新.
     */
    //[p bg_updateWhere:@[@"age",@"=",@(50)] ignoreKeys:@[@"name"]];
    
    
    /**
     清除People表的所有数据
     */
    //[People bg_clear];
    
    /**
     删除People的数据表
     */
    //[People bg_drop];
    
    /**
     覆盖掉原来People类的所有数据,只存储当前对象的数据.
     */
    //[p bg_cover];
    
    /**
     将People类中user1.name包含@“小明”字符串 和 user.student.human.sex中等于@“女”的数据 更新为当前对象的数据.
     */
    //BOOL updateResult = [p bg_updateForKeyPathAndValues:@[@"user1.name",bg_contains,@"小明",@"user.student.human.sex",bg_equal,@"女"]];
    
    /**
     删除People类数据中主键ID=3的数据.
     */
    //[People bg_deleteWhere:@[@"ID",@"=",@(3)]];
    
    /**
     将People类中name等于"马云爸爸"的数据的name设为"马化腾",此接口是为了方便开发者自由扩展更深层次的查询条件逻辑.
     */
    //BOOL updateState = [People bg_updateFormatSqlConditions:@"set %@=%@ where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"马化腾"),bg_sqlKey(@"name"),bg_sqlValue(@"斯巴达")];

    /**
     将People类数据中name等于"马化腾"的数据更新为当前对象的数据.
     */
    //[p bg_updateFormatSqlConditions:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"爸爸")];
    
    /**
     将People类数据中user.student.human.body等于"小芳"的数据更新为当前对象的数据.
     */
    //[p bg_updateFormatSqlConditions:@"where %@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
    
    /**
     删除People类中name等于"美国队长"的数据,此接口是为了方便开发者自由扩展更深层次的查询条件逻辑.
     */
    //[People bg_deleteFormatSqlConditions:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"美国队长")];
    
    /**
     删除People类中user.student.human.body等于"小芳"的数据
     */
    //[People bg_deleteFormatSqlConditions:@"where %@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
    
    /**
     删除People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据
     */
    //[People bg_deleteFormatSqlConditions:@"where %@=%@ and %@",bg_sqlKey(@"name"),bg_sqlValue(@"美国队长"),bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
    
    /**
     查询People类中name等于"美国队长"的数据条数,此接口是为了方便开发者自由扩展更深层次的查询条件逻辑.
     */
    //NSInteger count = [People bg_countFormatSqlConditions:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"美国队长")];
    
    /**
     查询People类中user.student.human.body等于"小芳"的数据条数.
     */
    //NSInteger count = [People bg_countFormatSqlConditions:@"where %@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
    
    /**
     查询People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据条数.
     */
    //NSInteger count = [People bg_countFormatSqlConditions:@"where %@=%@ and %@",bg_sqlKey(@"name"),bg_sqlValue(@"美国队长"),bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"])];
    
    //NSLog(@"数量 = %ld",count);
    
    /**
     当数据量巨大时采用分页范围查询.
     */
    NSInteger count = [People bg_countWhere:nil];
    for(int i=0;i<count;i+=10){
            NSArray* arr = [People bg_findAllWithRange:NSMakeRange(i,10) orderBy:nil desc:NO];
        for(People* pp in arr){
            //库新增两个自带字段createTime和updateTime方便开发者使用和做参考对比.
             NSLog(@"主键 = %@, 创建时间 = %@, 更新时间 = %@",pp.bg_id,pp.bg_createTime,pp.bg_updateTime);
//            NSDateFormatter* formatter = [NSDateFormatter new];
//            formatter.dateFormat = @"yyyy年MM月dd日 HH时mm分ss秒";
//            NSLog(@"date = %@",[formatter stringFromDate:pp.date]);
        }
            if(i==0){
                People* p = arr.lastObject;
                _showImage.image = p.image;
                _showLab.attributedText = p.attriStr;
            }
    }
    
    /**
     同步查询People类所有数据.
     */
//    NSArray* finfAlls = [People bg_findAll];
//    People* lastObj = finfAlls.lastObject;
//    _showImage.image = [UIImage imageWithData:lastObj.data2];
//    self.view.backgroundColor = lastObj.color?lastObj.color:[UIColor whiteColor];
//    for(People* obj in finfAlls){
//        for(id value in obj.nsset){
//            NSLog(@"NSSet = %@",value);
//        }
//
//        for(id value in obj.mapTable.objectEnumerator.allObjects){
//            NSLog(@"mapTable = %@",value);
//        }
//        for(id value in obj.hashTable){
//            NSLog(@"hashTable = %@",value);
//        }
//        NSLog(@"主键ID = %@",obj.ID);
//        NSLog(@"查询结果： name = %@，testAge = %d,testName = %@,num = %@,age = %d,students = %@,info = %@,eye = %@,user.name = %@,user.密码 = %@ , user.student.num = %@,user.student.names[0] = %@, user.student.humane.sex = %@,p.user.student.human.body = %@",obj.name,obj->testAge,obj->testName,obj.num,obj.age,obj.students,obj.info,obj.eye,obj.user.name,obj.user.attri[@"密码"],obj.user.student.num,obj.user.student.names[0],obj.user.student.human.sex,obj.user.student.human.body);
//    }
    
    /**
     查询name等于爸爸和age等于45,或者name等于马哥的数据.  此接口是为了方便开发者自由扩展更深层次的查询条件逻辑.
     */
//    NSArray* arrayConds1 = [People bg_findFormatSqlConditions:@"where %@=%@ and %@=%@ or %@=%@",bg_sqlKey(@"age"),bg_sqlValue(@(45)),bg_sqlKey(@"name"),bg_sqlValue(@"爸爸"),bg_sqlKey(@"name"),bg_sqlValue(@"马哥")];
//
    
    /**
     查询user.student.human.body等于小芳 和 user1.name中包含fuck这个字符串的数据.
     */
//    NSArray* arrayConds2 = [People bg_findFormatSqlConditions:@"where %@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳",@"user1.name",bg_contains,@"fuck"])];
    
    /**
    查询user.student.human.body等于小芳,user1.name中包含fuck这个字符串 和 name等于爸爸的数据.
    */
//    NSArray* arrayConds3 = [People bg_findFormatSqlConditions:@"where %@ and %@=%@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳",@"user1.name",bg_contains,@"fuck"]),bg_sqlKey(@"name"),bg_sqlValue(@"爸爸")];
    
    /**
     将People的name拷贝给Man的Man_name，其他同理.
     */
//    [People bg_copyToClass:[Man class] keyDict:@{@"name":@"Man_name",
//                                                       @"num":@"Man_num",
//                                                       @"age":@"Man_age",
//                                                       @"image":@"image"}
//               append:YES];
    /**
     异步查询Man的所有数据.
     */
//    NSArray* mans = [Man bg_findAll];
//    for(Man* man in mans){
//        NSLog(@"Man_name = %@  , Man_num = %@ , Man_age = %d",man.Man_name,man.Man_num,man.Man_age);
//    }

    /**
     异步查询People类的数据,查询限制3条,通过age降序排列.
     */
//    [People bg_findAllAsyncWithLimit:3 orderBy:@"age" desc:YES complete:^(NSArray * _Nullable array) {
//        for(People* p in array){
//            NSLog(@"查询结果： name = %@，testAge = %d,testName = %@,num = %@,age = %d,students = %@,info = %@,eye = %@,user.name = %@,user.密码 = %@ , user.student.num = %@,user.student.names[0] = %@, user.student.humane.sex = %@,p.user.student.human.body = %@",p.name,p->testAge,p->testName,p.num,p.age,p.students,p.info,p.eye,p.user.name,p.user.attri[@"密码"],p.user.student.num,p.user.student.names[0],p.user.student.human.sex,p.user.student.human.body);
//        }
//    }];
    
    /**
     查询People类中age>=21,name=@"马哥"的数据条数.
     */
    //NSLog(@"数量 = %ld",[People bg_countWhere:@[@"age",@">=",@(21),@"name",@"=",@"马哥"]]);
    
    /**
     查询People类中所有数据的条数.
     */
    //NSLog(@"数量 = %ld",[People bg_countWhere:nil]);
    
    /**
     异步查询People类的数据,查询范围从第10处开始的后面5条,不排序.
     */
//    [People bg_findAllAsyncWithRange:NSMakeRange(10,5) orderBy:nil desc:NO complete:^(NSArray * _Nullable array) {
//        for(People* p in array){
//            NSLog(@"查询结果： name = %@，testAge = %d,testName = %@,num = %@,age = %d,students = %@,info = %@,eye = %@,user.name = %@,user.密码 = %@ , user.student.num = %@,user.student.names[0] = %@, user.student.humane.sex = %@,p.user.student.human.body = %@",p.name,p->testAge,p->testName,p.num,p.age,p.students,p.info,p.eye,p.user.name,p.user.attri[@"密码"],p.user.student.num,p.user.student.names[0],p.user.student.human.sex,p.user.student.human.body);
//        }
//    }];

}

#pragma mark 直接存储数组
-(void)testSaveArray{
    NSMutableArray* testA = [NSMutableArray array];
    [testA addObject:@"我是"];
    [testA addObject:@(10)];
    [testA addObject:@(9.999)];
    [testA addObject:@{@"key":@"value"}];
    Human* human = [Human new];
    human.sex = @"女";
    human.body = @"小芳";
    human.humanAge = 26;
    human.age = 15;
    human.num = 999;
    human.counts = 10001;
    human.food = @"大米";
    human.data = UIImageJPEGRepresentation([UIImage imageNamed:@"MarkMan"], 1);
    human.array = @[@"数组1",@"数组2",@"数组3",@(1),@(1.5)];
    human.dict = @{@"key1":@"value1",@"key2":@(2)};
    [testA addObject:human];
    /**
     存储标识名为testA的数组.
     */
    [testA bg_saveArrayWithName:@"testA"];
    
    /**
     往标识名为@"testA"的数组中添加元素.
     */
    //[NSArray bg_addObjectWithName:@"testA" object:@[@(1),@"哈哈"]];
    
    /**
     更新标识名为testA的数组某个位置上的元素.
     */
    //[NSArray bg_updateObjectWithName:@"testA" Object:@"人妖" Index:0];
    
    /**
     删除标识名为testA的数组某个位置上的元素.
     */
    //[NSArray bg_deleteObjectWithName:@"testA" Index:3];
    
    /**
     查询标识名为testA的数组全部元素.
     */
    NSArray* testResult = [NSArray bg_arrayWithName:@"testA"];
    
    /**
     获取标识名为testA的数组某个位置上的元素.
     */
    id arrObject = [NSArray bg_objectWithName:@"testA" Index:3];
    
    /**
     清除标识名为testA的数组所有元素.
     */
    //[NSArray bg_clearArrayWithName:@"testA"];
    
    NSLog(@"结果 = %@",testResult);
}

#pragma mark 直接存储集合
-(void)testSaveDictionary{
    Human* human = [Human new];
    human.sex = @"女";
    human.body = @"小芳";
    human.humanAge = 26;
    human.age = 15;
    human.num = 999;
    human.counts = 10001;
    human.food = @"大米";
    human.data = UIImageJPEGRepresentation([UIImage imageNamed:@"MarkMan"], 1);
    human.array = @[@"数组1",@"数组2",@"数组3",@(1),@(1.5)];
    human.dict = @{@"key1":@"value1",@"key2":@(2)};
    NSDictionary* dict = @{@"one":@(1),@"key":@"value",@"array":@[@(1.2),@"哈哈"],@"human":human};
    /**
     存储字典.
     */
    [dict bg_saveDictionary];
    /**
     添加字典元素.
     */
    //[NSDictionary bg_setValue:@"标哥" forKey:@"name"];
    
    /**
    更新字典元素.
     */
    //[NSDictionary bg_updateValue:@"人妖" forKey:@"key"];
    
    /**
     获取某个字典元素.
     */
    id num = [NSDictionary bg_valueForKey:@"one"];
    
    /**
     移除字典某个元素.
     */
    //[NSDictionary bg_removeValueForKey:@"key"];
    
    /**
     遍历字典元素.
     */
    [NSDictionary bg_enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull value, BOOL *stop) {
        NSLog(@"key = %@ , value = %@",key,value);
    }];
    
    /**
     清空字典.
     */
    //[NSDictionary bg_clearDictionary];
}

-(People*)people{
    //存储对象使用示例
    People* p = [People new];
    p.name = @"斯巴达";
    p.num = @(220.88);
    p.age = 30;
    p.sex = @"男";
    p.eye = @"末世眼皮";
    p.Url = [NSURL URLWithString:@"http://www.gmjk.com"];
    p.addBool = YES;
    p.range = NSMakeRange(0,10);
    p.rect = CGRectMake(0,0,10,20);
    p.size = CGSizeMake(50,50);
    p.point = CGPointMake(2.55,3.14);
    p.color = [UIColor colorWithRed:245 green:245 blue:245 alpha:1.0];
    NSMutableAttributedString* attStrM = [[NSMutableAttributedString alloc] initWithString:@"BGFMDB"];
    [attStrM addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0, 2)];
    p.attriStr = attStrM;
    p.image = [UIImage imageNamed:@"MarkMan"];
    NSData* data = UIImageJPEGRepresentation(p.image, 1);
    p.data2 = data;
    
    p.arrM = [NSMutableArray array];
    for(int i=1;i<=5;i++){
        [p.arrM addObject:UIImageJPEGRepresentation([UIImage imageNamed:[NSString stringWithFormat:@"ima%d",i]], 1)];
    }
    
    [p setValue:@(110) forKey:@"testAge"];
    p->testName = @"测试名字";
    p.sex_old = @"新名";
    User* user = [[User alloc] init];
    user.name = @"陈浩南";
    user.attri = @{@"用户名":@"黄芝标",@"密码":@(123456),@"数组":@[@"数组1",@"数组2"],@"集合":@{@"集合1":@"集合2"}};
    Student* student = [[Student alloc] init];
    student.num = @"测试学生数量...标哥";
    student.names = @[@"小哥哥",@"小红",@(110),@[@"数组元素1",@"数组元素2"],@{@"集合key":@"集合value"}];
    Human* human = [[Human alloc] init];
    human.sex = @"女";
    human.body = @"小";
    student.human = human;
    user.student = student;
    p.students = @[@(1),@"呵呵",@[@"数组元素1",@"数组元素2"],@{@"集合key":@"集合value"},student,data,student];
    p.infoDic = @{@"name":@"标哥",@"年龄":@(1),@"数组":@[@"数组1",@"数组2"],@"集合":@{@"集合1":@"集合2"},@"user":user,@"data":data};
    
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
    p.user.userAge = 13;
    p.user.userNumer = @(3.14);
    p.user.student.human.humanAge = 9999;
    
    p.hashTable = hashTable;
    p.mapTable = mapTable;
    p.nsset = set1;
    p.setM = set2;
    p.date = [NSDate date];
    return p;
}
- (IBAction)insertAction:(id)sender {
    People* p = [self people];
    [p bg_save];
}

- (IBAction)deleteAction:(id)sender{
    [People bg_deleteWhere:@[@"ID",@"=",@(1)]];
}

- (IBAction)updateAction:(id)sender {
    People* p = [self people];
    [p bg_updateWhere:@[@"ID",@"=",@(1)]];
}

- (IBAction)registerChangeAction:(id)sender{
    [People bg_registerChangeWithName:@"insert" block:^(bg_changeState result) {
        switch (result) {
            case bg_insert:
                NSLog(@"有数据插入");
                break;
            case bg_update:
                NSLog(@"有数据更新");
                break;
            case bg_delete:
                NSLog(@"有数据删删除");
                break;
            case bg_drop:
                NSLog(@"有表删除");
                break;
            default:
                break;
        }
    }];
}

- (IBAction)removeChangeAction:(id)sender{
    [People bg_removeChangeWithName:@"insert"];
}

- (IBAction)stockAction:(id)sender {
    stockController* con = [stockController new];
    [self presentViewController:con animated:YES completion:nil];
}

- (IBAction)dictToModelAction:(id)sender{
    dictToModelController* con = [dictToModelController new];
    [self presentViewController:con animated:YES completion:nil];
}
@end
