//
//  SqliteManager.h
//  Sqlite
//
//  Created by mac book on 16/1/15.
//  Copyright © 2016年 mac book. All rights reserved.
//
//这只是一个简单的封装，还有更多的细节没有考虑，例如如何处理并发安全性，如何更好的处理事务等

#import <Foundation/Foundation.h>
#import <sqlite3.h>
//#import "KCSingleton.h"
@interface SqliteManager : NSObject;
#pragma mark - 属性
#pragma mark 数据库引用，使用它进行数据库操作
@property (nonatomic) sqlite3 *database;
#pragma mark - 共有方法
/**
 *  打开数据库
 *
 *  @param dbname 数据库名称
 */
-(void)openDb:(NSString *)dbname;
/**
 *  执行无返回值的sql
 *
 *  @param sql sql语句
 */
-(void)executeNonQuery:(NSString *)sql;
/**
 *  执行有返回值的sql
 *
 *  @param sql sql语句
 *
 *  @return 查询结果
 */
-(NSArray *)executeQuery:(NSString *)sql;
@end