//
//  PostPollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class PostPollController: UIViewController, PollControllerDelegate, UITextFieldDelegate {

    // Interface elements
    @IBOutlet weak var textField: UITextField!
    private weak var pollController: PollController!

    // Friends list
    weak var delegate: PostPollControllerDelegate?
    private var cachedFriendsList: [ParseUser]?

    @IBAction func pollControllerTapped(sender: AnyObject) {
        textField.resignFirstResponder()
    }

    func clean() {
        navigationItem.rightBarButtonItem?.enabled = false
        textField.text = nil
        pollController.poll = ParsePoll(user: ParseUser.currentUser())
    }

    func cacheFriendsList() {
        
        FBRequestConnection.startForMyFriendsWithCompletionHandler { (requestConnection, object, error) -> Void in

            if error != nil {
                NSLog("Friends list download error: \(error.localizedDescription)")
                self.delegate?.postPollControllerDidFailDownloadFriendsList(error)
                return
            }

            // Get list of IDs from friends
            var friendsFacebookIds = [String]()
            if let friendsFacebook = object["data"] as? [[String:String]] {

                for friendFacebook in friendsFacebook {
                    friendsFacebookIds.append(friendFacebook["id"]!)
                }

                // Get parse users from Facebook friends
                let friendsQuery = PFQuery(className: ParseUser.parseClassName())
                friendsQuery.whereKey(ParseUserFacebookIdKey, containedIn: friendsFacebookIds)
                friendsQuery.findObjectsInBackgroundWithBlock { (objects, error) -> Void in

                    self.cachedFriendsList = (objects as? [ParseUser]) ?? []
                    self.cachedFriendsList!.sort({$0.name < $1.name})
                    self.delegate?.postPollControllerDidFinishDownloadFriendsList(self.cachedFriendsList!)
                }
            } else {
                self.delegate?.postPollControllerDidFailDownloadFriendsList(nil)
            }
        }
    }
    
    // MARK: UIViewController
    
    override func needsLogin() -> Bool {
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let identifier = segue.identifier {
            
            switch identifier {
                
            case "Poll Controller":
                pollController = segue.destinationViewController as PollController

            case "Friends List":
                textField.resignFirstResponder()
                pollController.poll.caption = textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                let friendsListController = segue.destinationViewController as FriendsListTableController
                friendsListController.friendsList = cachedFriendsList
                friendsListController.poll = pollController.poll
                friendsListController.postPollController = self

            default:
                return
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.tabBarItem.selectedImage = UIImage(named: "TabBarIconPostSelected")

        textField.delegate = self
        textField.frame.size.width = view.bounds.size.width
        pollController.delegate = self

        cacheFriendsList()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        PFAnalytics.fn_trackScreenShowInBackground("Post: Main", block: nil)
    }

    // MARK: PollControllerDelegate
    
    func pollController(pollController: PollController, didEditPoll poll: ParsePoll) {
        navigationItem.rightBarButtonItem?.enabled = poll.isValid
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}

protocol PostPollControllerDelegate: class {

    func postPollControllerDidFinishDownloadFriendsList(friendsList: [ParseUser])
    func postPollControllerDidFailDownloadFriendsList(error: NSError!)
}