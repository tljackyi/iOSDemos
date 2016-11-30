//
//  ViewController.m
//  Webp
//
//  Created by yitailong on 2016/11/30.
//  Copyright © 2016年 yitailong. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"webp" ofType:@"html"];
    
    NSString *html = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    
    [self.webView loadHTMLString:html baseURL:nil];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
