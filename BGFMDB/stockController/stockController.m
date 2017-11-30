//
//  stockController.m
//  BGFMDB
//
//  Created by huangzhibiao on 17/3/9.
//  Copyright © 2017年 Biao. All rights reserved.
//

#import "stockController.h"
#import "stockModel.h"

@interface stockController ()

@property(nonatomic,strong)NSNumber* shenData;
@property(nonatomic,strong)NSNumber* huData;
@property(nonatomic,strong)NSNumber* chuangData;

@property(nonatomic,strong)stockModel* shenStock;
@property(nonatomic,strong)stockModel* huStock;
@property(nonatomic,strong)stockModel* chuangStock;

@property (weak, nonatomic) IBOutlet UILabel *shenLab;
@property (weak, nonatomic) IBOutlet UILabel *huLab;
@property (weak, nonatomic) IBOutlet UILabel *chuangLab;

@property(nonatomic,assign)BOOL updateFlag;//停止循环更新标志;
- (IBAction)backAction:(id)sender;

@end

@implementation stockController

-(void)dealloc{
    //移除数据变化监听.
    [stockModel bg_removeChangeForTableName:nil identify:@"stock"];
    //恢复默认值.
    bg_setDisableCloseDB(NO);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //设置操作过程中不可关闭数据库(即closeDB函数无效),防止数据更新的时候频繁关闭开启数据库.
    bg_setDisableCloseDB(YES);
    //注册数据变化监听.
    [self registerChange];
    
    //深市数据初始
    _shenData = @(10427.24);
    stockModel* shenStock = [stockModel stockWithName:@"深市" stockData:_shenData];
    _shenStock = shenStock;
    [shenStock bg_saveOrUpdate];
    //沪市数据初始
    _huData = @(3013.56);
    stockModel* huStock = [stockModel stockWithName:@"沪市" stockData:_huData];
    _huStock = huStock;
    [huStock bg_saveOrUpdate];
    //创业板数据初始
    _chuangData = @(1954.91);
    stockModel* chuangStock = [stockModel stockWithName:@"创业版" stockData:_chuangData];
    _chuangStock = chuangStock;
    [chuangStock bg_saveOrUpdate];
    
    _updateFlag = YES;//设置循环更新标志.
    [self performSelector:@selector(updateData) withObject:nil afterDelay:1.0];
}

-(void)updateData{
    //更新深市数据
    _shenData = [NSNumber numberWithFloat:(float)(rand()%300) + 10427.24];
    _shenStock.stockData = _shenData;
    NSString* where1 = [NSString stringWithFormat:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"深市")];
    [_shenStock bg_updateWhere:where1];
    //更新沪市数据
    _huData = [NSNumber numberWithFloat:(float)(rand()%200) + 3013.56];
    _huStock.stockData = _huData;
    NSString* where2 = [NSString stringWithFormat:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"沪市")];
    [_huStock bg_updateWhere:where2];
    //更新创业板数据
    _chuangData = [NSNumber numberWithFloat:(float)(rand()%500) + 1954.91];
    _chuangStock.stockData = _chuangData;
    NSString* where3 = [NSString stringWithFormat:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"创业版")];
    [_chuangStock bg_updateWhere:where3];
    
    !_updateFlag?:[self performSelector:@selector(updateData) withObject:nil afterDelay:1.0];
}

//注册数据变化监听.
-(void)registerChange{
    //注册数据变化监听.
    __weak typeof(self) BGSelf = self;
    [stockModel bg_registerChangeForTableName:nil identify:@"stock" block:^(bg_changeState result) {
        NSLog(@"当前线程 = %@",[NSThread currentThread]);
        if ((result==bg_insert) || (result==bg_update)){
            //读取深市数据.
            NSString* where1 = [NSString stringWithFormat:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"深市")];
            stockModel* shen = [stockModel bg_find:nil where:where1].lastObject;
            BGSelf.shenLab.text = shen.stockData.stringValue;
            //读取沪市数据.
            NSString* where2 = [NSString stringWithFormat:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"沪市")];
            stockModel* hu = [stockModel bg_find:nil where:where2].lastObject;
            BGSelf.huLab.text = hu.stockData.stringValue;
            //读取创业版数据.
            NSString* where3 = [NSString stringWithFormat:@"where %@=%@",bg_sqlKey(@"name"),bg_sqlValue(@"创业版")];
            stockModel* chuang = [stockModel bg_find:nil where:where3].lastObject;
            BGSelf.chuangLab.text = chuang.stockData.stringValue;
        }
    }];
}

- (IBAction)backAction:(id)sender {
    _updateFlag = NO;//停止更新操作.
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
