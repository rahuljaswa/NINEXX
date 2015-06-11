//
//  RJAuthenticationController.m
//  Community
//

#import "RJAppDelegate.h"
#import "RJAuthenticationController.h"
#import "RJAuthenticationDetailsViewController.h"
#import "RJCoreDataManager.h"
#import "RJManagedObjectUser.h"
#import "RJRemoteObjectUser.h"
#import "RJStyleManager.h"
#import <DigitsKit/Digits.h>
#import <Parse/PFInstallation.h>
#import <Parse/PFQuery.h>
#import <SVProgressHUD/SVProgressHUD.h>


@interface RJAuthenticationController () <RJAuthenticationDetailsViewControllerDelegate>

@property (strong, nonatomic, readonly) UIViewController *presentingViewController;
@property (nonatomic, strong) RJRemoteObjectUser *remoteUser;

@end


@implementation RJAuthenticationController

@synthesize presentingViewController = _presentingViewController;

#pragma mark - Private Protocols

- (void)authenticationDetailsViewControllerDidCancel:(RJAuthenticationDetailsViewController *)viewController {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    [self cancelAuthentication];
}

- (void)authenticationDetailsViewControllerDidFinish:(RJAuthenticationDetailsViewController *)viewController {
    self.remoteUser.name = viewController.textField.text;
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Saving name...", nil) maskType:SVProgressHUDMaskTypeClear];
    [self.remoteUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [self completeLogin];
        } else {
            NSLog(@"Error saving display name\n\n%@", [error localizedDescription]);
        }
        [SVProgressHUD dismiss];
    }];
}

#pragma mark - Private Instance Methods

- (void)cancelAuthentication {
    RJManagedObjectUser *currentUser = [RJManagedObjectUser currentUser];
    if (currentUser) {
        currentUser.currentUser = @NO;
        NSError *error = nil;
        if (![[currentUser managedObjectContext] save:&error]) {
            NSLog(@"Error logging current user out in core data\n\n%@", [error localizedDescription]);
        }
    }
    
    [RJRemoteObjectUser logOut];
    
    if ([self.delegate respondsToSelector:@selector(authenticationControllerDidCancel:)]) {
        [self.delegate authenticationControllerDidCancel:self];
    }
}

- (void)addCommunityMembershipsAndUpdateInstallationForUser:(RJRemoteObjectUser *)user withCompletion:(void (^)(BOOL success))completion {
    [user addUniqueObject:[[NSBundle mainBundle] bundleIdentifier] forKey:@"communityMemberships"];
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            PFInstallation *currentInstallation = [PFInstallation currentInstallation];
            RJRemoteObjectUser *currentUserOnInstallation = currentInstallation[@"user"];
            if (!currentUserOnInstallation) {
                currentInstallation[@"user"] = [RJRemoteObjectUser currentUser];
            }
            
            [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (completion) {
                    completion(succeeded);
                }
                if (!succeeded) {
                    NSLog(@"Error updating installation with user: %@", error);
                }
            }];
        } else {
            NSLog(@"Error updating user's phone verification status\n\n%@", [error localizedDescription]);
            if (completion) {
                completion(NO);
            }
        }
    }];
}

- (void)startNameUpdating {
    RJAuthenticationDetailsViewController *authenticationDetailsViewController = [[RJAuthenticationDetailsViewController alloc] init];
    authenticationDetailsViewController.delegate = self;
    authenticationDetailsViewController.title = [NSLocalizedString(@"Enter Display Name", nil) uppercaseString];
    authenticationDetailsViewController.textField.placeholder = NSLocalizedString(@"Display Name", nil);
    authenticationDetailsViewController.textField.keyboardType = UIKeyboardTypeAlphabet;
    authenticationDetailsViewController.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    if (self.remoteUser) {
        authenticationDetailsViewController.textField.text = self.remoteUser.name;
    } else {
        authenticationDetailsViewController.textField.text = nil;
    }
    [authenticationDetailsViewController.button setTitle:NSLocalizedString(@"Finish", nil) forState:UIControlStateNormal];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:authenticationDetailsViewController];
    [self.presentingViewController presentViewController:navigationController animated:YES completion:^{
        [SVProgressHUD dismiss];
    }];
}

