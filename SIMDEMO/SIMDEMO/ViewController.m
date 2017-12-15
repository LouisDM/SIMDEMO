//
//  ViewController.m
//  SIMDEMO
//
//  Created by 辜东明 on 2017/11/6.
//  Copyright © 2017年 Louis. All rights reserved.
//

#import "ViewController.h"

#import "SIMManagers.h"
#import "UIView+Boom.h"
#import "AView.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIView *viewa;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    SIMManagers *simm = [SIMManagers new];
    [simm demo];
    
//    AView *av = [[AView alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
//    [self.view addSubview:av];
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [av removeFromSuperview];
//    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)tap:(id)sender {

    [self.viewa boom];
}


@end
