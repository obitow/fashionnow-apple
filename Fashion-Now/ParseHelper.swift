//
//  ParseHelper.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-19.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

let ParseObjectCreatedAtKey = "createdAt"
let ParseObjectUpdatedAtKey = "updatedAt"
let ParseObjectIdKey = "objectId"

let ParseQueryLimit = 1000

// MARK: - Installation class

let ParseInstallationLocationKey = "location"
let ParseInstallationUserIdKey = "userId"

class ParseInstallation: PFInstallation, PFSubclassing {

    var location: PFGeoPoint? {
        get {
            return self[ParseInstallationLocationKey] as? PFGeoPoint
        }
        set {
            self[ParseInstallationLocationKey] = newValue ?? NSNull()
        }
    }

    var userId: String? {
        get {
            return self[ParseInstallationUserIdKey] as? String
        }
        set {
            self[ParseInstallationUserIdKey] = newValue ?? NSNull()
        }
    }
}

// MARK: - User class

let ParseUserAvatarImageKey = "avatarImage"
let ParseUserBirthdayKey = "birth"
let ParseUserFacebookIdKey = "facebookId"
let ParseUserGenderKey = "gender"
let ParseUserHasPassword = "hasPassword"
let ParseUserLocationKey = "location"
let ParseUserNameKey = "name"

private let dateFormat = "yyyy-MM-dd"

class ParseUser: PFUser, PFSubclassing {

//    override class func logOut() {
//        superclass()!.logOut()
//        FBSDKSession.activeSession().closeAndClearTokenInformation()
//    }

    var avatarImage: PFFile? {
        get {
            return self[ParseUserAvatarImageKey] as? PFFile
        }
        set {
            self[ParseUserAvatarImageKey] = newValue ?? NSNull()
        }
    }

    func avatarURL(size: Int? = nil) -> NSURL? {
        if let unwrappedAvatarPath = avatarImage?.url {
            return NSURL(string: unwrappedAvatarPath)
        } else if let unwrappedFacebookId = facebookId {
            return FacebookHelper.urlForPictureOfUser(id: unwrappedFacebookId, size: size)
        }
        return nil
    }

    /// Returns current date if no birthday provided
    var birthday: NSDate? {
        get {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = dateFormat
            return dateFormatter.dateFromString(self[ParseUserBirthdayKey] as? String ?? "")
        }
        set {
            if newValue == nil {
                self[ParseUserBirthdayKey] = NSNull()
                return
            }
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = dateFormat
            self[ParseUserBirthdayKey] = dateFormatter.stringFromDate(newValue!)
        }
    }

    var facebookId: String? {
        get {
            return self[ParseUserFacebookIdKey] as? String
        }
        set {
            self[ParseUserFacebookIdKey] = newValue ?? NSNull()
        }
    }

    var gender: String? {
        get {
            return self[ParseUserGenderKey] as? String
        }
        set {
            self[ParseUserGenderKey] = newValue ?? NSNull()
        }
    }

    var hasPassword: Bool? {
        get {
            return self[ParseUserHasPassword] as? Bool
        }
        set {
            self[ParseUserHasPassword] = newValue ?? NSNull()
        }
    }

    var location: String? {
        get {
            return self[ParseUserLocationKey] as? String
        }
        set {
            self[ParseUserLocationKey] = newValue ?? NSNull()
        }
    }

    var name: String? {
        get {
            return self[ParseUserNameKey] as? String
        }
        set {
            self[ParseUserNameKey] = newValue ?? NSNull()
        }
    }

    // MARK: Helper methods

    var isValid: Bool {
        if PFAnonymousUtils.isLinkedWithUser(self) {
            return true
        } else if PFFacebookUtils.isLinkedWithUser(self) && !(facebookId?.fn_count > 0) {
            return false
        } else if hasPassword != true || email?.isEmail() != true {
            return false
        }
        return true
    }
}

// MARK: - Photo class

let ParsePhotoImageKey = "image"
let ParsePhotoUserIdKey = "userId"

class ParsePhoto: PFObject, PFSubclassing {

    class func parseClassName() -> String {
        return "Photo"
    }

    convenience init(user: ParseUser) {
        self.init()
        let defaultACL = PFACL(user: user)
        defaultACL.setPublicReadAccess(true)
        ACL = defaultACL
        userId = user.objectId
    }

    var image: PFFile? {
        get {
            return self[ParsePhotoImageKey] as? PFFile
        }
        set {
            self[ParsePhotoImageKey] = newValue ?? NSNull()
        }
    }

    var userId: String? {
        get {
            return self[ParsePhotoUserIdKey] as? String
        }
        set {
            self[ParsePhotoUserIdKey] = newValue ?? NSNull()
        }
    }

    // MARK: Helper methods

