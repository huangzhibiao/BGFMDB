# BGFMDB算法全新震撼升级.  
作者联系方式:       
QQ: 450426721   
QQ邮箱: 450426721@qq.com   
使用交流QQ群: 572359447    
如果在使用过程中发现什么问题或有什么疑问,请加我QQ反馈.    
## 完美支持:    
int,long,signed,float,double,NSInteger,CGFloat,BOOL,NSString,NSMutableString,NSNumber,NSArray,NSMutableArray,NSDictionary,NSMutableDictionary,NSMapTable,NSHashTable,NSData,NSMutableData,UIImage,NSDate,NSURL,NSRange,CGRect,CGSize,CGPoint,自定义对象 等的存储.   
## 写本库的动机: 在对coredata和realm做了探究总结后,发现了很多有缺陷的地方,最明显的就是下面的原因:   
### realm缺陷: 
Realm不支持集合类型,这一点也是比较蛋疼。   
Realm支持以下的属性类型：BOOL、bool、int、NSInteger、long、long long、float、double、NSString、NSDate、NSData以及 被特殊类型标记的NSNumber。CGFloat属性的支持被取消了，因为它不具备平台独立性。    
这里就是不支持集合，比如说NSArray，NSMutableArray，NSDictionary，NSMutableDictionary，NSSet，NSMutableSet。如果服务器传来的一个字典，key是一个字符串，对应的value就是一个数组，这时候就想存储这个数组就比较困难了。   
### coredata缺陷:   
coredata虽然通过Transformable可以存取集合类型,但需要开发者去进行转换处理,使用起来不方便直观,虽然coredata有很多好用的封装库,像ResKit,MMRecord等,但这些库比较庞大,而且都是英文介绍,不利于国内初中级开发的快速开发使用.    
## 虽然国内也已经有了对FMDB面相对象层的封装,比如像JRDB,LKDBHelper等,但是在使用总结后还是发现不少的问题,问题如下:    
JRDB存储数组需要传入对象的泛型,同时还要复写一些函数和映射，这对于初中级开发者是很不利的,看的很萌逼.    
LKDBHelper好一点,但也要复写不少的函数,而且LKDBHelper的使用demo有点乱,还有就是不支持NSMaptable,NSHashTable的存储,LKDBHelper还有一个致命的弱点就是当类变量名称跟sqlite的关键字一样时,会发生冲突错误！       
## 综合上述原因后,我决定写一款适合国内初中级开发者使用的存储封装库(BGFMDB),不管是从使用步骤还是支持的存储类型上,都比JRDB,LKDB简单好用和全面.    
## 本库几乎支持存储ios所有基本的自带数据类型.     
## 使用介绍(喜欢的话别忘了给本库一个Star😊). 
### 添加所需依赖库   
libsqlite3   
### 导入头文件   
```Objective-C
/**
只要在自己的类中导入了NSObject+BGModel.h这个头文件,本类就具有了存储功能.
*/
#import <Foundation/Foundation.h>
#import "NSObject+BGModel.h"
@interface stockModel : NSObject
@property(nonatomic,copy)NSString* name;
@property(nonatomic,strong)NSNumber* stockData;
+(instancetype)stockWithName:(NSString*)name stockData:(NSNumber*)stockData;
@end
```
### 初始化对象
```Objective-C
People* p = [self people];
```
### 存储
```Objective-C
//同步存储.
[p save];
//异步存储.
[p saveAsync:^(BOOL isSuccess) {
       //you code
   }];
//覆盖掉原来People类的所有数据,只存储当前对象的数据.
[p cover];
```
### 查询
```Objective-C
//同步查询所有People的数据.
NSArray* finfAlls = [People findAll];
//异步查询所有People的数据.
[People findAllAsync:^(NSArray * _Nullable array) {
        // you code
    }];
//异步查询People类的数据,查询限制3条,通过age降序排列.
[People findAllAsyncWithLimit:3 orderBy:@"age" desc:YES complete:^(NSArray * _Nullable array) {
    for(People* p in array){
      // you code
    }
}];
//异步查询People类的数据,查询范围从第10处开始的后面5条,不排序.
[People findAllAsyncWithRange:NSMakeRange(10,5) orderBy:nil desc:NO complete:^(NSArray * _Nullable array) {
     for(People* p in array){
        // you code
     }
}];

//查询name等于爸爸和age等于45,或者name等于马哥的数据.  此接口是为了方便开发者自由扩展更深层次的查询条件逻辑.
NSArray* arrayConds1 = [People findFormatSqlConditions:@"where %@=%@ and %@=%@ or %@=%@",sqlKey(@"age"),sqlValue(@(45)),sqlKey(@"name"),sqlValue(@"爸爸"),sqlKey(@"name"),sqlValue(@"马哥")];
//查询user.student.human.body等于小芳 和 user1.name中包含fuck这个字符串的数据.
NSArray* arrayConds2 = [People findFormatSqlConditions:@"where %@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳",@"user1.name",Contains,@"fuck"])];
//查询user.student.human.body等于小芳,user1.name中包含fuck这个字符串 和 name等于爸爸的数据.
NSArray* arrayConds3 = [People findFormatSqlConditions:@"where %@ and %@=%@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳",@"user1.name",Contains,@"fuck"]),sqlKey(@"name"),sqlValue(@"爸爸")];
```
### 更新
```Objective-C
//将People类数据中name=@"标哥"，num=220.88的数据更新为当前对象的数据.
[p updateWhere:@[@"name",@"=",@"标哥",@"num",@"=",@(220.88)]];

//将People类中name等于"马云爸爸"的数据的name设为"马化腾",此接口是为了方便开发者自由扩展更深层次的查询条件逻辑.
[People updateFormatSqlConditions:@"set %@=%@ where %@=%@",sqlKey(@"name"),sqlValue(@"马化腾"),sqlKey(@"name"),sqlValue(@"马云爸爸")];
// 将People类数据中name等于"马化腾"的数据更新为当前对象的数据.
[p updateFormatSqlConditions:@"where %@=%@",sqlKey(@"name"),sqlValue(@"爸爸")];
```
### 删除
```Objective-C
//同步删除People类数据中name=@"标哥"，num=220.88的数据.
[People deleteWhere:@[@"name",@"=",@"标哥",@"num",@"=",@(220.88)]];
//异步删除People类数据中name=@"标哥"，num=220.88的数据.
[People deleteAsync:@[@"name",@"=",@"标哥",@"num",@"=",@(220.88)] complete:^(BOOL isSuccess) {
      // you code  
}];
//清除People表的所有数据.
[People clear];
//删除People的数据库表.
[People drop];

//删除People类中name等于"美国队长"的数据,此接口是为了方便开发者自由扩展更深层次的查询条件逻辑.
[People deleteFormatSqlConditions:@"where %@=%@",sqlKey(@"name"),sqlValue(@"美国队长")];
//删除People类中user.student.human.body等于"小芳"的数据
[People deleteFormatSqlConditions:@"where %@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];
//删除People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据
//[People deleteFormatSqlConditions:@"where %@=%@ and %@",sqlKey(@"name"),sqlValue(@"美国队长"),keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];
```
### keyPath(类嵌套的时候使用)   
```Objective-C
@interface Human : NSObject
@property(nonatomic,copy)NSString* sex;
@end

@interface Student : NSObject
@property(nonatomic,strong)Human* human;
@end

@interface User : NSObject
@property(nonatomic,strong)Student* student;
@end

@interface People : NSObject
@property(nonatomic,strong)User* user1;
@property(nonatomic,strong)User* user2;
@end

//查询People类中user2.student.human.sex中等于@“女”的数据
[People findForKeyPathAndValues:@[@"user2.student.human.sex",Equal,@"女"]];

//将People类中user1.name包含@“小明”字符串 和 user2.student.human.sex中等于@“女”的数据 更新为当前对象的数据.
[p updateForKeyPathAndValues:@[@"user1.name",Contains,@"小明",@"user2.student.human.sex",Equal,@"女"]];
 
//删除People类中user1.name包含@“小明”字符串的数据.
[People deleteForKeyPathAndValues:@[@"user1.name",Contains,@"小明"]];
```
### 基本的使用
```Objective-C
stockModel* shenStock = [stockModel stockWithName:@"深市" stockData:_shenData];   
[shenStock save];//一句代码搞定存储.   
[shenStock updateWhere:@[@"name",@"=",@"深市"]];//一句代码搞定更新.   
NSArray* array = [stockModel findAll];//一句代码搞定查询.   
[stockModel deleteWhere:@[@"name",@"=",@"深市"]];//一句代码搞定删.  
//注册数据变化监听.  
[stockModel registerChangeWithName:@"stockModel" block:^(changeState result){  
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
  //移除数据变化监听.  
 [stockModel removeChangeWithName:@"stockModel"]; 
 
 //更多功能请下载demo使用了解.
```   
### 主键
```Objective-C
@property(nonatomic,strong)NSNumber*_Nullable ID;//本库自带的自动增长主键.
```
### 唯一约束
```Objective-C
//如果需要指定“唯一约束”字段,就复写该函数,这里指定 name 为“唯一约束”.
-(NSString *)uniqueKey{
    return @"name";
}
```
### 更多功能请下载demo运行了解使用.   
## 以下是API介绍,一看就懂,马马上手使用.
//同步：线程阻塞；异步：线程非阻塞;   
/**   
 设置调试模式   
 @debug YES:打印SQL语句, NO:不打印SQL语句.   
 */   
