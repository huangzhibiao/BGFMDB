# BGFMDB让数据的增删改查分别只需要一行代码即可,就是这么简单任性.
## 最新重大更新:   
1.增加了自定义“联合主键”的功能.       
2.进行了大重构，优化缩减API，支持多个'唯一约束'，ignoredKeys放到模型类.m文件实现bg_ignoreKeys类函数即可，增加自定义表名功能.       
## Swift工程中使用方式    
目前可以存储Swift工程中的OC类model,在桥接文件导入OC类model的头文件即可, 但是不能解析存储Swift类model,后面会补上Swift类model解析部分😊.    
## 小伙伴们的使用反馈   
![BGFMDB](http://o7pq80nc2.bkt.clouddn.com/showUse_meitu.jpg "小伙伴们的使用反馈")
## 交流QQ群:         
使用交流QQ群: 572359447    
如果在使用过程中发现什么问题或有什么疑问,请加群反馈.    
## 完美支持:    
int,long,signed,float,double,NSInteger,CGFloat,BOOL,NSString,NSMutableString,NSMutableAttributedString,NSAttributedString,NSNumber,NSArray,NSMutableArray,NSDictionary,NSMutableDictionary,NSMapTable,NSHashTable,NSData,NSMutableData,UIImage,NSDate,NSURL,NSRange,CGRect,CGSize,CGPoint,自定义对象 等的存储.   
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
### 而最重要的是: JRDB,LKDBHelper都不支持同一数组中存储不同类型的自定义类型数据,BGFMDB则完美支持,JRDB,LKDBHelper已经成为过去,现在是BGFMDB的时代,作者的宣言是：“要把BGFMDB写成不会写代码的人都会用的库”，欢迎大家反馈和吐槽问题,骚年作者等着你们.
## 综合上述原因后,我决定写一款适合国内初中级开发者使用的存储封装库(BGFMDB),不管是从使用步骤还是支持的存储类型上,都比JRDB,LKDB简单好用和全面.    
## 本库几乎支持存储ios所有基本的自带数据类型.    
## 使用介绍(喜欢的话别忘了给本库一个Star😊).   
## 想加密数据库的,请借鉴此demo:![SQLCipherDemo](https://github.com/huangzhibiao/SQLCipherDemo)     
## CocoaPods的方式.
### Podfile
```Podfile
platform :ios, '8.0'

target '工程名称' do
pod 'BGFMDB', '~> 2.0.9'
end
```
## 直接下载库代码使用方式.
### 添加所需依赖库   
libsqlite3   
### 导入头文件   
```Objective-C
/**
只要在自己的类中导入了BGFMDB.h这个头文件,本类就具有了存储功能.
*/
#import <Foundation/Foundation.h>
#import "BGFMDB.h"
@interface stockModel : NSObject
@property(nonatomic,copy)NSString* name;
@property(nonatomic,strong)NSNumber* stockData;
+(instancetype)stockWithName:(NSString*)name stockData:(NSNumber*)stockData;
@end
```
### 主键
```Objective-C
/**
本库自带的自动增长主键.
*/
@property(nonatomic,strong)NSNumber*_Nullable bg_id;

/**
 为了方便开发者，特此加入以下两个字段属性供开发者做参考.(自动记录数据的存入时间和更新时间)
 */
@property(nonatomic,copy)NSString* _Nonnull bg_createTime;//数据创建时间(即存入数据库的时间)
@property(nonatomic,copy)NSString* _Nonnull bg_updateTime;//数据最后那次更新的时间.

/**
 自定义表名
 */
@property(nonatomic,copy)NSString* _Nonnull bg_tableName;
```
### 联合主键
```Objective-C
/**
 自定义“联合主键” ,这里指定 name和age 为“联合主键”.
 */
+(NSArray *)bg_unionPrimaryKeys{
    return @[@"name",@"age"];
}
```
### 唯一约束
```Objective-C
/**
 如果需要指定“唯一约束”字段, 在模型.m文件中实现该函数,这里指定 name和age 为“唯一约束”.
 */
+(NSArray *)bg_uniqueKeys{
    return @[@"name",@"age"];
}
```
### 设置不需要存储的属性
```Objective-C
/**
 设置不需要存储的属性, 在模型.m文件中实现该函数.
 */
+(NSArray *)bg_ignoreKeys{
   return @[@"eye",@"sex",@"num"];
}
```
### 初始化对象
```Objective-C
People* p = [self people];
```
### 存储
```Objective-C
/**
同步存储.
*/
[p bg_save];

/**
异步存储.
*/
[p bg_saveAsync:^(BOOL isSuccess) {
       //you code
   }];
   
/**
覆盖掉原来People类的所有数据,只存储当前对象的数据.
*/
[p bg_cover];

/**
 同步存储或更新.
 当"唯一约束"或"主键"存在时，此接口会更新旧数据,没有则存储新数据.
 提示：“唯一约束”优先级高于"主键".
 */
 [p bg_saveOrUpdate];
 
/**
同步 存储或更新 数组元素.
当"唯一约束"或"主键"存在时，此接口会更新旧数据,没有则存储新数据.
提示：“唯一约束”优先级高于"主键".
*/
[People bg_saveOrUpdateArray:@[p,p1,p2]];
```
### 查询
```Objective-C
/**
同步查询所有数据.
*/
NSArray* finfAlls = [People bg_findAll:bg_tablename];

/**
按条件查询.
*/
NSString* where = [NSString stringWithFormat:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"斯巴达")];
NSArray* arr = [People bg_find:bg_tablename where:where];

/**
 直接写SQL语句操作.
 */
NSArray* arr = bg_executeSql(@"select * from yy", bg_tablename, [People class]);//查询时,后面两个参数必须要传入.

/**
 根据范围查询.
*/
NSArray* arr = [People bg_find:bg_tablename range:NSMakeRange(i,50) orderBy:nil desc:NO];
```
### 更新
```Objective-C
/**
 单个对象更新.
 支持keyPath.
 */
 NSString* where = [NSString stringWithFormat:@"where %@ or %@=%@",bg_keyPathValues(@[@"user.student.human.body",bg_equal,@"小芳"]),bg_sqlKey(@"age"),bg_sqlValue(@(31))];
  [p bg_updateWhere:where];
  
/**
 sql语句批量更新.
 */
  NSString* where = [NSString stringWithFormat:@"set %@=%@ where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"马化腾"),bg_sqlKey(@"name"),bg_sqlValue(@"天朝")];
  [People bg_update:bg_tablename where:where];  
  
/**
 直接写SQL语句操作
 */
bg_executeSql(@"update yy set BG_name='标哥'", nil, nil);//更新或删除等操作时,后两个参数不必传入.
```
### 删除
```Objective-C
/**
 按条件删除.
 */
NSString* where = [NSString stringWithFormat:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"斯巴达")];
[People bg_delete:bg_tablename where:where];

/**
清除表的所有数据.
*/
[People bg_clear:bg_tablename];

/**
删除数据库表.
*/
[People bg_drop:bg_tablename];

```
### 获取类数据库版本
```Objective-C
/**
 获取该类的数据库版本号;
*/
NSInteger version = [People bg_version:bg_tablename];
```
### 类数据库版本手动升级(当'唯一约束','联合主键','属性类型改变',发生改变时需要手动调用升级,其他情况库自动检测升级)
```Objective-C
//注: 版本号从1开始,依次往后递增,本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
/**
 如果类'唯一约束','联合主键','属性类型'发生改变.
 则调用此API刷新该类数据库,不需要新旧映射的情况下使用此API.
*/
[People bg_update:bg_tablename version:version];

/**
如果类'唯一约束','联合主键','属性类型'发生改变.
则调用此API刷新该类数据库.data2是新变量名,data是旧变量名,即将旧的值映射到新的变量名,其他不变的变量名会自动复制,只管写出变化的对应映射即可.
*/
[People bg_update:bg_tablename version:version keyDict:@{@"data2":@"data"}];
```
### 事务操作
```Objective-C
/**
事务操作,返回YES提交事务,返回NO则回滚事务.
*/
bg_inTransaction(^BOOL{
        [p bg_save];//存储
        return NO;
    });
```
### 快速查询数据条数
```Objective-C
/**
按条件查询表中所有数据的条数.
*/
NSInteger count = [People bg_count:bg_tablename where:nil];
```
### 类数据之间的拷贝
```Objective-C
/**
 将People表的数据拷贝给bg_tablename表, name拷贝给Man的Man_name，其他同理.
 */
 [People bg_copy:nil toTable:bg_tablename keyDict:@{@"name":@"Man_name",
                                                       @"num":@"Man_num",
                                                       @"age":@"Man_age",
                                                       @"image":@"image"} append:NO];
```
### 直接存取数组
```Objective-C
NSMutableArray* testA = [NSMutableArray array];
    [testA addObject:@"我是"];
    [testA addObject:@(10)];
    [testA addObject:@(9.999)];
    [testA addObject:@{@"key":@"value"}];
    /**
     存储标识名为testA的数组.
     */
    [testA bg_saveArrayWithName:@"testA"];
    
    /**
     往标识名为@"testA"的数组中添加元素.
     */
    [NSArray bg_addObjectWithName:@"testA" object:@[@(1),@"哈哈"]];
    
    /**
     删除标识名为testA的数组某个位置上的元素.
     */
    [NSArray bg_deleteObjectWithName:@"testA" Index:3];
    
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
    [NSArray bg_clearArrayWithName:@"testA"];
```
### 直接存取字典
```Objective-C
NSDictionary* dict = @{@"one":@(1),@"key":@"value",@"array":@[@(1.2),@"哈哈"]};
    /**
     存储字典.
     */
    [dict bg_saveDictionary];
    
    /**
     添加字典元素.
     */
    [NSDictionary bg_setValue:@"标哥" forKey:@"name"];
    
    /**
     获取某个字典元素.
     */
    id num = [NSDictionary bg_valueForKey:@"one"];
    
    /**
     移除字典某个元素.
     */
    [NSDictionary bg_removeValueForKey:@"key"];
    
    /**
     遍历字典元素.
     */
    [NSDictionary bg_enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull value, BOOL *stop) {
        NSLog(@"key = %@ , value = %@",key,value);
    }];
    
    /**
     清空字典.
     */
    [NSDictionary bg_clearDictionary];
```
### 注册数据变化监听
```Objective-C
/**
注册监听bg_tablename表的数据变化，唯一识别标识是@"change".  
*/
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
```
### 移除数据监听
```Objective-C
/**
移除bg_tablename表数据变化的监听，唯一识别标识是@"change".  
*/
 [People bg_removeChangeForTableName:bg_tablename identify:@"change"];
```
### 字典转模型
```Objective-C
NSDictionary* dictAni = [self getDogDict];
/**
一代码搞定字典转模型.
*/
Dog* dog = [Dog bg_objectWithKeyValues:dictAni];

NSDictionary* dictMy = [self getMyDict];
/**
一代码搞定字典转模型.
*/
My* my = [My bg_objectWithDictionary:dictMy];
```
### 模型转字典
```Objective-C
/**
一句代码搞定模型转字典.
*/
 NSDictionary* dictBodyAll = [body bg_keyValuesIgnoredKeys:nil];
 
/**
忽略掉hand这个变量不转.
*/
NSDictionary* dictBody = [body bg_keyValuesIgnoredKeys:@[@"hand"]];
```
### 如果模型中的数组变量存储的是自定义类,则需要实现下面的这个函数:
```Objective-C
/**
如果模型中有数组且存放的是自定义的类(NSString等系统自带的类型就不必要了),那就实现该函数,key是数组名称,value是自定的类Class,用法跟MJExtension一样.
(‘字典转模型’ 或 ’模型转字典‘ 都需要实现该函数)
*/
+(NSDictionary *)bg_objectClassInArray{
    return @{@"dogs":[Dog class],@"bodys":[Body class]};
}

/**
 如果模型中有自定义类变量,则实现该函数对应进行集合到模型的转换.
 将json数据中body这个key对应的值转化为Body类变量body对象.
 */
+(NSDictionary *)bg_objectClassForCustom{
    return @{@"body":[Body class]};
}

/**
 替换变量的功能(及当字典的key和属性名不一样时，进行映射对应起来)
 即将字典里key为descri的值 赋给 属性名为intro的变量,性别和sex同理.
 */
+(NSDictionary *)bg_replacedKeyFromPropertyName{
    return @{@"descri":@"intro",@"性别":@"sex"};
}
```
### 更多功能请下载demo运行了解使用.   
