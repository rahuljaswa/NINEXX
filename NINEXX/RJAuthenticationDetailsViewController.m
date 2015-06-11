//
//  RJAuthenticationDetailsViewController.m
//  NINEXX
//
//  Created by Rahul Jaswa on 6/10/15.
//  Copyright (c) 2015 Rahul Jaswa. All rights reserved.
//

#import "RJAuthenticationDetailsViewController.h"
#import "RJStyleManager.h"
#import "UIImage+RJAdditions.h"
#import <SVProgressHUD/SVProgressHUD.h>


@interface RJAuthenticationDetailsViewController ()

@property (nonatomic, assign) BOOL viewWillAppear;

@end


@implementation RJAuthenticationDetailsViewController

#pragma mark - Private Instance Methods

- (void)buttonPressed:(UIButton *)button {
    if (self.textField.text.length < 4) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Name must be 4 characters or more", nil)];
    } else {
        [self.delegate authenticationDetailsViewControllerDidFinish:self];
    }
}

- (void)cancelButtonPressed:(UIButton *)button {
    [self.delegate authenticationDetailsViewControllerDidCancel:self];
}

#pragma mark - Public Instance Methods

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UIView *textField = self.textField;
    UIView *button = self.button;
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:textField];
    [self.view addSubview:button];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(textField, button);
    [self.view addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-40-[textField]-40-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-60-[textField(40)]-40-[button(30)]" options:0 metrics:nil views:views]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:button
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0f
                                                           constant:0.0f]];
}

- (instancetype)init {
    return [self initWithNibName:nil bundle:nil];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self){
        _viewWillAppear = NO;
        
        RJStyleManager *styleManager = [RJStyleManager sharedInstance];
        
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        [_button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        _button.clipsToBounds = YES;
        _button.contentEdgeInsets = UIEdgeInsetsMake(10.0f, 15.0f, 10.0f, 15.0f);
        _button.layer.borderColor = [UIColor whiteColor].CGColor;
        _button.layer.cornerRadius = 5.0f;
        _button.layer.borderWidth = 2.0f;
        [_button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_button setTitleColor:styleManager.themeColor forState:UIControlStateHighlighted];
        [_button setBackgroundImage:[UIImage imageWithColor:styleManager.themeColor] forState:UIControlStateNormal];
        [_button setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
        
        _textField = [[UITextField alloc] initWithFrame:CGRectZero];
        _textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 10.0f, 10.0f)];
        _textField.leftViewMode = UITextFieldViewModeAlways;
        _textField.rightView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 10.0f, 10.0f)];
        _textField.rightViewMode = UITextFieldViewModeAlways;
        _textField.tintColor = [UIColor whiteColor];
        _textField.textColor = [UIColor whiteColor];
        _textField.textAlignment = NSTextAlignmentCenter;
        _textField.layer.borderColor = [UIColor whiteColor].CGColor;
        _textField.layer.cornerRadius = 5.0f;
        _textField.layer.borderWidth = 2.0f;
    }
    return self;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (self.viewWillAppear && ![self.textField isFirstResponder]) {
        [self.textField becomeFirstResponder];
        self.viewWillAppear = NO;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [[RJStyleManager sharedInstance] themeColor];
    
    UIImage *cancelImage = [UIImage tintableImageNamed:@"cancelButton"];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:cancelImage
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(cancelButtonPressed:)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.viewWillAppear = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

@end