- (void)completeLogin {
    RJAppDelegate *appDelegate = (RJAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate requestNotificationsPermissionsWithCompletion:^{
        [[RJCoreDataManager sharedInstance] marshallPFObjects:@[self.remoteUser] relation:kRJDataMarshallerPFRelationNone targetUser:nil targetCategory:nil completion:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kRJUserLoggedInNotification object:nil];
            [SVProgressHUD dismiss];
            [self.delegate authenticationControllerDidFinish:self];
        }];
    }];
}

#pragma mark - Public Instance Methods

- (instancetype)initWithPresentingViewController:(UIViewController *)viewController {
    self = [super init];
    if (self) {
        _presentingViewController = viewController;
    }
    return self;
}

- (void)startAuthentication {
    DGTAppearance *appearance = [[DGTAppearance alloc] init];
    appearance.backgroundColor = [[RJStyleManager sharedInstance] themeColor];
    appearance.accentColor = [UIColor whiteColor];
    [[Digits sharedInstance] authenticateWithDigitsAppearance:appearance viewController:nil title:nil completion:^(DGTSession *session, NSError *error) {
        if (session) {
            [SVProgressHUD showWithStatus:NSLocalizedString(@"Retrieving account details...", nil) maskType:SVProgressHUDMaskTypeClear];
            [RJRemoteObjectUser logInWithUsernameInBackground:session.phoneNumber
                                                     password:session.phoneNumber
                                                        block:^(PFUser *user, NSError *error)
             {
                 if (user) {
                     self.remoteUser = (RJRemoteObjectUser *)user;
                     if (self.remoteUser.admin) {
                         [self completeLogin];
                     } else {
                         if ([self.remoteUser.twitterDigitsUserID isEqualToString:session.userID]) {
                             __weak RJAuthenticationController *weakSelf = self;
                             [self addCommunityMembershipsAndUpdateInstallationForUser:self.remoteUser withCompletion:^(BOOL success) {
                                 __strong RJAuthenticationController *strongSelf = weakSelf;
                                 if (success) {
                                     [strongSelf startNameUpdating];
                                 } else {
                                     [strongSelf.delegate authenticationControllerDidCancel:strongSelf];
                                 }
                             }];
                         } else {
                             self.remoteUser.twitterDigitsUserID = session.userID;
                             [self.remoteUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                 __weak RJAuthenticationController *weakSelf = self;
                                 [self addCommunityMembershipsAndUpdateInstallationForUser:self.remoteUser withCompletion:^(BOOL success) {
                                     __strong RJAuthenticationController *strongSelf = weakSelf;
                                     if (success) {
                                         [strongSelf startNameUpdating];
                                     } else {
                                         [strongSelf.delegate authenticationControllerDidCancel:strongSelf];
                                     }
                                 }];
                             }];
                         }
                     }
                 } else {
                     [SVProgressHUD showWithStatus:NSLocalizedString(@"Creating account...", nil) maskType:SVProgressHUDMaskTypeClear];
                     
                     self.remoteUser = [RJRemoteObjectUser object];
                     self.remoteUser.username = session.phoneNumber;
                     self.remoteUser.password = session.phoneNumber;
                     self.remoteUser.phone = session.phoneNumber;
                     self.remoteUser.twitterDigitsUserID = session.userID;
                     self.remoteUser.skeleton = NO;
                     [self.remoteUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                         if (succeeded) {
                             __weak RJAuthenticationController *weakSelf = self;
                             [self addCommunityMembershipsAndUpdateInstallationForUser:self.remoteUser withCompletion:^(BOOL success) {
                                 __strong RJAuthenticationController *strongSelf = weakSelf;
                                 if (success) {
                                     [strongSelf startNameUpdating];
                                 } else {
                                     [strongSelf.delegate authenticationControllerDidCancel:strongSelf];
                                 }
                             }];
                         } else {
                             NSLog(@"Error signing up user\n\n%@", [error localizedDescription]);
                         }
                     }];
                 }
             }];
        } else {
            [self.delegate authenticationControllerDidCancel:self];
        }
    }];
}

@end