+(void)setDebug:(BOOL)debug;   
/**   
 自定义 “唯一约束” 函数,如果需要 “唯一约束”字段,则在自定类中自己实现该函数.   
 @return 返回值是 “唯一约束” 的字段名(即相对应的变量名).   
 */   
-(NSString* _Nonnull)uniqueKey;   
/**   
 判断这个类的数据表是否已经存在.   
 */   
+(BOOL)isExist;   
/**   
 同步存储.   
 */   
-(BOOL)save;   
/**   
 异步存储.   
 */   
-(void)saveAsync:(Complete_B)complete;   
/**   
 同步覆盖存储.   
 覆盖掉原来的数据,只存储当前的数据.   
 */   
-(BOOL)cover;   
/**   
 异步覆盖存储   
 覆盖掉原来的数据,只存储当前的数据.   
 */   
-(void)coverAsync:(Complete_B)complete;   
/**   
 同步查询所有结果.   
 */   
+(NSArray* _Nullable)findAll;   
/**   
 异步查询所有结果   
 */   
+(void)findAllAsync:(Complete_A)complete;   
/**   
 同步查询所有结果.   
 @limit 每次查询限制的条数,0则无限制.   
 @desc YES:降序，NO:升序.   
 */
+(NSArray* _Nullable)findAllWithLimit:(NSInteger)limit orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc;   
/**   
 异步查询所有结果.   
 @limit 每次查询限制的条数,0则无限制.   
 @desc YES:降序，NO:升序.   
 */   
