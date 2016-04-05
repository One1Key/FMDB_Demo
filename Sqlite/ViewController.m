//
//  ViewController.m
//  Sqlite
//
//  Created by mac book on 16/1/15.
//  Copyright © 2016年 mac book. All rights reserved.
//

#import "ViewController.h"
#import "FMDB.h"
#import "UIImageView+WebCache.h"
#import "Person.h"

@interface ViewController ()
@property (nonatomic, strong) FMDatabase *fmdb;
@property (nonatomic, strong) FMDatabaseQueue *queue;//此处未进行任何操作
@property (nonatomic, strong) NSMutableArray *arr;
/**
 *  保存路径
 */
@property (nonatomic, copy) NSString *savePath;
@end

@implementation ViewController

- (NSString *)savePath{
    if (!_savePath) {
        _savePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        _savePath = [_savePath stringByAppendingPathComponent:@"People"];
    }
    return _savePath;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _arr = [NSMutableArray array];
    
    _queue = [FMDatabaseQueue databaseQueueWithPath:self.savePath];
    
}
/**
 *  执行查询操作，自定构造models集合
 *
 *  @param sql        sql语句
 *  @param args       sql参数
 *  @param modelClass 结果集model类型
 *  @param block      对model执行自定义操作
 *
 *  @return 查询结果集
 */
- (NSArray *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)args modelClass:(Class)modelClass performBlock:(void (^)(id model, FMResultSet *rs))block
{
    __block NSMutableArray *models = [NSMutableArray array];
    
    [_queue inDatabase:^(FMDatabase *db) {
        NSDictionary *mapping = nil;
        
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            id model = [[modelClass alloc] init];
            if(!mapping && [model conformsToProtocol:@protocol(ColumnPropertyMappingDelegate)]) {
                //实现了列-属性转换协议
                mapping = [model columnPropertyMapping];
            }
            
            for (int i = 0; i < [rs columnCount]; i++) {
                //列名
                NSString *columnName = [rs columnNameForIndex:i];
                //进行数据库列名到model之间的映射转换，拿到属性名
                NSString *propertyName;
                
                if(mapping) {
                    propertyName = mapping[columnName];
                    if (propertyName == nil) {
                        //如果映射未定义，则视为相同
                        propertyName = columnName;
                    }
                } else {
                    propertyName = columnName;
                }
                
                objc_property_t objProperty = class_getProperty(modelClass, propertyName.UTF8String);
                //如果属性不存在，则不操作
                if (objProperty) {
                    if(![rs columnIndexIsNull:i]) {
                        [self setProperty:model value:rs columnName:columnName propertyName:propertyName property:objProperty];
                    }
                }
                
                NSAssert(![propertyName isEqualToString:@"description"], @"description为自带方法，不能对description进行赋值，请使用其他属性名或请ColumnPropertyMappingDelegate进行映射");
            }
            
            //执行自定义操作
            if (block) {
                block(model, rs);
            }
            [models addObject:model];
        }
        
        [rs close];
    }];
    return models;
}

/**
 *  进行属性赋值
 */
- (void)setProperty:(id)model value:(FMResultSet *)rs columnName:(NSString *)columnName propertyName:(NSString *)propertyName property:(objc_property_t)property
{
    //    @"f":@"float",
    //    @"i":@"int",
    //    @"d":@"double",
    //    @"l":@"long",
    //    @"c":@"BOOL",
    //    @"s":@"short",
    //    @"q":@"long",
    //    @"I":@"NSInteger",
    //    @"Q":@"NSUInteger",
    //    @"B":@"BOOL",
    
    NSString *firstType = [[[[NSString stringWithUTF8String:property_getAttributes(property)] componentsSeparatedByString:@","] firstObject] substringFromIndex:1];
    
    
    if ([firstType isEqualToString:@"f"]) {
        NSNumber *number = [rs objectForColumnName:columnName];
        [model setValue:@(number.floatValue) forKey:propertyName];
        
    } else if([firstType isEqualToString:@"i"]){
        NSNumber *number = [rs objectForColumnName:columnName];
        [model setValue:@(number.intValue) forKey:propertyName];
        
    } else if([firstType isEqualToString:@"d"]){
        [model setValue:[rs objectForColumnName:columnName] forKey:propertyName];
        
    } else if([firstType isEqualToString:@"l"] || [firstType isEqualToString:@"q"]){
        [model setValue:[rs objectForColumnName:columnName] forKey:propertyName];
        
    } else if([firstType isEqualToString:@"c"] || [firstType isEqualToString:@"B"]){
        NSNumber *number = [rs objectForColumnName:columnName];
        [model setValue:@(number.boolValue) forKey:propertyName];
        
    } else if([firstType isEqualToString:@"s"]){
        NSNumber *number = [rs objectForColumnName:columnName];
        [model setValue:@(number.shortValue) forKey:propertyName];
        
    } else if([firstType isEqualToString:@"I"]){
        NSNumber *number = [rs objectForColumnName:columnName];
        [model setValue:@(number.integerValue) forKey:propertyName];
        
    } else if([firstType isEqualToString:@"Q"]){
        NSNumber *number = [rs objectForColumnName:columnName];
        [model setValue:@(number.unsignedIntegerValue) forKey:propertyName];
        
    } else if([firstType isEqualToString:@"@\"NSData\""]){
        NSData *value = [rs dataForColumn:columnName];
        [model setValue:value forKey:propertyName];
        
    } else if([firstType isEqualToString:@"@\"NSDate\""]){
        NSDate *value = [rs dateForColumn:columnName];
        [model setValue:value forKey:propertyName];
        
    } else if([firstType isEqualToString:@"@\"NSString\""]){
        NSString *value = [rs stringForColumn:columnName];
        [model setValue:value forKey:propertyName];
        
    } else {
        [model setValue:[rs objectForColumnName:columnName] forKey:propertyName];
    }
}

