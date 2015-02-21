//
//  AppDelegate.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-29.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {

        // Parse pre configuration
        Parse.enableLocalDatastore()
        ParseCrashReporting.enable()

        // Register subclasses
        // This is because overriding class function "load()" doesn't work on Swift 1.2+
        ParseInstallation.registerSubclass()
        ParsePhoto.registerSubclass()
        ParsePoll.registerSubclass()
        ParseUser.registerSubclass()
        ParseVote.registerSubclass()

        return true
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {

        // App basic configuration
        window?.tintColor = UIColor.defaultTintColor()
        
        // Parse configuration
        Parse.setApplicationId("Yiuaalmc4UFWxpLHfVHPrVLxrwePtsLfiEt8es9q", clientKey: "60gioIKODooB4WnQCKhCLRIE6eF1xwS0DwUf3YUv")
        ParseUser.enableAutomaticUser()
        PFAnalytics.trackAppOpenedWithLaunchOptionsInBackground(launchOptions, block: nil)
        PFFacebookUtils.initializeFacebook()

        // Push notifications
        if application.respondsToSelector("registerUserNotificationSettings:") {
            // Register for Push Notitications, if running iOS 8
            let settings = UIUserNotificationSettings(forTypes:.Alert | .Badge | .Sound, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        } else {
            // Register for Push Notifications before iOS 8
            application.registerForRemoteNotificationTypes(.Alert | .Badge | .Sound)
        }

        // Erase badge number
        ParseInstallation.currentInstallation().badge = 0

        // Verify if current user is valid. If no, clean login caches.
        let currentUser = ParseUser.currentUser()
        if !PFAnonymousUtils.isLinkedWithUser(currentUser) && (currentUser.hasPassword != true || currentUser.facebookId == nil || count(currentUser.facebookId!) <= 0) {
            ParseUser.logOut()
            FBSession.activeSession().closeAndClearTokenInformation()
        }
        currentUser.avatar?.fetchIfNeededInBackgroundWithBlock(nil)

        // Observe login change and update installation
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateInstallationUser:", name: LoginChangedNotificationName, object: nil)
        
        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        return FBAppCall.handleOpenURL(url, sourceApplication: sourceApplication, withSession: PFFacebookUtils.session())
    }

    func applicationDidBecomeActive(application: UIApplication) {
        FBAppCall.handleDidBecomeActiveWithSession(PFFacebookUtils.session())
        FBAppEvents.activateApp()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: Push notifications

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        // Store the deviceToken in the current installation and send it to Parse
        let currentInstallation = ParseInstallation.currentInstallation()
        currentInstallation.setDeviceTokenFromData(deviceToken)
        currentInstallation.saveEventually(nil)
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        PFPush.handlePush(userInfo)
    }

    func updateInstallationUser(notification: NSNotification) {
        // Register user ID in installation on login
        let currentInstallation = ParseInstallation.currentInstallation()
        currentInstallation.userId = (notification.userInfo?["user"] as? ParseUser)?.objectId
        currentInstallation.saveEventually(nil)
    }
}

/// Returns "OK" for English and its variants for other languages
public let LocalizedOKButtonTitle = NSLocalizedString("OK_BUTTON_TITLE", value: "OK" , comment: "Default OK button title for entire app")

extension UIColor {
    
    // MARK: Colors
    
    class func defaultBlackColor(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 27/255.0, green: 27/255.0, blue: 27/255.0, alpha: alpha)
    }
    
    class func defaultDetailColor(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 7/255.0, green: 131/255.0, blue: 123/255.0, alpha: alpha)
    }
    
    class func defaultLightColor(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 10/255.0, green: 206/255.0, blue: 188/255.0, alpha: alpha)
    }
    
    class func defaultDarkColor(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 6/255.0, green: 137/255.0, blue: 132/255.0, alpha: alpha)
    }
    
    class func defaultTintColor(alpha: CGFloat = 1) -> UIColor {
        return defaultDetailColor(alpha: alpha)
    }

    class func defaultDestructiveColor(alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: 1, green: 102/255.0, blue: 102/255.0, alpha: alpha)
    }

    class func defaultErrorColor(alpha: CGFloat = 1) -> UIColor {
        return redColor().colorWithAlphaComponent(alpha)
    }

    class func randomColor(alpha: CGFloat = 1) -> UIColor{
        return UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: alpha)
    }
    
    // MARK: Helpers

    /**
    :returns: An image with this color and the specified size
    */
    func image(size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        
        UIGraphicsBeginImageContext(size);
        let context = UIGraphicsGetCurrentContext();
        
        CGContextSetFillColorWithColor(context, CGColor);
        CGContextFillRect(context, CGRect(origin: CGPointZero, size: size));
        
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image
    }
}

/// UIButton that gets the background image and apply template rendering mode
class TemplateBackgroundButton: UIButton {

    override func awakeFromNib() {
        super.awakeFromNib()

        setBackgroundImage(backgroundImageForState(.Normal), forState: .Normal)
    }

    override func setBackgroundImage(image: UIImage?, forState state: UIControlState) {
        super.setBackgroundImage(image?.imageWithRenderingMode(.AlwaysTemplate), forState: state)
    }
}
