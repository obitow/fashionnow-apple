//
//  VotePollController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-23.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class VotePollController: UIViewController {
    
    var photoComparisonController: PhotoComparisonController!

    @IBOutlet weak var navBarTopMargin: NSLayoutConstraint!
    @IBOutlet weak var navBar: UINavigationBar!
    
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var tagsLabel: UILabel!
    weak var tagsGradientBackgroundLayer: CAGradientLayer!
    
    // MARK: UIViewController
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let identifier = segue.identifier {
            
            switch identifier {
                
            case "Photo Comparison Controller":
                photoComparisonController = segue.destinationViewController as PhotoComparisonController
                
            default:
                return
            }
        }
    }
    
    // MARK: Rotation

    override func supportedInterfaceOrientations() -> Int {
        
        var supportedInterfaceOrientations = UIInterfaceOrientationMask.AllButUpsideDown
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            supportedInterfaceOrientations = UIInterfaceOrientationMask.All
        }
        return Int(supportedInterfaceOrientations.rawValue)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        navBarTopMargin.constant = (rootController!.cleanInterface ? -navBar.frame.height : 0)
        
//        var tagsGradientBackgroundLayerFrame = tagsGradientBackgroundLayer.superlayer.bounds
//        tagsGradientBackgroundLayerFrame.size.width *= 1.5
//        tagsGradientBackgroundLayerFrame.size.height *= 1.4
//        tagsGradientBackgroundLayer.frame = tagsGradientBackgroundLayerFrame
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rootController?.delegate = self
        
        avatarView.layer.cornerRadius = 20
        avatarView.layer.masksToBounds = true
        
//        let gradientLayer = CAGradientLayer()
//        gradientLayer.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
//        gradientLayer.colors = [UIColor(white: 0, alpha: 0.25).CGColor, UIColor(white: 0, alpha: 0.2).CGColor, UIColor(white: 0, alpha: 0).CGColor]
//        tagsLabel.superview?.layer.insertSublayer(gradientLayer, atIndex: 0)
//        tagsLabel.superview?.backgroundColor = nil
//        tagsGradientBackgroundLayer = gradientLayer
        
        photoComparisonController.mode = .Vote
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        rootController?.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        var query: PFQuery = PFQuery(className: Poll.parseClassName())
        query.includeKey("photos")
        query.includeKey("createdBy")
        query.orderByDescending("createdAt")
        
        query.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in
            
            let poll = object as Poll
            self.photoComparisonController.poll = poll
            
            // Name
            self.nameLabel.text = poll.createdBy?.username
            // Date
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .ShortStyle
            dateFormatter.timeStyle = .ShortStyle
            dateFormatter.doesRelativeDateFormatting = true
            self.dateLabel.text = dateFormatter.stringFromDate(poll.createdAt)
        }
    }
}