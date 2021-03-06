//
//  AppDelegate.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-29.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    /// Called every login or logout
    func loginChanged(notification: NSNotification) {

        // Clear caches
        let imageCache = SDImageCache.sharedImageCache()
        imageCache.clearDisk()
        imageCache.clearMemory()
        PFObject.unpinAllObjectsInBackgroundWithBlock { (succeeded, error) -> Void in
            FNAnalytics.logError(error, location: "AppDelegate: Login Changed Unpin")
        }

        // Register new user ID in installation on login change
        let install = ParseInstallation.currentInstallation()
        let currentUser = ParseUser.current()
        install.userId = currentUser.objectId
        install.saveInBackgroundWithBlock { (succeeded, error) -> Void in
            FNAnalytics.logError(error, location: "AppDelegate: Login Changed Save")
        }

        // Update analytics
        GAI.sharedInstance().defaultTracker.set(kGAIUserId, value: currentUser.objectId)
    }

    /// Updates current installation with default values (included the provided location) and saves.
    private func updateLocation(location: PFGeoPoint?) {
        // Erase badge number, set userID and update location
        let install = ParseInstallation.currentInstallation()
        install.badge = 0
        install.language = NSLocale.currentLocale().localeIdentifier
        install.localization = NSBundle.mainBundle().preferredLocalizations.first
        install.pushVersion = 2
        install.userId = ParseUser.current().objectId
        if let location = location {
            install.location = location
        }
        install.saveInBackgroundWithBlock { (succeeded, error) -> Void in
            FNAnalytics.logError(error, location: "AppDelegate: Location From IP Save")
        }
    }

    // MARK: App lifecycle

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {

        // App basic configuration
        window!.tintColor = UIColor.fn_tint()

        // Parse pre configuration
        ParseInstallation.registerSubclass()
        ParsePhoto.registerSubclass()
        ParsePoll.registerSubclass()
        ParseReport.registerSubclass()
        ParseUser.registerSubclass()
        ParseVote.registerSubclass()
        ParseBlock.registerSubclass()

        // Parse configuration
        Parse.enableLocalDatastore()
        #if DEBUG
            Parse.setApplicationId("AIQ4OyhhFVequZa6eXLCDdEpxu9qE0JyFkkfczWw", clientKey: "4dMOa5Ts1cvKVcnlIv2E4wYudyN7iJoH0gQDxpVy")
        #else
            Parse.setApplicationId("Yiuaalmc4UFWxpLHfVHPrVLxrwePtsLfiEt8es9q", clientKey: "60gioIKODooB4WnQCKhCLRIE6eF1xwS0DwUf3YUv")
        #endif
        ParseUser.enableAutomaticUser()
        
        let currentUser = ParseUser.current()
        
        // Analytics configuration
        var error: NSError?
        GGLContext.sharedInstance().configureWithError(&error)
        #if DEBUG
            GAI.sharedInstance().optOut = true
            GAI.sharedInstance().logger.logLevel = .Verbose
        #else
            GAI.sharedInstance().optOut = !(NSUserDefaults.standardUserDefaults().objectForKey("AnalyticsEnabled") as? Bool ?? true)
        #endif
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.allowIDFACollection = true
        tracker.set(kGAIUserId, value: currentUser.objectId)
        
        // Parse post configuration
        ParseUser.enableRevocableSessionInBackgroundWithBlock { (error) -> Void in
            FNAnalytics.logError(error, location: "AppDelegate: Enable Revocable Session")
        }
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)
        
        // Observe login change and update installation
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loginChanged:", name: LoginChangedNotificationName, object: nil)
        
        // Track app opened
        if application.applicationState != .Background {
            PFAnalytics.trackAppOpenedWithLaunchOptionsInBackground(launchOptions, block: nil)
        }
        
        #if DEBUG
            Crashlytics.sharedInstance().debugMode = true
        #endif
        Fabric.with([Crashlytics()])
        #if DEBUG
            Fabric.sharedSDK().debug = true
        #endif
        
        
        
        
        
        
        
        // FIXME: !!!!!!
        ParseUser.current().saveInBackground()
        Crashlytics.sharedInstance().setUserEmail(currentUser.email)
        Crashlytics.sharedInstance().setUserIdentifier(currentUser.objectId)
        Crashlytics.sharedInstance().setUserName(currentUser.displayName)
        
        
        
        
        
        
        
        
        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {

        // Analytics
        let params = GAIDictionaryBuilder().setCampaignParametersFromUrl(url.absoluteString).build() as [NSObject:AnyObject]
        if !(params[kGAICampaignSource] is NSNull) {
            GAI.sharedInstance().defaultTracker.send(params)
        }

        // Show poll first if it is in the vote list
        if url.scheme == "fashionnowapp" {

            if url.host == "poll" {
                VotePollController.firstPollId = url.lastPathComponent
                return true
            }
        }

        // Facebook
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func applicationDidBecomeActive(application: UIApplication) {

        // Facebook Analytics
        FBSDKAppEvents.activateApp()

        // Start friends cache
        ParseFriendsList.shared.update(false)

        // Clean image cache
        SDImageCache.sharedImageCache().cleanDiskWithCompletionBlock(nil)

        // Get location for Installation
        switch CLLocationManager.authorizationStatus() {
        default:
            // Get aproximate location with https://freegeoip.net/
            NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "https://freegeoip.net/json")!, completionHandler: { (data, response, error) -> Void in
                if FNAnalytics.logError(error, location: "AppDelegate: Location From IP Download") {
                    self.updateLocation(nil)
                    return
                }
                do {
                    let geoInfo = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? [String: AnyObject]
                    let latitude = geoInfo!["latitude"] as? Double
                    let longitude = geoInfo!["longitude"] as? Double
                    if latitude != nil && longitude != nil {
                        self.updateLocation(PFGeoPoint(latitude: latitude!, longitude: longitude!))
                    }
                } catch {
                    if FNAnalytics.logError(error as? NSError, location: "AppDelegate: Location From IP Serialization") {
                        self.updateLocation(nil)
                        return
                    }
                }
            }).resume()
        }
    }

    func applicationDidReceiveMemoryWarning(application: UIApplication) {
        SDImageCache.sharedImageCache().clearMemory()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: Push notifications

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        // Store the deviceToken in the current installation and send it to Parse
        let install = ParseInstallation.currentInstallation()
        install.setDeviceTokenFromData(deviceToken)
        install.saveEventually { (succeeded, error) -> Void in
            FNAnalytics.logError(error, location: "AppDelegate: Register Notification Save")
        }
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        FNAnalytics.logError(error, location: "AppDelegate: Register Notification Fail")
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {

        // Handling push notification for vote
        VotePollController.firstPollId = userInfo["poll"] as? String
        NSNotificationCenter.defaultCenter().postNotificationName(VoteNotificationTappedNotificationName, object: self, userInfo: userInfo)

        if application.applicationState != .Active {
            // The application was just brought from the background to the foreground, so we consider the app as having been "opened by a push notification."
            PFAnalytics.trackAppOpenedWithRemoteNotificationPayloadInBackground(userInfo, block: nil)
        }
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        self.application(application, didReceiveRemoteNotification: userInfo)
        completionHandler(userInfo["poll"] != nil ? .NewData : .NoData)
    }
}