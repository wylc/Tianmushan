/**************************************************************************
 *
 *  Created by shushaoyong on 2016/10/31.
 *    Copyright © 2016年 踏潮. All rights reserved.
 * 
 * 项目名称：浙江踏潮-天目山-h5模版制作软件
 * 版权说明：本软件属浙江踏潮网络科技有限公司所有，在未获得浙江踏潮网络科技有限公司正式授权
 *           情况下，任何企业和个人，不能获取、阅读、安装、传播本软件涉及的任何受知
 *           识产权保护的内容。
 *
 ***************************************************************************/

#import <Foundation/Foundation.h>

@interface TMSCategoryItem : NSObject

/**图片地址*/
@property(nonatomic,copy)NSString *imageurl;

/**名称*/
@property(nonatomic,copy)NSString *nick;

/**分类名*/
@property(nonatomic,copy)NSString *name;

/**模板个数*/
@property(nonatomic,assign)NSInteger num;

@end