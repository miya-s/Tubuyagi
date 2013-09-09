//
//  ManualInputViewController.m
//  Tubuyagi
//
//  Created by Genki Ishibashi on 13/09/09.
//  Copyright (c) 2013年 Genki Ishibashi. All rights reserved.
//

#import "ManualInputViewController.h"

@interface ManualInputViewController ()

@end

@implementation ManualInputViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backMainView:(UIBarButtonItem *)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
