/**
 * Created by bio1712 for love2d
 *
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 **/

// LOVE
#include "common/config.h"
#include "Ads.h"

#if defined(LOVE_MACOSX)
#include <CoreServices/CoreServices.h>
#elif defined(LOVE_IOS)
#include "common/ios.h"
#elif defined(LOVE_LINUX) || defined(LOVE_ANDROID)
#include <signal.h>
#include <sys/wait.h>
#include <errno.h>
#elif defined(LOVE_WINDOWS)
#include "common/utf8.h"
#include <shlobj.h>
#include <shellapi.h>
#pragma comment(lib, "shell32.lib")
#endif
#if defined(LOVE_ANDROID)
#include "common/android.h"
#elif defined(LOVE_LINUX)
#include <spawn.h>
#endif

// SDL

//Objc
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <AudioToolbox/AudioServices.h>

#include <GoogleMobileAds/GoogleMobileAds.h>

#import "ads/VideoDelegate.h"

#import "ads/InterstitialDelegate.h"

namespace love
{
namespace ads
{
	
	
	NSString * testDevice;
	
GADBannerView * bannerView;
	
GADInterstitial *interstitialAd;
InterstitialDelegate *interstitialDel;
	
GADRewardBasedVideoAd *videoAd;
VideoDelegate *videoDel;
	
		
Ads::Ads()
{
	[GADMobileAds configureWithApplicationID:@"INSERT-YOUR-APP-ID-HERE"];
	testDevice = @"INSERT-YOUR-TEST-DEVICE-ID-HERE";
}
	
void Ads::test() const {
	//printf("ADS_TEST\n");
}
	
UIViewController * Ads::getRootViewController()
{
	static auto win = Module::getInstance<window::Window>(Module::M_WINDOW);
	
	
	SDL_Window *window = win-> getWindowObj();
	SDL_SysWMinfo systemWindowInfo;
	SDL_VERSION(&systemWindowInfo.version);
	if ( ! SDL_GetWindowWMInfo(window, &systemWindowInfo)) {
		printf("Error 0\n");
	}
	UIWindow * appWindow = systemWindowInfo.info.uikit.window;
	UIViewController * rootViewController = appWindow.rootViewController;
		
	return rootViewController;
}

void Ads::createBanner(const char *adID, const char *position) {
	
	if (hasBannerBeenCreated) {
		printf("Skipping banner creation! Banner has already been created!\n");
		return;
	}
	
	printf("Creating banner with adID= ");
	printf("%s", adID);
	printf(" position= %s\n",position);

	
	//UIView * myView = [[UIView alloc] initWithFrame: CGRectMake ( 0, 0, 200, 150)];
	CGRect screenRect = [[UIScreen mainScreen] bounds];
	CGFloat screenHeight = screenRect.size.height;
	CGFloat screenWidth = screenRect.size.width;
	
	if (screenWidth > screenHeight)
	{
		bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerLandscape origin:CGPointMake(0,0)];
	}
	else
	{
		bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait origin:CGPointMake(0,0)];
	}
	
	if (strcmp("bottom",position) == 0) {
		[bannerView setFrame:CGRectMake(0,screenHeight-bannerView.frame.size.height, bannerView.frame.size.width, bannerView.frame.size.height)];
	} else {
		[bannerView setFrame:CGRectMake(0, 0, bannerView.frame.size.width, bannerView.frame.size.height)];
	}
	//bannerViewDelegate *bannerDel = [[bannerViewDelegate alloc] init];
	
	//bannerView.delegate = bannerDel;
	
	//if([bannerView.delegate respondsToSelector:@selector(adViewWillPresentScreen:)]) {
	//	[bannerView.delegate adViewWillPresentScreen:bannerView];
	//}
	
	bannerView.adUnitID = @(adID);
	
	
	UIViewController *VC = getRootViewController();
	bannerView.rootViewController = VC;
	
	GADRequest *request = [GADRequest request];
	request.testDevices = @[ testDevice ];
	
	[bannerView loadRequest:request];
	
	hasBannerBeenCreated = true;
}
	

void Ads::hideBanner()
{
	if (hasBannerBeenCreated)
	{
		[bannerView removeFromSuperview];
	}
	else
	{
		printf("Cannot hide banner: No banner has been created yet.\n");
	}
}
	
