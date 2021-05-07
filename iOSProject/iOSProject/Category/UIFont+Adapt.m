//
//  UIFont+Adapt.m
//  iOSProject
//
//  Created by 肖志超 on 2021/4/28.
//

#import "UIFont+Adapt.h"
#import <objc/runtime.h>

@implementation UIFont (Adapt)


/**
 * runtime 交换方法
 *  class_getClassMethod(class, selector)
 *  method_exchangeImplementions(new,old)
 */
+ (void)load
{
    //保证只执行一次
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method newMethod = class_getClassMethod([self class], @selector(adaptFontOfSize:));
        Method originalMethod = class_getClassMethod([self class], @selector(systemFontOfSize:));
        method_exchangeImplementations(newMethod, originalMethod);
    });
}

#warning 375是UI设计师采用的手机模型的宽
+(UIFont*)adaptFontOfSize:(CGFloat)fontSize
{
    UIFont *font = nil;
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    font = [UIFont adaptFontOfSize:fontSize *(width/375)];//对字体进行适配
    return font;
}


/**
 * runtime 实现分类动态添加属性
 * objc_getAssociatedObject(self,key)
 * objc_setAssociatedObject(self,key,属性,保存策略)
 * OBJC_ASSOCIATION_RETAIN
 * //OBJC_ASSOCIATION_ASSIGN类似于我们常用的assign,assign策略的特点就是在对象释放以后，不会主动将应用的对象置为nil，这样会有访问僵尸对象导致应用崩溃的风险。为了解决这个问题：我们可以创建一个替身对象,以OBJC_ASSOCIATION_RETAIN_NONATOMIC 的策略来强引用替身对象，然后在对象中以weak的策略去引用我们真实需要保护的对象。这样就能解决这个可能导致崩溃的问题了。
 
 //结论：将OBJC_ASSOCIATION_ASSIGN改为OBJC_ASSOCIATION_RETAIN，这样在本对象有一个强引用，这个被关联的对象也就不会被释放，生命周期也和本对象相同了。我认为既然关联对象传入的都是对象，那么其实绝大多时候用的应该是OBJC_ASSOCIATION_RETAIN，在我们项目中传入的对象很多是NSNumber类型（包装的bool或则int）的时候都是用的OBJC_ASSOCIATION_ASSIGN，以前没暴露问题也是误打误撞错进错出。所以除了一些需要破解循环引用的场景，关联对象的内存操作修饰符建议都用OBJC_ASSOCIATION_RETAIN
 */
-(NSString *)testRun
{
    return objc_getAssociatedObject(self, @"test");
}

-(void)setTestRun:(NSString *)testRun
{
    return objc_setAssociatedObject(self, @"test", testRun, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
