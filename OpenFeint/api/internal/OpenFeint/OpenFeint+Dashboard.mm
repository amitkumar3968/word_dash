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

#import "OpenFeint+Dashboard.h"
#import "OpenFeint+Private.h"
#import "OFSelectChatRoomDefinitionController.h"
#import "OFControllerLoader.h"
#import "OFApplicationDescriptionController.h"
#import "OFSelectInviteTypeController.h"
#import "OFConversationController.h"
#import "OFSendSocialNotificationController.h"
#import "OFGameProfilePageInfo.h"
#import "OpenFeint+UserOptions.h"

const NSString* OpenFeintDashBoardTabNowPlaying = @"GameProfile";
const NSString* OpenFeintDashBoardTabMyFeint = @"MyFeint";
const NSString* OpenFeintDashBoardTabGames = @"GameDiscovery";

const NSString* OpenFeintControllerAchievementsList = @"AchievementList";
const NSString* OpenFeintControllerLeaderboardsList = @"Leaderboard";
const NSString* OpenFeintControllerChallengesList = @"ChallengeList";
const NSString* OpenFeintControllerFindFriends = @"ImportFriends";
const NSString* OpenFeintControllerWhosPlaying = @"WhosPlaying";
const NSString* OpenFeintControllerHighScores = @"HighScore";

@implementation OpenFeint (Dashboard)

+ (void)launchDashboardWithWhosPlayingPage
{
	[OpenFeint launchDashboardWithDelegate:nil tabControllerName:OpenFeintDashBoardTabNowPlaying andController:OpenFeintControllerWhosPlaying];
}

+ (void)launchDashboardWithAchievementsPage
{
	[OpenFeint launchDashboardWithDelegate:nil tabControllerName:OpenFeintDashBoardTabNowPlaying andController:OpenFeintControllerAchievementsList];
}

+ (void)launchDashboardWithListLeaderboardsPage;
{
	[OpenFeint launchDashboardWithDelegate:nil tabControllerName:OpenFeintDashBoardTabNowPlaying andController:OpenFeintControllerLeaderboardsList];
}

+ (void)launchDashboardWithHighscorePage:(NSString*)leaderboardId;
{
	NSArray* controllers = [[[NSArray alloc] initWithObjects:OpenFeintControllerLeaderboardsList,leaderboardId,nil] autorelease];
	[OpenFeint launchDashboardWithDelegate:nil tabControllerName:OpenFeintDashBoardTabNowPlaying andControllers:controllers];
}

+ (void)launchDashboardWithChallengesPage;
{
	[OpenFeint launchDashboardWithDelegate:nil tabControllerName:OpenFeintDashBoardTabNowPlaying andController:OpenFeintControllerChallengesList];
}

+ (void)launchDashboardWithFindFriendsPage;
{
	[OpenFeint launchDashboardWithDelegate:nil tabControllerName:OpenFeintDashBoardTabMyFeint andController:OpenFeintControllerFindFriends];
}

+ (void)launchDashboardWithListGlobalChatRoomsPage
{
	OFSelectChatRoomDefinitionController* chatController = (OFSelectChatRoomDefinitionController*)OFControllerLoader::load(@"SelectChatRoomDefinition");
	chatController.includeGlobalRooms = YES;
	chatController.includeDeveloperRooms = NO;
	chatController.includeApplicationRooms = NO;
	NSArray* controllers = [NSArray arrayWithObject:chatController];
	[OpenFeint launchDashboardWithDelegate:nil tabControllerName:OpenFeintDashBoardTabNowPlaying andControllers:controllers];
}

+ (void)launchDashboardWithiPurchasePage:(NSString*)clientApplicationId
{
	OFApplicationDescriptionController* iPurchaseController = [OFApplicationDescriptionController applicationDescriptionForId:clientApplicationId appBannerPlacement:@"directDashboardLaunch"];
	NSArray* controllers = [NSArray arrayWithObject:iPurchaseController];
	[OpenFeint launchDashboardWithDelegate:nil tabControllerName:OpenFeintDashBoardTabGames andControllers:controllers];
}

+ (void)launchDashboardWithSwitchUserPage
{
	NSArray* controllers = [NSArray arrayWithObject:OFControllerLoader::load(@"UseNewOrOldAccount")];
	[OpenFeint launchDashboardWithDelegate:nil tabControllerName:OpenFeintDashBoardTabMyFeint andControllers:controllers];
}

+ (void)launchDashboardWithForumsPage
{
	OFAssert([OpenFeint allowUserGeneratedContent], "You must enable User Generated Content to launch directly to the forums page!");
	
	if ([OpenFeint allowUserGeneratedContent])
	{
		NSArray* controllers = [NSArray arrayWithObject:OFControllerLoader::load(@"ForumTopicList")];
		[OpenFeint launchDashboardWithDelegate:nil tabControllerName:OpenFeintDashBoardTabNowPlaying andControllers:controllers];
	}
}

+ (void)launchDashboardWithInvitePage
{
	NSArray* controllers = [NSArray arrayWithObject:[OFSelectInviteTypeController inviteTypeControllerWithInviteIdentifier:nil]];
	[OpenFeint launchDashboardWithDelegate:nil tabControllerName:OpenFeintDashBoardTabNowPlaying andControllers:controllers];
}

+ (void)launchDashboardWithSpecificInvite:(NSString*)inviteIdentifier
{
	NSArray* controllers = [NSArray arrayWithObject:[OFSelectInviteTypeController inviteTypeControllerWithInviteIdentifier:inviteIdentifier]];
	[OpenFeint launchDashboardWithDelegate:nil tabControllerName:OpenFeintDashBoardTabMyFeint andControllers:controllers];
}

+ (void)launchDashboardWithIMToUser:(OFUser*)user initialText:(NSString*)initialText
{
	NSArray* controllers = [NSArray arrayWithObject:[OFConversationController conversationWithId:nil withUser:user initialText:initialText]];
	[OpenFeint launchDashboardWithDelegate:nil tabControllerName:OpenFeintDashBoardTabMyFeint andControllers:controllers];
}

+ (void)launchDashboardWithSocialNotificationWithPrepopulatedText:(NSString*)prepopulatedText originialMessage:(NSString*)originalMessage imageName:(NSString*)imageName linkedUrl:(NSString*)url;
{
	OFSendSocialNotificationController* controller = (OFSendSocialNotificationController*)OFControllerLoader::load(@"SendSocialNotification");
	[controller setPrepopulatedText:prepopulatedText andOriginalMessage:originalMessage];
	
	if(imageName && ![imageName isEqualToString:@""])
	{
		[controller setImageName:imageName linkedUrl:url];
	}
	else
	{
		[controller setImageType:@"achievement_definitions" imageId:@"game_icon" linkedUrl:url];
		[controller setImageUrl:[OpenFeint localGameProfileInfo].iconUrl defaultImage:nil];
	}

	[controller setDismissDashboardWhenSent:YES];
	NSArray* controllers = [NSArray arrayWithObject:controller];
	[OpenFeint launchDashboardWithDelegate:nil tabControllerName:OpenFeintDashBoardTabNowPlaying andControllers:controllers];
}

@end