+(void)findAllAsyncWithLimit:(NSInteger)limit orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc complete: (Complete_A)complete;   
/**   
 同步查询所有结果.   
 @range 查询的范围(从location开始的后面length条).   
 @desc YES:降序，NO:升序.   
 */   
+(NSArray* _Nullable)findAllWithRange:(NSRange)range orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc;   
/**   
 异步查询所有结果.   
 @range 查询的范围(从location开始的后面length条).   
 @desc YES:降序，NO:升序.   
 */   
+(void)findAllAsyncWithRange:(NSRange)range orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc complete:(Complete_A)complete;   
/**   
 同步条件查询所有结果.   
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即查询name=标哥,age=>25的数据;   
 可以为nil,为nil时查询所有数据;   
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath查询接口).   
 */   
+(NSArray* _Nullable)findWhere:(NSArray* _Nullable)where;   
/**   
 异步条件查询所有结果.   
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即查询name=标哥,age=>25的数据;   
 可以为nil,为nil时查询所有数据;   
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath查询接口).   
 */   
+(void)findAsyncWhere:(NSArray* _Nullable)where complete:(Complete_A)complete;   
/**   
 keyPath查询   
 同步查询所有keyPath条件结果.   
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]   
 即查询user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.   
 */    
+(NSArray* _Nullable)findForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues;   
/**   
 keyPath查询   
 异步查询所有keyPath条件结果.   
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]   
 即查询user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.   
 */   
