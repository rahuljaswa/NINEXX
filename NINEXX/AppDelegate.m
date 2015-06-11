//
//  ThemedAppDelegate.m
//  NINEXX
//
//  Created by Rahul Jaswa on 1/18/15.
//  Copyright (c) 2015 Rahul Jaswa. All rights reserved.
//

#import "AppDelegate.h"
#import "RJAuthenticationController.h"
#import <Snapp/RJManagedObjectUser.h>
#import <Snapp/RJStyleManager.h>
#import <Snapp/RJTemplateManager.h>
#import <Fabric/Fabric.h>
#import <DigitsKit/DigitsKit.h>


@interface AppDelegate () <RJAuthenticationControllerDelegate>

@property (nonatomic, strong) RJAuthenticationController *authenticationController;
@property (nonatomic, copy) void (^authenticationCompletion) (BOOL);

@end


@implementation AppDelegate

#pragma mark - Private Protocols - RJAuthenticationControllerDelegate

- (void)authenticationControllerDidCancel:(RJAuthenticationController *)authenticationController {
    if (self.authenticationCompletion) {
        self.authenticationCompletion(NO);
        self.authenticationCompletion = nil;
    }
    [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)authenticationControllerDidFinish:(RJAuthenticationController *)authenticationController {
    if (self.authenticationCompletion) {
        self.authenticationCompletion(YES);
        self.authenticationCompletion = nil;
    }
    [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private Instance Methods

- (void)customizeStyleManager:(RJStyleManager *)styleManager {
    styleManager.cropsImagesToSquares = NO;
    styleManager.displaysImageResultsFromWeb = NO;
    styleManager.themeColor = [UIColor colorWithRed:0.0f/255.0f green:122.0f/255.0f blue:255.0f/255.0f alpha:1.0f];
    styleManager.themedTextColor = [UIColor colorWithRed:0.0f/255.0f green:122.0f/255.0f blue:235.0f/255.0f alpha:1.0f];
}

- (void)customizeTemplateManager:(RJTemplateManager *)templateManager {
    templateManager.type = kRJTemplateManagerTypeClassifieds;
}

- (void)userDidLogOut:(NSNotification *)notification {
    [[Digits sharedInstance] logOut];
}

#pragma mark - Public Instance Methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Fabric with:@[DigitsKit]];
    [self customizeStyleManager:self.styleManager];
    [self customizeTemplateManager:self.templateManager];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogOut:) name:kRJUserLoggedOutNotification object:nil];
    
    BOOL finished = [super application:application didFinishLaunchingWithOptions:launchOptions];
    
    self.authenticationController = [[RJAuthenticationController alloc] initWithPresentingViewController:self.window.rootViewController];
    self.authenticationController.delegate = self;
    
    return finished;
}

- (void)authenticateWithCompletion:(void (^)(BOOL))completion {
    self.authenticationCompletion = completion;
    [self.authenticationController startAuthentication];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
