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

#define bg_tablename @"yy"

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

- (IBAction)multithreadTestAction:(id)sender;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    /**
     想测试更多功能,打开注释掉的代码即可.
     */
    bg_setDebug(YES);//打开调试模式,打印输出调试信息.
    
    /**
     如果频繁操作数据库时,建议进行此设置(即在操作过程不关闭数据库).
     */
    //bg_setDisableCloseDB(YES);
    
    /**
     手动关闭数据库(如果设置了bg_setDisableCloseDB(YES)，则在切换bg_setSqliteName前，需要手动关闭数据库一下).
     */
    //bg_closeDB();
    
    /**
     自定义数据库名称，否则默认为BGFMDB
     */
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
    p.bg_tableName = bg_tablename;//自定义数据库表名称(库自带的字段).
    /**
     存储.
     */
     [p bg_save];
    
    /**
     同步存储或更新.
     当"唯一约束"或"主键"存在时，此接口会更新旧数据,没有则存储新数据.
     */
     //[p bg_saveOrUpdate];
    
    /**
     同步 存储或更新 数组元素.
     当"唯一约束"或"主键"存在时，此接口会更新旧数据,没有则存储新数据.
     提示：“唯一约束”优先级高于"主键".
     */
    //    p.bg_id = @(1);
    //    People* p1 = [self people];
    //    p1.bg_tableName = bg_tablename;//自定义数据库表名称(库自带的字段).
    //    p1.bg_id = @(2);
    //    p1.age = 66611;
    //    p1.name = @"琪瑶11";
    //    People* p2 = [self people];
    //    p2.bg_tableName = bg_tablename;//自定义数据库表名称(库自带的字段).
    //    p2.bg_id = @(3);
    //    p2.age = 88822;
    //    p2.name = @"标哥22";
    //    [People bg_saveOrUpdateArray:@[p,p1,p2]];
    
    /**
     单个对象更新,支持keyPath.
     根据user下的student下的human下的body是否等于小芳 或 age是否等于31 来更新当前对象的数据进入数据库.
     */
    //NSString* where = [NSString stringWithFormat:@"where %@ and %@=%@",bg_keyPathValues(@[@"user.student.num",bg_equal,@"标哥"]),bg_sqlKey(@"age"),bg_sqlValue(@(99))];
    //p.name = @"天朝1";
    //[p bg_updateWhere:where];
    
    /**
     使用SQL语句设置更新.
     根据某个属性值去更改某个属性值，此处是当name等于@"天朝"时,设置age=100.
     */
//    NSString* where = [NSString stringWithFormat:@"set %@=%@ where %@=%@",bg_sqlKey(@"age"),bg_sqlValue(@(100)),bg_sqlKey(@"name"),bg_sqlValue(@"斯巴达")];
//    [People bg_update:bg_tablename where:where];
    
//    NSMutableArray* arrayM = [NSMutableArray array];
//    Human* human = [Human new];
//    human.sex = @"女";
//    human.body = @"小芳";
//    human.humanAge = 26;
//    human.age = 15;
//    human.num = 999;
//    human.counts = 10001;
//    human.food = @"大米";
//    [arrayM addObject:@"111"];
//    [arrayM addObject:@"222"];
//    [arrayM addObject:human];
//    NSString * update = [NSString stringWithFormat:@"set %@=%@ where %@=%@",bg_sqlKey(@"datasM"),bg_sqlValue(arrayM),bg_sqlKey(bg_primaryKey),bg_sqlValue(@(1))];
//    [People bg_update:bg_tablename where:update];
    
    /**
     获取第一个元素.
     */
//    People* firstObj = [People bg_firstObjet:bg_tablename];
    
    /**
     获取最后一个元素.
     */
//    People* lastObj = [People bg_lastObject:bg_tablename];
    
    /**
     获取某一行的元素.
     */
//    People* someObj = [People bg_object:bg_tablename row:3];
    
    /**
     覆盖存储,即清除之前的数据，只存储当前的数据.
     */
//    [p bg_cover];
    
    /**
     按条件查询.
     */
//    NSString* where = [NSString stringWithFormat:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"斯巴达")];
//    NSArray* arr = [People bg_find:bg_tablename where:where];
    
    /**
     按时间段查找数据.
     */
//    NSArray* arr = [People bg_find:bg_tablename type:bg_createTime dateTime:@"2017-11-30"];
    
    /**
     按条件删除.
     */
//    NSString* where = [NSString stringWithFormat:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"斯巴达")];
//    [People bg_delete:bg_tablename where:where];
    
    /**
     直接写SQL语句操作
     */
    //NSArray* arr = bg_executeSql(@"select * from yy", bg_tablename, [People class]);//查询时,后面两个参数必须要传入.
//    bg_executeSql(@"update yy set BG_name='标哥'", nil, nil);//更新或删除等操作时,后两个参数不必传入.
    
    /**
     获取数据表当前版本号.
     */
//    NSInteger version = [People bg_version:bg_tablename];
    /**
     刷新,当类"唯一约束"改变时,调用此接口刷新一下.
     version 版本号,从1开始,依次往后递增.
     说明: 本次更新版本号必须 大于 上次的版本号,否则不会更新.
     */
//    [People bg_update:bg_tablename version:1];
    
    /**
     使用keyPath查询嵌套类信息.
     */