+(void)findAsyncForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_A)complete;   
/**   
 同步更新数据.   
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即更新name=标哥,age=>25的数据;   
 可以为nil,nil时更新所有数据;   
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持.   
 */   
-(BOOL)updateWhere:(NSArray* _Nullable)where;   
/**   
 异步更新.   
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即更新name=标哥,age=>25的数据;   
 可以为nil,nil时更新所有数据;   
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持.   
 */   
-(void)updateAsync:(NSArray* _Nullable)where complete:(Complete_B)complete;   
/**   
 根据keypath更新数据.   
 同步更新.   
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]   
 即更新user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.   
 */   
-(BOOL)updateForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues;   
/**   
 根据keypath更新数据.   
 异步更新.   
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]   
 即更新user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.   
 */   
-(void)updateAsyncForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_B)complete;   
/**   
 同步删除数据.   
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即删除name=标哥,age=>25的数据.   
 不可以为nil;   
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持   
 */   
+(BOOL)deleteWhere:(NSArray* _Nonnull)where;   
/**   
 异步删除.   
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即删除name=标哥,age=>25的数据.   
 不可以为nil;   
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持   
 */   
+(void)deleteAsync:(NSArray* _Nonnull)where complete:(Complete_B)complete;   
/**   
 根据keypath删除数据.   
 同步删除.   
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]   
 即删除user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.   
 */   
+(BOOL)deleteForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues;   
/**   
 根据keypath删除数据.   
 异步删除.   
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]   
 即删除user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象.   
 */   
+(void)deleteAsyncForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues complete:(Complete_B)complete;   
/**   
 同步清除所有数据   
 */   
+(BOOL)clear;   
/**   
 异步清除所有数据.   
 */   
+(void)clearAsync:(Complete_B)complete;   
/**   
 同步删除这个类的数据表   
 */   
+(BOOL)drop;   
/**   
 异步删除这个类的数据表.   
 */   
+(void)dropAsync:(Complete_B)complete;   
/**   
 查询该表中有多少条数据   
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即name=标哥,age=>25的数据有多少条,为nil时返回全部数据的条数.   
 不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持(有专门的keyPath查询条数接口).   
 */   
+(NSInteger)countWhere:(NSArray* _Nullable)where;   
/**   
 keyPath查询该表中有多少条数据   
 @keyPathValues数组,形式@[@"user.student.name",Equal,@"小芳",@"user.student.conten",Contains,@"书"]   
 即查询user.student.name=@"小芳" 和 user.student.content中包含@“书”这个字符串的对象的条数.   
 */   
+(NSInteger)countForKeyPathAndValues:(NSArray* _Nonnull)keyPathValues;   
/**   
 获取本类数据表当前版本号.   
 */   
+(NSInteger)version;   
/**   
 刷新,当类变量名称或"唯一约束"改变时,调用此接口刷新一下.   
 同步刷新.   
 @version 版本号,从1开始,依次往后递增.   
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.   
 */   
+(dealState)updateVersion:(NSInteger)version;   
/**   
 刷新,当类变量名称或"唯一约束"改变时,调用此接口刷新一下.   
 异步刷新.   
 @version 版本号,从1开始,依次往后递增.   
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.   
 */   