    var isValid: Bool {
        return image != nil
    }
}

// MARK: - Poll class

let ParsePollCaptionKey = "caption"
let ParsePollCreatedByKey = "createdBy"
let ParsePollPhotosKey = "photos"
let ParsePollUserIdsKey = "userIds"
let ParsePollVersionKey = "version"

public class ParsePoll: PFObject, PFSubclassing {

    public class func parseClassName() -> String {
        return "Poll"
    }
    
    convenience init(user: ParseUser) {
        self.init()
        let defaultACL = PFACL(user: user)
        defaultACL.setPublicReadAccess(true)
        ACL = defaultACL
        createdBy = user
        version = 1
    }

    var caption: String? {
        get {
            return self[ParsePollCaptionKey] as? String
        }
        set {
            self[ParsePollCaptionKey] = newValue ?? NSNull()
        }
    }

    var createdBy: ParseUser? {
        get {
            return self[ParsePollCreatedByKey] as? ParseUser
        }
        set {
            self[ParsePollCreatedByKey] = newValue ?? NSNull()
        }
    }

    var photos: [ParsePhoto]? {
        get {
            return self[ParsePollPhotosKey] as? [ParsePhoto]
        }
        set {
            self[ParsePollPhotosKey] = newValue ?? NSNull()
        }
    }

    var userIds: [String]? {
        get {
            return self[ParsePollUserIdsKey] as? [String]
        }
        set {
            self[ParsePollUserIdsKey] = newValue ?? NSNull()
        }
    }

    var version: NSNumber? {
        get {
            return self[ParsePollVersionKey] as? NSNumber
        }
        set {
            self[ParsePollVersionKey] = newValue ?? NSNull()
        }
    }

    // MARK: Helper methods

    var isValid: Bool {
        if photos == nil {
            return false
        }
        for photo in photos! {
            if photo.isValid != true {
                return false
            }
        }
        return createdBy != nil
    }
}

class ParsePollList: Printable, DebugPrintable {

    // It there is more than one type of not vote, algorithm must change
    /// Type of poll list
    enum Type {
        /// Polls uploaded by the current user
        case Mine
        /// Public polls from everyone, except the ones voted by the current user
        case VotePublic
    }

    // If list is currently downloading content
    private(set) var downloading = false
    private var lastUpdate: NSDate?
    /// Minimum time to update again, in seconds
    private let updateLimitTime: NSTimeInterval = -5 // Needs to be negative
    private var polls = [ParsePoll]()
    private var pollsAreRemote = false
    // Type of list
    let type: Type

    /// Return new query by type of list
    private var pollQuery: PFQuery {
        let currentUser = ParseUser.currentUser()
        let query = PFQuery(className: ParsePoll.parseClassName())
            .includeKey(ParsePollCreatedByKey)
            .includeKey(ParsePollPhotosKey)
            .orderByDescending(ParseObjectCreatedAtKey)
        switch type {
        case .Mine:
            return query.whereKey(ParsePollCreatedByKey, equalTo: currentUser)
        case .VotePublic:
            if !PFAnonymousUtils.isLinkedWithUser(currentUser) {
                let votesByMeQuery = PFQuery(className: ParseVote.parseClassName())
                    .orderByDescending(ParseObjectCreatedAtKey)
                    .whereKey(ParseVoteByKey, equalTo: currentUser)
                votesByMeQuery.limit = ParseQueryLimit
                query.whereKey(ParseObjectIdKey, doesNotMatchKey: ParseVotePollIdKey, inQuery: votesByMeQuery)
            }
            return query.whereKey(ParsePollCreatedByKey, notEqualTo: currentUser)
        }
    }

    init(type: Type) {
        self.type = type
    }

    /// Type of update request
    enum UpdateType {
        /// Download newer polls
        case Newer
        /// Download older polls
        case Older
    }

    /// Return next poll (generally to vote) and optionally, remove it from the list
    func nextPoll(#remove: Bool) -> ParsePoll? {

        if polls.count > 0 {
            let nextPoll = polls[0]
            if remove {
                polls.removeAtIndex(0)
            }
            return nextPoll
        }
        return nil
    }

    /// Cache the completion handler from update method and use in the finish method
    private var completionHandler: PFBooleanResultBlock?

