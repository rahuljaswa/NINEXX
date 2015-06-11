//
//  RJAuthenticationDetailsViewController.h
//  NINEXX
//
//  Created by Rahul Jaswa on 6/10/15.
//  Copyright (c) 2015 Rahul Jaswa. All rights reserved.
//

#import <UIKit/UIKit.h>


@class RJAuthenticationDetailsViewController;

@protocol RJAuthenticationDetailsViewControllerDelegate <NSObject>

- (void)authenticationDetailsViewControllerDidCancel:(RJAuthenticationDetailsViewController *)viewController;
- (void)authenticationDetailsViewControllerDidFinish:(RJAuthenticationDetailsViewController *)viewController;

@end


@interface RJAuthenticationDetailsViewController : UIViewController

@property (weak, nonatomic) id<RJAuthenticationDetailsViewControllerDelegate> delegate;

@property (strong, nonatomic, readonly) UIButton *button;
@property (strong, nonatomic, readonly) UITextField *textField;

@end
