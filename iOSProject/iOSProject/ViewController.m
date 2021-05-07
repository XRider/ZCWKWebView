//
//  ViewController.m
//  iOSProject
//
//  Created by 肖志超 on 2021/4/22.
//

#import "ViewController.h"
#import "ZCWebViewController.h"
#import "UIFont+Adapt.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface ViewController ()

@end

@implementation ViewController

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"WKWebView";
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    
    [btn setFrame:CGRectMake(50, 100, 100, 100)];
    
    btn.backgroundColor = [UIColor redColor];
    
    [btn addTarget:self action:@selector(jump) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btn];
    
    //测试Runtime给系统分类动态添加属性
//    UIFont *font = [UIFont systemFontOfSize:14.0f];
//
//    font.testRun = @"runtime";
//
////    ((void(*)(id,SEL, id,id))objc_msgSend)(self, @selector(msgSend), nil, nil);
//
//    objc_msgSend(self, @selector(msgSend));
//    //测试Runtime消息传递机制
//    [self performSelector:@selector(eat:)];
}

//-(void)msgSend
//{
//    NSLog(@"msgSend");
//}
//
//+(BOOL)resolveInstanceMethod:(SEL)sel
//{
//    if (sel == @selector(eat:)) {
//        class_addMethod([self class], sel, (IMP)fooMethod, "v@:");
//        return YES;
//    }
//    return [super resolveClassMethod:sel];
//}
//
//void fooMethod(id obj, SEL _cmd)
//{
//    NSLog(@"foo");
//}

-(void)jump
{
    [self.navigationController pushViewController:[[ZCWebViewController alloc] init] animated:YES];
}




@end