+(void)updateVersionAsync:(NSInteger)version complete:(Complete_I)complete;   
/**   
 刷新,当类变量名称或"唯一约束"改变时,调用此接口刷新一下.   
 同步刷新.   
 @version 版本号,从1开始,依次往后递增.   
 @keyDict 拷贝的对应key集合,形式@{@"新Key1":@"旧Key1",@"新Key2":@"旧Key2"},即将本类以前的变量 “旧Key1” 的数据拷贝给现在本类的变量“新Key1”，其他依此推类.   
 (特别提示: 这里只要写那些改变了的变量名就可以了,没有改变的不要写)，比如A以前有3个变量,分别为a,b,c；现在变成了a,b,d；那只要写@{@"d":@"c"}就可以了，即只写变化了的变量名映射集合.   
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.   
 */
+(dealState)updateVersion:(NSInteger)version keyDict:(NSDictionary* const _Nonnull)keydict;   
/**   
 刷新,当类变量名称或"唯一约束"改变时,调用此接口刷新一下.   
 异步刷新.   
 @version 版本号,从1开始,依次往后递增.   
 @keyDict 拷贝的对应key集合,形式@{@"新Key1":@"旧Key1",@"新Key2":@"旧Key2"},即将本类以前的变量 “旧Key1” 的数据拷贝给现在本类的变量“新Key1”，其他依此推类.   
 (特别提示: 这里只要写那些改变了的变量名就可以了,没有改变的不要写)，比如A以前有3个变量,分别为a,b,c；现在变成了a,b,d；那只要写@{@"d":@"c"}就可以了，即只写变化了的变量名映射集合.   
 说明: 本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.   
 */
+(void)updateVersion:(NSInteger)version keyDict:(NSDictionary* const _Nonnull)keydict complete:(Complete_I)complete;   
/**   
 将某表的数据拷贝给另一个表   
 同步复制.   
 @destCla 目标类.   
 @keyDict 拷贝的对应key集合,形式@{@"srcKey1":@"destKey1",@"srcKey2":@"destKey2"},即将源类srcCla中的变量值拷贝给目标类destCla中的变量destKey1，srcKey2和destKey2同理对应,依此推类.    
 @append YES: 不会覆盖destCla的原数据,在其末尾继续添加；NO: 覆盖掉destCla原数据,即将原数据删掉,然后将新数据拷贝过来.   
 */   
+(dealState)copyToClass:(__unsafe_unretained _Nonnull Class)destCla keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append;   
/**   
 将某表的数据拷贝给另一个表   
 异步复制.   
 @destCla 目标类.   
 @keyDict 拷贝的对应key集合,形式@{@"srcKey1":@"destKey1",@"srcKey2":@"destKey2"},即将源类srcCla中的变量值拷贝给目标类destCla中的变量destKey1，srcKey2和destKey2同理对应,依此推类.   
 @append YES: 不会覆盖destCla的原数据,在其末尾继续添加；NO: 覆盖掉destCla原数据,即将原数据删掉,然后将新数据拷贝过来.   
 */   
+(void)copyAsyncToClass:(__unsafe_unretained _Nonnull Class)destCla keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append complete:(Complete_I)complete;   
/**   
 事务操作.   
 @return 返回YES提交事务, 返回NO回滚事务.   
 */    
+(void)inTransaction:(BOOL (^_Nonnull)())block;   
/**   
 注册数据变化监听.   
 @name 注册名称,此字符串唯一,不可重复,移除监听的时候使用此字符串移除.   
 @return YES: 注册监听成功; NO: 注册监听失败.   
 */   
+(BOOL)registerChangeWithName:(NSString* const _Nonnull)name block:(ChangeBlock)block;   
/**   
 移除数据变化监听.   
 @name 注册监听的时候使用的名称.   
 @return YES: 移除监听成功; NO: 移除监听失败.   
 */   
+(BOOL)removeChangeWithName:(NSString* const _Nonnull)name;   
