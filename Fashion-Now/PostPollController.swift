//
//  PostPollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

// Tutorial
private let tutorialShownKey = "tutorialPost1"
private var tutorialShown = NSUserDefaults.standardUserDefaults().boolForKey(tutorialShownKey) {
    didSet {
        NSUserDefaults.standardUserDefaults().setBool(tutorialShown, forKey: tutorialShownKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}

class PostPollController: FNViewController, UITextFieldDelegate {

    // Interface elements
    private var textField: UITextField {
        return navigationItem.titleView as! UITextField
    }
    private weak var pollController: PollController!

    // Interface for when user has no email
    @IBOutlet weak var noEmailInterface: UIView!

    // Interface for when user is not verified
    @IBOutlet weak var refreshInterface: UIView!
    @IBAction func resendVerification(sender: UIButton) {

        if fn_isOffline() {
            return
        }

        PFCloud.callFunctionInBackground("resendVerification", withParameters: nil) { (result, error) -> Void in
            if FNAnalytics.logError(error, location: "Post: Resend Verification Email") {
                FNToast.show(title: NSLocalizedString("PostPollController.resendVerification.errorTitle", value: "Email not sent", comment: "Trying to resend a verification email"), message: NSLocalizedString("PostPollController.resendVerification.errorMessage", value: "Please, try again later.", comment: "Trying to resend a verification email"), type: .Error)
            } else {
                FNToast.show(title: NSLocalizedString("PostPollController.resendVerification.confirmTitle", value: "Email sent", comment: "Trying to resend a verification email"), message: NSLocalizedString("PostPollController.resendVerification.confirmTitle", value: "Check your inbox", comment: "Trying to resend a verification email"))
            }
        }
    }
    @IBAction func alreadyVerified(sender: UIButton) {

        if fn_isOffline() {
            return
        }

        let activityIndicator = refreshInterface.fn_setLoading(background: UIColor.fn_white(0.5))
        ParseUser.current().fetchInBackgroundWithBlock({ (user, error) -> Void in
            activityIndicator.removeFromSuperview()

            if FNAnalytics.logError(error, location: "Post: Verify Email Fetch") {
                FNToast.show(title: NSLocalizedString("PostPollController.alreadyVerified.errorTitle", value: "An error occurred", comment: "Trying to verify email"), message: NSLocalizedString("PostPollController.alreadyVerified.errorMessage", value: "Please, try again later.", comment: "Trying to verify email"), type: .Error)

            } else if (user as! ParseUser).emailVerified {
                // User has verified the email
                self.view.fn_transition(true, changes: { () -> Void in
                    self.refreshInterface.removeFromSuperview()
                    self.textField.enabled = true
                    self.navigationItem.rightBarButtonItem!.enabled = true
                })

            } else {
                // User hasn't verified the email
                FNToast.show(title: NSLocalizedString("PostPollController.emailMissing.errorTitle", value: "You didn't vefied your email", comment: "Trying to send poll without email"), type: .Error)
            }
        })
    }

    @IBAction func pollControllerTapped(sender: UITapGestureRecognizer) {
        textField.resignFirstResponder()
    }

    func clean() {
        navigationController!.popToRootViewControllerAnimated(true)
        navigationItem.rightBarButtonItem!.enabled = false
        textField.text = nil
        pollController.poll = ParsePoll(user: ParseUser.current())
    }
    
    // MARK: UIViewController
    
    override func needsLogin() -> Bool {
        return true
    }

    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        textField.resignFirstResponder()

        switch identifier {

        case "Next Step":
            if fn_isOffline() {
                return false
            }
            let poll = pollController.poll
            if poll.isValid {
                if textField.text?.characters.count > 0 {
                    poll.caption = textField.text
                    return true
                } else {
                    let alert = SDCAlertController(title: NSLocalizedString("PostController.noCaptionAlert.title", value: "Poll Without Description", comment: "Shown when user tries to send a invalid without caption"), message: NSLocalizedString("PostController.noCaptionAlert.message", value: "Go further without a description?", comment: "Shown when user tries to send a invalid without caption"), preferredStyle: .Alert)
                    alert.addAction(SDCAlertAction(title: NSLocalizedString("PostController.noCaptionAlert.cancel", value: "Go Back", comment: "Shown when user tries to send a invalid without caption"), style: .Cancel, handler: nil))
                    alert.addAction(SDCAlertAction(title: NSLocalizedString("PostController.noCaptionAlert.next", value: "Go Further", comment: "Shown when user tries to send a invalid without caption"), style: .Default, handler: { (action) -> Void in
                        self.performSegueWithIdentifier(identifier, sender: nil)
                    }))
                    alert.presentWithCompletion(nil)
                    return false
                }
            } else {
                FNToast.show(title: NSLocalizedString("PostController.invalidPollAlert.title", value: "Invalid Poll", comment: "Shown when user tries to send a invalid poll"), message: NSLocalizedString("PostController.invalidPollAlert.message", value: "Choose two photos", comment: "Shown when user tries to send a invalid poll"), type: .Error)
                return false
            }

        default:
            break
        }
        
        return true
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {

            switch identifier {

            case "Poll Controller":
                pollController = segue.destinationViewController as! PollController

            case "Next Step":
                (segue.destinationViewController  as! PostFriendsController).poll = pollController.poll

            default:
                return
            }
        }
    }

    // MARK: Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Interface adjustments
        textField.delegate = self
        textField.frame.size.width = view.bounds.size.width

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "clean", name: LoginChangedNotificationName, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "clean", name: FNPollPostedNotificationName, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let currentUser = ParseUser.current()
        let showRefreshInterface = !currentUser.canPostPoll
        let showNoEmailInterface = showRefreshInterface && currentUser.email?.isEmail() != true

        // Show refresh interface if user cannot post
        if showRefreshInterface {
            if (view.subviews ).indexOf(refreshInterface) == nil {
                refreshInterface.frame = view.bounds
                refreshInterface.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
                view.addSubview(refreshInterface)
            }
        } else {
            refreshInterface.removeFromSuperview()
        }

        // Show no email interface if needed
        if showNoEmailInterface {
            if (view.subviews ).indexOf(noEmailInterface) == nil {
                noEmailInterface.frame = view.bounds
                noEmailInterface.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
                view.addSubview(noEmailInterface)
            }
        } else {
            noEmailInterface.removeFromSuperview()
        }

        if showNoEmailInterface || showRefreshInterface {
            textField.enabled = false
            navigationItem.rightBarButtonItem!.enabled = false
        } else {
            textField.enabled = true
            navigationItem.rightBarButtonItem!.enabled = true
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if !tutorialShown {

            let alertPost = fn_alertController(UIImage(named: "TutorialPost.jpg")!)
            alertPost.addAction(SDCAlertAction(title: FNLocalizedGotItButtonTitle, style: .Recommended, handler: nil))
            alertPost.presentWithCompletion(nil)

            tutorialShown = true
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}