    /// Updates (or downloads for the first time) the poll list. It returns true in the completion handler if there is new polls added to the list.
    func update(type: UpdateType = .Newer, completionHandler: PFBooleanResultBlock) {

        if downloading {

            // Already downloading. Just return error.
            completionHandler(false, NSError(fn_code: .Busy))
            
        } else if lastUpdate?.timeIntervalSinceNow > updateLimitTime {

            // Tried to update too early. Just return error.
            completionHandler(false, NSError(fn_code: .RequestTooOften))

        } else if Reachability.reachabilityForInternetConnection().isReachable() {

            // Online. Update polls list (or download it for the first time).

            // Configure request
            let query = pollQuery
            if pollsAreRemote {
                switch type {
                case .Newer:
                    if let unwrappedFirstPoll = polls.first {
                        query.whereKey(ParseObjectCreatedAtKey, greaterThan: unwrappedFirstPoll.createdAt)
                    }
                case .Older:
                    if let unwrappedLastPoll = polls.last {
                        query.whereKey(ParseObjectCreatedAtKey, lessThan: unwrappedLastPoll.createdAt)
                    }
                }
            }

            // Start download
            downloading = true
            self.completionHandler = completionHandler
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                var error: NSError?

                // Save user if needed
                let currentUser = ParseUser.currentUser()
                if currentUser.isDirty() {
                    currentUser.save(&error)
                    if error != nil {
                        self.finish(false, error: error)
                        return
                    }
                }

                var unwrappedNewPolls: [ParsePoll]! = query.findObjects(&error) as? [ParsePoll] // FIXME: Swift 1.2
                if error == nil && unwrappedNewPolls != nil && unwrappedNewPolls.count > 0 {

                    // Remove already voted polls only if type is one of the vote types
                    if self.type != .Mine {

                        // Collect new polls IDs
                        var newPollsIds = [String]()
                        for poll in unwrappedNewPolls {
                            newPollsIds.append(poll.objectId)
                        }

                        // Find votes on these new polls
                        let myVotesQuery = PFQuery(className: ParseVote.parseClassName())
                            .whereKey(ParseVotePollIdKey, containedIn: newPollsIds)
                            .whereKey(ParseVoteByKey, equalTo: currentUser)
                        myVotesQuery.limit = ParseQueryLimit
                        let myVotes = myVotesQuery.findObjects(&error) as? [ParseVote]
                        if error != nil {
                            self.finish(false, error: error)
                            return
                        }
                        if myVotes?.count >= unwrappedNewPolls.count {
                            // All new polls are voted. Just return error.
                            self.finish(false, error: NSError(fn_code: .NothingNew))
                            return
                        }
                        if myVotes?.count > 0 {
                            // Collect already voted polls IDs
                            var myVotesPollIds = [String]()
                            for vote in myVotes! {
                                myVotesPollIds.append(vote.pollId!)
                            }
                            // Remove the ones already voted
                            var notVotedNewPolls = [ParsePoll]()
                            for newPoll in unwrappedNewPolls {
                                if find(myVotesPollIds, newPoll.objectId) == nil {
                                    notVotedNewPolls.append(newPoll)
                                }
                            }
                            unwrappedNewPolls = notVotedNewPolls
                        }
                    }

                    if self.pollsAreRemote {
                        // Insert before or after depending on type of update
                        switch type {
                        case .Newer:
                            self.polls = unwrappedNewPolls + self.polls
                        case .Older:
                            self.polls += unwrappedNewPolls
                        }

                    } else {
                        // If this is first remote update, replace entire list
                        self.polls = unwrappedNewPolls
                        self.pollsAreRemote = true
                    }

                    // Cache polls and return
                    PFObject.pinAllInBackground(unwrappedNewPolls, block: nil)
                    self.finish(true, error: error)

                } else {

                    // Download error or no more polls
                    self.finish(false, error: error ?? NSError(fn_code: .NothingNew))
                }
            }

        } else if polls.count > 0 {

            // Offline but polls list is not empty. Just return error.
            completionHandler(false, NSError(fn_code: .ConnectionLost))

        } else {

            // Offline. Fill with cached polls if available.

            // Configure request
            let query = pollQuery.fromLocalDatastore()
            query.limit = ParseQueryLimit

            // Start download
            downloading = true
            query.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                self.downloading = false

                let unwrappedCachedPolls: [ParsePoll]! = objects as? [ParsePoll]
                if unwrappedCachedPolls != nil && unwrappedCachedPolls.count > 0 { // FIXME: Swift 1.2
                    self.polls = unwrappedCachedPolls
                    completionHandler(true, error)
                } else {
                    completionHandler(false, error ?? NSError(fn_code: .NoCache))
                }
            })
        }
    }

    /// Helper method to update
    private func finish(success: Bool, error: NSError!) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.downloading = false
            self.lastUpdate = NSDate()
            self.completionHandler?(success, error)
            self.completionHandler = nil
        })
    }

    /// Remove poll by object
    func removePoll(poll: ParsePoll) -> Int? {
        if let index = find(polls, poll) {
            polls.removeAtIndex(index)
            return index
        }
        return nil
    }

    // MARK: Array simulation

    var count: Int {
        return polls.count
    }

    var description: String {
        return polls.description
    }

    var debugDescription: String {
        return polls.debugDescription
    }

    subscript(index: Int) -> ParsePoll? {
        return index < polls.count ? polls[index] : nil
    }
}