//---------------------------------------------------------------------
//增删改查
- (IBAction)add:(UIButton *)sender {
    [self openDB:@"People"];
}
- (IBAction)delete_btn:(UIButton *)sender {
    [self delete];
}
- (IBAction)update_btn:(UIButton *)sender {
    [self insert];
}
- (IBAction)query_btn:(UIButton *)sender {
    [self query];
}
//注意：dataWithPath中的路径参数一般会选择保存到沙箱中的Documents目录中；
//如果这个参数设置为nil则数据库会在内存中创建；
//如果设置为@””则会在沙箱中的临时目录创建,应用程序关闭则文件删除
//增
- (void)openDB:(NSString *)dbname{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    path = [path stringByAppendingPathComponent:dbname];
    NSLog(@"path--->%@",path);
    FMDatabase *db = [FMDatabase databaseWithPath:path];
    _fmdb = db;
    if ([db open]) {
        NSLog(@"数据库（%@）打开成功",dbname);
        //在FMDB中，除查询以外的所有操作，都称为“更新”
        //create、drop、insert、update、delete等
        //建表
        BOOL result = [db executeUpdate:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS t_student (id integer PRIMARY KEY AUTOINCREMENT, name text NOT NULL, age integer NOT NULL);"]];
        if (result) {
            NSLog(@"创表成功");
        }else{
            NSLog(@"创表失败");
        }
    }else{
        NSLog(@"数据库（%@）打开失败",dbname);
    }
}
//改
- (void)insert{
    for (int i = 0; i<10; i++) {
        NSString *name = [NSString stringWithFormat:@"jack_%d",i];
        [self.fmdb executeUpdate:@"INSERT INTO t_student (name, age) VALUES (?, ?);", name, @(arc4random_uniform(40))];
    }
}
//删
- (void)delete{
    [self.fmdb executeUpdate:@"DROP TABLE IF EXISTS t_student;"];
    [self.fmdb executeUpdate:@"CREATE TABLE IF NOT EXISTS t_student (id integer PRIMARY KEY AUTOINCREMENT, name text NOT NULL, age integer NOT NULL);"];
}
//查
- (void)query
{
    // 1.执行查询语句
    FMResultSet *resultSet = [self.fmdb executeQuery:@"SELECT * FROM t_student"];
    
    // 2.遍历结果
    while ([resultSet next]) {
        int ID = [resultSet intForColumn:@"id"];
        NSString *name = [resultSet stringForColumn:@"name"];
        int age = [resultSet intForColumn:@"age"];
        NSLog(@"%d %@ %d", ID, name, age);
    }
    
    NSArray *aaa = [self executeQuery:resultSet.query withArgumentsInArray:_arr modelClass:[Person class] performBlock:^(id model, FMResultSet *rs) {
        rs = resultSet;
    }];
    
    NSString *assert = [NSString stringWithFormat:@"当前文件路径：%s\n当前函数或方法：%s\n当前行号：%d\n错误原因：%@",__FILE__,__func__,__LINE__,@"查询生成的模型数组为空"];
    NSAssert(aaa.count !=0, assert);
    Person *p = aaa[0];
    NSLog(@"%@--%@--%d",aaa,p.name,p.age);
    WLog(@"%@",p.name);
    DLog(@"%@",p.name);
    WDLog(@"%@",p.name);
}

//---------------------------<<使用--------------------------------------

typedef NS_ENUM(NSUInteger, TEST){
    TEST_ONE = 0,
    TEST_TWO = 1 << 0,
    TEST_THR = 2 << 1
};
- (void)test{
    //  <<使用
    int num = 10;//55=110111  18=10010
    num <<= 3;//220=11011100  72=1001000
    NSLog(@"%d",num);
    num <<= 3;//880=1101110000  288=1001000
    NSLog(@"%d",num);//288=100100000
    num = 16;
    num >>= 3;//13=1101 4=100
    NSInteger aa = 0X00FF0000;
    NSInteger bb = 0X67;
    NSLog(@"%d--%ld--%ld--%ld--%ld",num,UIControlStateApplication,aa,bb,TEST_THR);
    // 1 2 4 8 16 32 64 128 256
    
}
//- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    [self testBy:TEST_ONE & TEST_TWO & TEST_THR];
//}
- (void)testBy:(TEST)test{
    NSLog(@"all=%ld",test);
    if (test == (TEST_THR | TEST_TWO)) {
        NSLog(@"32--%ld",test);
    }else if (test == TEST_TWO){
        NSLog(@"2--%ld",test);
    }else if (test == TEST_THR){
        NSLog(@"3--%ld",test);
    }else if (test == TEST_ONE){
        NSLog(@"1--%ld",test);
    }
}

@end
