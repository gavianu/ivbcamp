//
//  MainViewController.h
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/20/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController<UITextFieldDelegate>

@property (retain, nonatomic) UITextField           *serverAddressField;
@property (retain, nonatomic) UISegmentedControl    *codecPicker;
@property (retain, nonatomic) UIButton              *connectButton;

@property (retain, nonatomic) NSString              *serverAddress;


- (void)connectButtonTapped;

@end