void Ads::showBanner()
{
	if (hasBannerBeenCreated)
	{
		UIViewController *VC = getRootViewController();
		[VC.view addSubview:bannerView];
	}
	else
	{
		printf("Cannot show banner: No banner has been created yet.\n");
	}
}
	
void Ads::requestInterstitial(const char *adID) {
	
	if (!adID)
	{
		printf("Interstitial ad unit ID is not valid.\n");
		return;
	}
	
	NSString *adUnitID = @(adID);
	interstitialAd = [[GADInterstitial alloc] initWithAdUnitID:adUnitID];
	
	interstitialDel = [[InterstitialDelegate alloc] init];
	
	interstitialAd.delegate = interstitialDel;
	[interstitialDel initProperties];
	
	GADRequest *request = [GADRequest request];
	request.testDevices = @[ testDevice ];
	[interstitialAd loadRequest:request];
	
	return;
}
	
void Ads::showInterstitial()
{
	if (interstitialAd.isReady)
	{
		UIViewController *cont = getRootViewController();
		[interstitialAd presentFromRootViewController:cont];
		printf("Showing interstitial ad\n");
	}
	else
	{
		printf("Cannot show intersitial: Ad is not ready or has not been requested yet.\n");
	}
	
	return;
}

bool Ads::isInterstitialLoaded()
{
	return interstitialAd.isReady;
}
	
void Ads::requestRewardedAd(const char *adID) {
	
	//videoDelegate *videoDel = [[videoDelegate alloc] init];
	videoAd = [[GADRewardBasedVideoAd alloc] init];
	videoDel = [[VideoDelegate alloc] init];
	
	
	GADRequest *request = [GADRequest request];
	request.testDevices = @[ testDevice ];
	NSString *adUnitID = @(adID);
	
	videoAd.delegate = videoDel;
	[videoDel initProperties];
	[videoAd loadRequest:request withAdUnitID:adUnitID];

	return;
}
	
bool Ads::isRewardedAdLoaded()
{
	if (videoAd.isReady)
	{
		return true;
	}
	else
	{
		return false;
	}
		
}
	
void Ads::showRewardedAd()
{
	if (videoAd.isReady)
	{
		UIViewController *cont = getRootViewController();
		[videoAd presentFromRootViewController:cont];
		printf("Showing rewarded ad\n");
	}
	else
	{
		printf("Cannot show rewarded ad: Ad is not ready or has not been requested yet.\n");
	}
	return;
	
}
	
//Private functions for callbacks
	
bool Ads::coreInterstitialError()
{ //Interstitial has failed to load
	if (interstitialDel.interstitialFailedToLoad) {
		interstitialDel.interstitialFailedToLoad = false; //reset property
		return true;
	}
	return false;
}
	
bool Ads::coreInterstitialClosed()
{ //Interstitial has been closed by user
	if (interstitialDel.interstitialDidClose) {
		interstitialDel.interstitialDidClose = false; //reset property
		return true;
	}
	return false;
}
	
bool Ads::coreRewardedAdError()
{ //Video has failed to load
	if (videoDel.rewardedAdFailedToLoad) {
		videoDel.rewardedAdFailedToLoad = false; //reset property
		return true;
	}
	return false;
}
	
bool Ads::coreRewardedAdDidFinish()
{ //Video has finished playing
	if (videoDel.rewardedAdDidFinish)
	{
		videoDel.rewardedAdDidFinish = false; //reset property
		return true;
	}
	return false;
}
	
std::string Ads::coreGetRewardType()
{ //Get reward type
	if (videoDel.rewardType)
	{
		std::string ret = [videoDel.rewardType UTF8String];
		return ret;
	}
	else
	{
		return "???";
	}
}
	
double Ads::coreGetRewardQuantity()
{ //Get reward qty
	if (videoDel.rewardQuantity)
	{
		return videoDel.rewardQuantity;
	}
	else
	{
		return 1.0;
	}
}
	
bool Ads::coreRewardedAdDidStop()
{ //Ad stopped by user
	if (videoDel.rewardedAdDidStop)
	{
		videoDel.rewardedAdDidStop = false; //reset property
		return true;
	}
	return false;
}
		
} // ads
} // love
