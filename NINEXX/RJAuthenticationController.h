//
//  RJAuthenticationController.h
//  Community
//

#import <UIKit/UIKit.h>


@class RJAuthenticationController;

@protocol RJAuthenticationControllerDelegate <NSObject>

- (void)authenticationControllerDidCancel:(RJAuthenticationController *)authenticationController;
- (void)authenticationControllerDidFinish:(RJAuthenticationController *)authenticationController;

@end


@interface RJAuthenticationController : NSObject

@property (weak, nonatomic) id<RJAuthenticationControllerDelegate> delegate;

- (instancetype)initWithPresentingViewController:(UIViewController *)viewController;
- (void)startAuthentication;

@end
