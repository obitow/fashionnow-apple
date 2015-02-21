//
//  LoginEmailController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-12.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class LoginEmailController: UITableViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    @IBAction func loginButtonPressed(sender: UIButton) {
        usernameField.enabled = false
        passwordField.enabled = false
        sender.enabled = false
        navigationItem.hidesBackButton = true
        activityIndicator.startAnimating()
        ParseUser.logInWithUsernameInBackground(usernameField.text, password: passwordField.text) { (user, error) -> Void in
            if user != nil {
                // Successful login
                NSNotificationCenter.defaultCenter().postNotificationName(LoginChangedNotificationName, object: self)
                (self.presentingViewController as! TabBarController).willDismissLoginController()
                self.dismissViewControllerAnimated(true, completion: nil)
            } else {
                UIAlertView(title: nil, message: error.localizedDescription, delegate: nil, cancelButtonTitle: LocalizedOKButtonTitle).show()
                self.usernameField.enabled = true
                self.usernameField.becomeFirstResponder()
                self.passwordField.enabled = true
                sender.enabled = true
                self.navigationItem.hidesBackButton = false
                self.activityIndicator.stopAnimating()
            }
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loginButton.setBackgroundImage(UIColor.defaultTintColor().image(), forState: .Normal)

        let tableViewHeaderHeight = view.bounds.height - 450
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: tableViewHeaderHeight))
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        usernameField.becomeFirstResponder()
    }
}
