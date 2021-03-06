//  Copyright 2009-2010 Aurora Feint, Inc.
// 
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  	http://www.apache.org/licenses/LICENSE-2.0
//  	
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "OFFacebookExtendedCredentialController.h"
#import "FBConnect.h"
#import "OFSettings.h"
#import "OFFormControllerHelper+Overridables.h"
#import "OFFormControllerHelper+Submit.h"
#import "OFISerializer.h"
#import "OFNavigationController.h"
#import "OFFacebookAccountController.h"
#import "OFControllerLoader.h"
#import "OFActionRequest.h"
#import "OFSocialNotification.h"
#import "OFImageView.h"
#import "OFImageLoader.h"
#import "OpenFeint+Private.h"
#import "OFRootController.h"
#import "OFSendSocialNotificationController.h"

@implementation OFFacebookExtendedCredentialController

- (void)awakeFromNib
{
	[super awakeFromNib];
	skipLoginOnAppear = YES;
	self.getPostingPermission = YES;
}

-(NSString*)singularResourceName
{
	return @"credential";
}

- (void)displayError:(NSString*)errorString
{
	[[[[UIAlertView alloc] 
	   initWithTitle:OFLOCALSTRING(@"Facebook Connect Error")
	   message:errorString
	   delegate:nil
	   cancelButtonTitle:OFLOCALSTRING(@"Ok")
	   otherButtonTitles:nil] autorelease] show];
}

-(void)populateViewDataMap:(OFViewDataMap*)dataMap
{
}

- (bool)canReceiveCallbacksNow
{
	return YES;
}

- (void) showLoadingScreen
{
	mCustomLoadingView.hidden = NO;
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.25f];
	[UIView setAnimationBeginsFromCurrentState:YES];
	mCustomLoadingView.alpha = 1.f;
	[UIView commitAnimations];
}

- (void) hideLoadingScreen
{
	mCustomLoadingView.hidden = YES;

	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.25f];
	[UIView setAnimationBeginsFromCurrentState:YES];
	mCustomLoadingView.alpha = 0.f;
	[UIView commitAnimations];
}

- (IBAction)login
{
	[super promptToLogin];
}

- (void)dismiss
{
	[[OpenFeint getRootController] dismissNonFullScreenModalViewControllerAnimated:YES];
}

- (IBAction)skip
{
	[self dismiss];
	[OFSendSocialNotificationController dismiss];
}

-(void)onFormSubmitted
{
	[self dismiss];

	if (mRequestToSubmit && !mNextController)
	{
		[mRequestToSubmit dispatch];
	}
	else if (mNextController)
	{
		[OpenFeint presentModalOverlay:mNextController];
	}
}

- (void)registerActionsNow
{
}

- (void)setNextController:(UIViewController<OFExtendedCredentialController>*)_next
{
	OFSafeRelease(mNextController);
	mNextController = [_next retain];
}

- (void)setRequestRequiringCredential:(OFActionRequest*)_request
{
	OFSafeRelease(mRequestToSubmit);
	mRequestToSubmit = [_request retain];
}

- (void)setSocialNotification:(OFSocialNotification*)_notification
{
	mNotificationImage.imageUrl = _notification.imageUrl;
	mNotificationText.text = _notification.text;
}

- (void)dealloc 
{
	OFSafeRelease(mRequestToSubmit);
	OFSafeRelease(mNextController);
	OFSafeRelease(mNotificationImage);
	OFSafeRelease(mNotificationText);
	OFSafeRelease(mCustomLoadingView);
	[super dealloc];
}

@end