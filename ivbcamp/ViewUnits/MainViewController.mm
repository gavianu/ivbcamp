//
//  MainViewController.m
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/20/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import "MainViewController.h"
#import "SessionConnection.h"

@interface MainViewController ()

@end

@implementation MainViewController

#pragma mark - initialization

- (id)init {
    if ((self = [super init])) {
        // Custom initialization
    }
    return self;
}

#pragma mark - deallocation

//No need on ARC enable
//- (void)dealloc {
//    [_serverAddressField release];
//    [_codecPicker release];
//    [_connectButton release];
//    [_serverAddress release];
//    [super dealloc];
//}

#pragma mark - Lifecycle

- (void)loadView {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    //    CGRect navBarRect = self.navigationController.navigationBar.frame;
    
    UIView *view = [[UIView alloc] initWithFrame:screenRect];
    [view setBackgroundColor:[UIColor whiteColor]];
    self.view = view;
    
    _serverAddressField = [[UITextField alloc] initWithFrame:CGRectMake(10, 100, screenRect.size.width/2, 40)];
    _serverAddressField.borderStyle = UITextBorderStyleRoundedRect;
    _serverAddressField.font = [UIFont systemFontOfSize:15];
    _serverAddressField.placeholder = @"enter server address";
    _serverAddressField.autocorrectionType = UITextAutocorrectionTypeNo;
    _serverAddressField.keyboardType = UIKeyboardTypeDefault;
    _serverAddressField.returnKeyType = UIReturnKeyDone;
    _serverAddressField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _serverAddressField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _serverAddressField.delegate = self;
    [self.view addSubview:_serverAddressField];
    
    NSArray *codedListArray = [NSArray arrayWithObjects: @"AAC", @"G729", nil];
    _codecPicker = [[UISegmentedControl alloc] initWithItems:codedListArray];
    _codecPicker.frame = CGRectMake(screenRect.size.width/2 + 20, 100, 200, 40);
    //    [_codecPicker addTarget:self action:@selector(MySegmentControlAction:) forControlEvents: UIControlEventValueChanged];
    _codecPicker.selectedSegmentIndex = 0;
    [self.view addSubview:_codecPicker];
    
    _connectButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    _connectButton.frame = CGRectMake(screenRect.size.width/2 + 230, 100, 60, 40);
    [view addSubview:_connectButton];
    [_connectButton addTarget:self action:@selector(connectButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    
    _serverAddress = @"54.76.116.126";
    
    [[SessionConnection sharedInstance] connectToHost:_serverAddress onPort:7827 error:nil];

}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - actions

- (void)connectButtonTapped {
    [[SessionConnection sharedInstance] startAudioSession];    
}

@end
