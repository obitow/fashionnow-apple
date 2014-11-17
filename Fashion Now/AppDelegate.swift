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

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        // App basic configuration
        window?.tintColor = UIColor.defaultTintColor()
        
        // Parse configuration
        Parse.setApplicationId("Yiuaalmc4UFWxpLHfVHPrVLxrwePtsLfiEt8es9q", clientKey: "60gioIKODooB4WnQCKhCLRIE6eF1xwS0DwUf3YUv")
        PFAnalytics.trackAppOpenedWithLaunchOptionsInBackground(launchOptions, block: nil)
        PFFacebookUtils.initializeFacebook()
        
        // Get current user (or create an anonymous one)
        PFUser.enableAutomaticUser()
        let currentUser = PFUser.currentUser()
        if currentUser.isDirty() {
            currentUser.saveInBackgroundWithBlock(nil)
        }
        
        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        return FBAppCall.handleOpenURL(url, sourceApplication: sourceApplication, withSession: PFFacebookUtils.session())
    }

    func applicationDidBecomeActive(application: UIApplication) {
        FBAppCall.handleDidBecomeActiveWithSession(PFFacebookUtils.session())
    }
}

extension UIColor {
    
    class func defaultTintColor() -> UIColor {
        return defaultTintColor(alpha: 1)
    }

    class func defaultTintColor(#alpha: CGFloat) -> UIColor {
        return UIColor(red: 24.0/255.0, green: 156.0/255.0, blue: 125.0/255.0, alpha: alpha)
    }
    
    func toImage() -> UIImage {
        return toImage(size: CGSize(width: 1, height: 1))
    }

    func toImage(#size: CGSize) -> UIImage {

        UIGraphicsBeginImageContext(size);
        let context = UIGraphicsGetCurrentContext();

        CGContextSetFillColorWithColor(context, CGColor);
        CGContextFillRect(context, CGRect(origin: CGPointZero, size: size));

        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image
    }
}

extension UIStoryboard {

    class func mainStoryboard() -> UIStoryboard {
        return UIStoryboard(name: "Main", bundle: nil)
    }
}