//    NSString* where = [NSString stringWithFormat:@"where %@",bg_keyPathValues(@[@"user.name",bg_equal,@"陈浩"])];
//    NSArray* arrFind = [People bg_find:bg_tablename where:where];
    
    /**
     当数据量巨大时采用分页范围查询.
     */
    NSInteger count = [People bg_count:bg_tablename where:nil];
    for(int i=1;i<=count;i+=50){
        NSArray* arr = [People bg_find:bg_tablename range:NSMakeRange(i,50) orderBy:nil desc:NO];
        for(People* pp in arr){
            //具体数据请断点查看
            //库新增两个自带字段createTime和updateTime方便开发者使用和做参考对比.
            NSLog(@"主键 = %@, 表名 = %@, 创建时间 = %@, 更新时间 = %@",pp.bg_id,pp.bg_tableName,pp.bg_createTime,pp.bg_updateTime);
        }
        
        //顺便取第一个对象数据测试
        if(i==1){
            People* lastP = arr.lastObject;
            _showImage.image = lastP.image;
            _showLab.attributedText = lastP.attriStr;
        }
    }
    
    
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
    p.name = @"斯巴达7";
    p.num = @(220.88);
    p.age = 99;
    p.sex = @"男";
    p.eye = @"末世眼皮111";
    p.Url = [NSURL URLWithString:@"http://www.baidu.com"];
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
    student.num = @"标哥";
    student.names = @[@"小哥哥",@"小红",@(110),@[@"数组元素1",@"数组元素2"],@{@"集合key":@"集合value"}];
    student.count = 199;
    Human* human = [[Human alloc] init];
    human.sex = @"女";
    human.body = @"小芳";
    human.humanAge = 98;
    human.age = 18;
    student.human = human;
    user.student = student;
    p.students = @[@(1),@"呵呵",@[@"数组元素1",@"数组元素2"],@{@"集合key":@"集合value"},student,data,student];
    p.infoDic = @{@"name":@"标哥",@"年龄":@(1),@"数组":@[@"数组1",@"数组2"],@"集合":@{@"集合1":@"集合2"},@"user":user,@"data":data};
    
    NSHashTable* hashTable = [NSHashTable new];
    [hashTable addObject:@"h1"];
    [hashTable addObject:@"h2"];
    [hashTable addObject:student];
    NSMapTable* mapTable = [NSMapTable  new];
    [mapTable setObject:@"m_value1" forKey:@"m_key1"];
    [mapTable setObject:@"m_value2" forKey:@"m_key2"];
    [mapTable setObject:user forKey:@"m_key3"];
    NSSet* set1 = [NSSet setWithObjects:@"1",@"2",student, nil];
    NSMutableSet* set2 = [NSMutableSet set];
    [set2 addObject:@{@"key1":@"value"}];
    [set2 addObject:@{@"key2":user}];
    
    People* userP = [People new];
    userP.name = @"互为属性测试";
    user.userP = userP;
    
    p.user = user;
    p.user1 = [User new];
    p.user1.name = @"小明_fuck2222";
    p.bfloat = 8.88;
    p.bdouble = 100.567;
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
/**
 测试子类对象指向父类引用的情况.
 */
-(void)testT{
    testT* test = [testT new];
    T2* t2 = [T2 new];
    t2.t2 = @"t2";
    t2.name = @"t2_name";
    /*------*/
    T3* t3 = [T3 new];
    t3.t3 = @"t3";
    t3.name = @"t3_name";
    t3.t2 = t2;
    
    test.t1 = t3;
    [test bg_save];
    
    NSArray* arr = [testT bg_findAll:nil];
    
    NSLog(@"-------");
}
/**
 插入
 */
- (IBAction)insertAction:(id)sender {
    People* p = [self people];
    p.bg_tableName = bg_tablename;//自定义的数据库表名称(库自带的字段).
    [p bg_save];
}
/**
 删除
 */
- (IBAction)deleteAction:(id)sender{
    NSString* where = [NSString stringWithFormat:@"where %@=%@",bg_sqlKey(bg_primaryKey),@(1)];
    [People bg_delete:bg_tablename where:where];
}
/**
 更新
 */
- (IBAction)updateAction:(id)sender {
    People* p = [self people];
    p.bg_tableName = bg_tablename;//自定义的数据库表名称(库自带的字段).
    NSString* where = [NSString stringWithFormat:@"where %@=%@",bg_sqlKey(bg_primaryKey),@(1)];
    [p bg_updateWhere:where];
}
/**
 数据库变化监听
 */
- (IBAction)registerChangeAction:(id)sender{
    [People bg_registerChangeForTableName:bg_tablename identify:@"change" block:^(bg_changeState result) {
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

/**
 移除监听
 */
- (IBAction)removeChangeAction:(id)sender{
    [People bg_removeChangeForTableName:bg_tablename identify:@"change"];
}
/**
 模拟股票数据
 */
- (IBAction)stockAction:(id)sender {
    stockController* con = [stockController new];
    [self presentViewController:con animated:YES completion:nil];
}
/**
 字典转模型
 */
- (IBAction)dictToModelAction:(id)sender{
    dictToModelController* con = [dictToModelController new];
    [self presentViewController:con animated:YES completion:nil];
}
/**
 多线程安全测试
 */
- (IBAction)multithreadTestAction:(id)sender {
    People* p = [self people];
    for(int i=0;i<5;i++){
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            NSLog(@"存储...");
            [p bg_save];
        });
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            NSLog(@"更新...");
            NSString* where = [NSString stringWithFormat:@"set %@=%@ where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"标哥"),bg_sqlKey(@"name"),bg_sqlValue(@"斯巴达")];
            [People bg_update:bg_tablename where:where];
        });
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            People* pp = [People bg_lastObject:nil];
            NSLog(@"bg_id = %@",pp.bg_id);
        });
        
    }

}
@end
