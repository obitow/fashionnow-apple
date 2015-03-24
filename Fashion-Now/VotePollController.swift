//
//  VotePollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class VotePollController: UIViewController, PollInteractionDelegate, PollLoadDelegate {

    private var polls = ParsePollList(type: .VotePublic)

    private weak var pollController: PollController!

    // Navigation bar items
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!

    // Vote buttons
    private var voteButtons: [UIButton]!
    @IBOutlet weak var leftVoteButton: UIButton!
    @IBOutlet weak var rightVoteButton: UIButton!
    // Press actions
    @IBAction func voteButtonWillBePressed(sender: UIButton) {
        setCleanInterface(false, animated: true)
    }
    @IBAction func voteButtonPressed(sender: UIButton) {
        pollController.animateHighlight(index: find(voteButtons, sender)! + 1, source: .Extern)
    }

    // Clean interface
    private var cleanInterface: Bool = false {
        didSet {
            for voteButton in voteButtons {
                voteButton.alpha = (cleanInterface ? 0.25 : 1)
            }
        }
    }
    private func setCleanInterface(cleanInterface: Bool, animated: Bool) {
        if cleanInterface != self.cleanInterface {
            if animated {
                UIView.animateWithDuration(0.15) { () -> Void in
                    self.cleanInterface = cleanInterface
                }
            } else {
                self.cleanInterface = cleanInterface
            }
        }
    }

    // Empty polls interface
    @IBOutlet weak var emptyInterface: UIView!

    // Loading interface
    @IBOutlet weak var loadingInterface: UIView!
    private func setLoadingInterfaceHidden(hidden: Bool, animated: Bool, completion: ((finished: Bool) -> Void)? = nil) {
        if hidden != loadingInterface.hidden && animated {
            loadingInterface.hidden = false
            UIView.animateWithDuration(0.15, animations: { () -> Void in
                // animations
                self.loadingInterface.alpha = (hidden ? 0 : 1)
            }, completion: { (finished) -> Void in
                // completion
                self.loadingInterface.hidden = hidden
                completion?(finished: finished)
            })
        } else {
            loadingInterface.hidden = hidden
            loadingInterface.alpha = (hidden ? 0 : 1)
            completion?(finished: true)
        }
    }

    private func showNextPoll() {

        if let nextPoll = self.polls.nextPoll(remove: true) {

            pollController.poll = nextPoll
            // Name
            nameLabel.text = nextPoll.createdBy?.name ?? nextPoll.createdBy?.email ?? NSLocalizedString("UNKNOW_USER", value: "Unknown", comment: "Shown when user has no name or email")
            // Date
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .ShortStyle
            dateFormatter.timeStyle = .ShortStyle
            dateFormatter.doesRelativeDateFormatting = true
            dateLabel.text = dateFormatter.stringFromDate(nextPoll.createdAt)

            // Avatar
            if let unwrappedAuthorFacebookId = nextPoll.createdBy?.facebookId {
                avatarView.setImageWithURL(FacebookHelper.urlForPictureOfUser(id: unwrappedAuthorFacebookId, size: 40), usingActivityIndicatorStyle: .White)
            } else {
                avatarView.image = nil
            }

        } else {

            // Adjust interface for no more polls
            emptyInterface.hidden = false
            setLoadingInterfaceHidden(true, animated: true, completion: nil)
        }
    }

    func loadPollList(notification: NSNotification?) {
        emptyInterface.hidden = true
        setLoadingInterfaceHidden(false, animated: false)
        polls = ParsePollList(type: .VotePublic)
        polls.update(completionHandler: { (success, error) -> Void in

            if error != nil {
                self.showErrorScreen()
                return
            }

            self.showNextPoll()
        })
    }

    // MARK: UIViewController
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let identifier = segue.identifier {
            switch identifier {
                
            case "Poll Controller":
                pollController = segue.destinationViewController as PollController
                
            default:
                return
            }
        }
    }

    private func showErrorScreen() {
        // TODO: Error Screen
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.tabBarItem.selectedImage = UIImage(named: "TabBarIconVoteSelected")

        pollController.interactDelegate = self
        pollController.loadDelegate = self

        voteButtons = [leftVoteButton, rightVoteButton]
        for voteButton in voteButtons {
            voteButton.tintColor = UIColor.fn_tint(alpha: 0.5)
        }

        // Initializes poll list and adjusts interface
        loadPollList(nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadPollList:", name: LoginChangedNotificationName, object: nil)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        PFAnalytics.fn_trackScreenShowInBackground("Vote: Main", block: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: PollControllerDelegate

    func pollLoaded(pollController: PollController) {
        setLoadingInterfaceHidden(true, animated: false)
    }

    func pollLoadFailed(pollController: PollController, error: NSError) {
        // TODO: Failed
    }

    func pollInteracted(pollController: PollController) {
        setCleanInterface(true, animated: true)
    }

    func pollWillHighlight(pollController: PollController, index: Int, source: PollController.HighlightSource) {

        var voteMethod = "Button"
        if source == .DoubleTap {
            voteMethod = "Double Tap"
        } else if source == .Drag {
            voteMethod = "Drag"
        }
        PFAnalytics.fn_trackVoteMethodInBackground(voteMethod)

        let vote = ParseVote(user: ParseUser.currentUser())
        vote.pollId = pollController.poll.objectId
        vote.vote = index
        vote.saveEventually(nil)
    }

    func pollDidHighlight(pollController: PollController) {
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "showLoadingInterfaceAndNextPoll:", userInfo: nil, repeats: false).fire()
    }
    func showLoadingInterfaceAndNextPoll(sender: NSTimer?) {
        setLoadingInterfaceHidden(false, animated: true) { (finished) -> Void in
            self.showNextPoll()
        }
    }
}