// MARK: - Vote class

let ParseVoteByKey = "voteBy"
let ParseVotePollIdKey = "pollId"
let ParseVoteVoteKey = "vote"

class ParseVote: PFObject, PFSubclassing {

    class func parseClassName() -> String {
        return "Vote"
    }

    convenience init(user: ParseUser) {
        self.init()
        let defaultACL = PFACL()
        defaultACL.setPublicReadAccess(true)
        ACL = defaultACL
        voteBy = user
    }

    var pollId: String? {
        get {
            return self[ParseVotePollIdKey] as? String
        }
        set {
            self[ParseVotePollIdKey] = newValue ?? NSNull()
        }
    }

    var vote: NSNumber? {
        get {
            return self[ParseVoteVoteKey] as? NSNumber
        }
        set {
            self[ParseVoteVoteKey] = newValue ?? NSNull()
        }
    }

    var voteBy: ParseUser? {
        get {
            return self[ParseVoteByKey] as? ParseUser
        }
        set {
            self[ParseVoteByKey] = newValue ?? NSNull()
        }
    }

    // MARK: Helper methods

    var isValid: Bool {
        return pollId?.fn_count > 0 && vote != nil && voteBy != nil
    }
}

// MARK: - Report class

let ParseReportCommentKey = "comment"
let ParseReportPollIdKey = "pollId"
let ParseReportUserKey = "user"

class ParseReport: PFObject, PFSubclassing {

    class func parseClassName() -> String {
        return "Report"
    }

    convenience init(user: ParseUser) {
        self.init()
        let defaultACL = PFACL(user: user)
        defaultACL.setPublicReadAccess(true)
        ACL = defaultACL
        self.user = user
    }

    var comment: String? {
        get {
            return self[ParseReportCommentKey] as? String
        }
        set {
            self[ParseReportCommentKey] = newValue ?? NSNull()
        }
    }

    var pollId: String? {
        get {
            return self[ParseReportPollIdKey] as? String
        }
        set {
            self[ParseReportPollIdKey] = newValue ?? NSNull()
        }
    }

    var user: ParseUser? {
        get {
            return self[ParseReportUserKey] as? ParseUser
        }
        set {
            self[ParseReportUserKey] = newValue ?? NSNull()
        }
    }
}

// MARK: - File

extension PFFile {

    convenience init(fn_imageData data: NSData) {
        self.init(name: "image.jpg", data: data, contentType: "image/jpeg")
    }
}

// MARK: - Analytics

enum ErrorLocation: Int {
    case AppDelegateLocationFromIPDownload = 0
    case AppDelegateLocationFromIPSerialization = 1
    case AppDelegateLocationFromIPSave = 2
    case AppDelegateLoginChangedUnpin = 3
    case AppDelegateLoginChangedSave = 4
    case AppDelegateRegisterNotificationSave = 5
    case AppDelegateEnableRevocableSession = 18
    case PhotoControllerImageDownload = 6
    case PhotoControllerImageSave = 7
    case PhotoControllerAddToCameraRoll = 8
    case VoteControllerHandle = 9
    case VoteControllerLoadList = 10
    case VoteControllerPollLoadFail = 11
    case VoteControllerVoteSave = 12
    case PostControllerCacheFriendsFacebookRequest = 13
    case PostControllerCacheFriendsQuery = 14
    case FriendsListControllerSendPoll = 15
    case MeControllerLogOut = 23
    case ResultControllerDeletePoll = 16
    case ResultControllerLoadResults = 17
    case LoginControllerFacebookLogin = 19
    case LoginControllerPasswordLogin = 20
    case LoginControllerResetPassword = 21
    case SignupControllerSaveUser = 22
}

extension PFAnalytics {

    class func fn_trackErrorInBackground(error: NSError, location: ErrorLocation) {
        trackEventInBackground("Error", dimensions: ["Domain": error.domain, "Code": "\(error.code)", "Location": "\(location.rawValue)"], block: nil)
    }

    class func fn_trackPostInBackground(imageSource: String, block: PFBooleanResultBlock! = nil) {
        trackEventInBackground("Post", dimensions: ["Source": imageSource], block: block)
    }

    class func fn_trackScreenInBackground(identifier: String, block: PFBooleanResultBlock! = nil) {
        trackEventInBackground("Screen", dimensions: ["Name": identifier], block: block)
    }

    class func fn_trackVote(vote: NSNumber, method: String, block: PFBooleanResultBlock! = nil) {
        trackEventInBackground("Vote", dimensions: ["Vote": "\(vote)", "Method": method], block: block)
    }
}