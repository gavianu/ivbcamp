//
//  MainViewController.h
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/20/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController<UITextFieldDelegate>

@property (strong, nonatomic) UITextField           *serverAddressField;
@property (strong, nonatomic) UISegmentedControl    *codecPicker;
@property (strong, nonatomic) UIButton              *connectButton;

@property (strong, nonatomic) NSString              *serverAddress;


- (void)connectButtonTapped;

@end
