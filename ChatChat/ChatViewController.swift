//
//  ChatViewController.swift
//  nuschat
//
//  Created by Mike Zhang Xunda on 4/7/17.
//  Copyright © 2017 Mike Zhang Xunda. All rights reserved.
//

import UIKit
import Firebase
import JSQMessagesViewController
import Photos

final class ChatViewController: JSQMessagesViewController {
//  
  // MARK: Properties
    var channelRef: DatabaseReference?
    var channel: Channel? {
        didSet {
            title = channel?.name
        }
    }
    
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    //messages is an array to store the various instances of JSQMessage in your app.
    var messages = [JSQMessage]()
    
    private lazy var messageRef: DatabaseReference = self.channelRef!.child("messages")
    private var newMessageRefHandle: DatabaseHandle?
    
    //Create a Firebase reference that tracks whether the local user is typing.
    private lazy var userIsTypingRef: DatabaseReference = self.channelRef!.child("typingIndicator").child(self.senderId)
    //Store whether the local user is typing in a private property.
    private var localTyping = false
    var isTyping: Bool {
        get{
            return localTyping
        }
        set {
            //Use a computed property to update localTyping and userIsTypingRef each time it’s changed.
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }
    // property holds an DatabaseQuery, which is just like a Firebase reference, except that it’s ordered. You initialize the query by retrieving all users who are typing. This is basically saying, “Hey Firebase, go to the key /typingIndicator and get me all users for whom the value is true.
    private lazy var usersTypingQuery: DatabaseQuery = self.channelRef!.child("typingIndicator").queryOrderedByValue().queryEqual(toValue: true)
    
    lazy var storageRef: StorageReference = Storage.storage().reference(forURL: "gs://nuschat-164315.appspot.com/")
    private let imageURLNotSetKey = "NOTSET"
    private var photoMessageMap = [String: JSQPhotoMediaItem]()
    private var updatedMessageRefHandle: DatabaseHandle?
    
  // MARK: View Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.senderId = Auth.auth().currentUser?.uid
    collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
    collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
    observeMessages()
//    let tapGesture = UITapGestureRecognizer(target:
//        self, action:#selector(tableViewTapped))
//    collectionView.addGestureRecognizer(tapGesture)

  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    observeTyping()
  }
    
    deinit {
        if let refHandle = newMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
        
        if let refHandle = updatedMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
    }
    
  // MARK: Collection view data source (and related) methods
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    //return the number of items in each section; in this case, the number of messages.
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    //To set the colored bubble image for each message
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt
        //retrieve the message.
        indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        //If the message was sent by the local user, return the outgoing image view.
        if message.senderId == senderId {
            return outgoingBubbleImageView
        }else {
            //Otherwise, return the incoming image view.
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            cell.textView?.textColor = UIColor.white
        }else {
            cell.textView?.textColor = UIColor.black
        }
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
        let message = messages[indexPath.item]
        
        // Displaying names above messages
        //Mark: Removing Sender Display Name
        /**
         *  Example on showing or removing senderDisplayName based on user settings.
         *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
         */
//        if defaults.bool(forKey: Setting.removeSenderDisplayName.rawValue) {
//            return nil
//        }
        
//        if message.senderId == self.senderId() {
//            return nil
//        }
        
        return NSAttributedString(string: message.senderDisplayName)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForMessageBubbleTopLabelAt indexPath: IndexPath) -> CGFloat {
        
        /**
         *  Example on showing or removing senderDisplayName based on user settings.
         *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
         */
//        if defaults.bool(forKey: Setting.removeSenderDisplayName.rawValue) {
//            return 0.0
//        }
        
        /**
         *  iOS7-style sender name labels
         */
        let currentMessage = self.messages[indexPath.item]
        
//        if currentMessage.senderId == self.senderId() {
//            return 0.0
//        }
        
        if indexPath.item - 1 > 0 {
            let previousMessage = self.messages[indexPath.item - 1]
            if previousMessage.senderId == currentMessage.senderId {
                return 0.0
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
  
  // MARK: Firebase related methods
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        //Using childByAutoId(), you create a child reference with a unique key.
        let itemRef = messageRef.childByAutoId()
        //Then you create a dictionary to represent the message.
        let messageItem = [
            "senderId": senderId!,
            "senderName": senderDisplayName!,
            "text": text!
        ]
        //Next, you Save the value at the new child location.
        itemRef.setValue(messageItem)
        //You then play the canonical “message sent” sound.
        //JSQSystemSoundPlayer.jsq_playMessageSentSound()
        //Finally, complete the “send” action and reset the input toolbar to empty.
        finishSendingMessage()
        isTyping = false
    }
    
    private func observeMessages() {
        messageRef = channelRef!.child("messages")
        //Start by creating a query that limits the synchronization to the last 25 messages.
        let messageQuery = messageRef.queryLimited(toLast:25)
        
        //listen for new messages being written to the firebase DB
        //Use the .ChildAdded event to observe for every child item that has been added, and will be added, at the messages location.
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) in
            //Extract the messageData from the snapshot.
            let messageData = snapshot.value as! Dictionary<String, String>
            if let id = messageData["senderId"] as String!, let name = messageData["senderName"] as String!, let text = messageData["text"] as String!, text.characters.count > 0 {
                //Call addMessage(withId:name:text) to add the new message to the data source.
                self.addMessage(withId: id, name: name, text: text)
                //Inform JSQMessagesViewController that a message has been received.
                self.finishReceivingMessage()
            }else if let id = messageData["senderId"] as String!,
                // 1 First, check to see if you have a photoURL set.
                let photoURL = messageData["photoURL"] as String! { // 1
                // 2 If so, create a new JSQPhotoMediaItem. This object encapsulates rich media in messages — exactly what you need here!
                if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId) {
                    // 3 With that media item, call addPhotoMessage
                    self.addPhotoMessage(withId: id, key: snapshot.key, mediaItem: mediaItem)
                    // 4 Finally, check to make sure the photoURL contains the prefix for a Firebase Storage object. If so, fetch the image data.
                    if photoURL.hasPrefix("gs://") {
                        self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
                    }
                }
            }else {
                print("Error! Could not decode message data")
            }
        })
        
        // We can also use the observer method to listen for
        // changes to existing messages.
        // We use this to be notified when a photo has been stored
        // to the Firebase Storage, so we can update the message data
        updatedMessageRefHandle = messageRef.observe(.childChanged, with: { (snapshot) in
            let key = snapshot.key
            // 1.Grabs the message data dictionary from the Firebase snapshot.
            let messageData = snapshot.value as! Dictionary<String, String> // 1
            //2. Checks to see if the dictionary has a photoURL key set.
            if let photoURL = messageData["photoURL"] as String! { // 2
                // The photo has been updated.
                //3. If so, pulls the JSQPhotoMediaItem out of the cache.
                if let mediaItem = self.photoMessageMap[key] { // 3
                    //4. Finally, fetches the image data and update the message with the image!
                    self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: key) // 4
                }
            }
        })
    }
  
  // MARK: UI and User Interaction
    //creates the message bubble colors used in the native Messages app
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory(bubble: UIImage.jsq_bubbleCompactTailless(), capInsets: UIEdgeInsets.zero)
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory(bubble: UIImage.jsq_bubbleCompactTailless(), capInsets: UIEdgeInsets.zero)
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }
    
    private func addMessage(withId id: String, name:String, text: String) {
        if let message = JSQMessage(senderId: id, displayName: name, text: text) {
            messages.append(message)
        }
    }
    
    
    
  // MARK: UITextViewDelegate methods
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        //if the text is not empty, the user is typing
        isTyping = textView.text != ""
    }
    
    //creates a child reference to your channel called typingIndicator where i will update the typing status of the user
    // delete it once the user has left using onDisconnectRemoveValue()
    private func observeTyping() {
        let typingIndicatorRef = channelRef!.child("typingIndicator")
        userIsTypingRef = typingIndicatorRef.child(senderId)
        userIsTypingRef.onDisconnectRemoveValue()
        
        //observe for changes using .value; this will call the completion block anytime it changes
        usersTypingQuery.observe(.value) { (data: DataSnapshot) in
            // i am the only one typing, dont show indicator
            if data.childrenCount == 1 && self.isTyping {
                return
            }
            
            //are there others typing
            self.showTypingIndicator = data.childrenCount > 0
            self.scrollToBottom(animated: true)
        }
    }
    
    // MARK: Sending Images
    func sendPhotoMessage() -> String? {
        let itemRef = messageRef.childByAutoId()
        
        let messageItem = [
            "photoURL": imageURLNotSetKey,
            "senderId": senderId,
        ]
        
        itemRef.setValue(messageItem)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        finishSendingMessage()
        return itemRef.key
    }
    
    private func addPhotoMessage(withId id: String, key: String, mediaItem: JSQPhotoMediaItem) {
        if let message = JSQMessage(senderId: id, displayName: "", media: mediaItem) {
            messages.append(message)
            
            if (mediaItem.image == nil) {
                photoMessageMap[key] = mediaItem
            }
            
            collectionView.reloadData()
        }
    }
    
    func setImageURL(_ url: String, forPhotoMessageWithKey key: String) {
        let itemRef = messageRef.child(key)
        itemRef.updateChildValues(["photoURL" : url])
    }
    
    //present a camera if the device supports it, or the photo library if not
    override func didPressAccessoryButton(_ sender: UIButton!) {
        let picker = UIImagePickerController()
        picker.delegate = self
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
            picker.sourceType = UIImagePickerControllerSourceType.camera
        }else {
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        }
        present(picker, animated: true, completion: nil)
    }
    
    private func fetchImageDataAtURL(_ photoURL: String, forMediaItem mediaItem: JSQPhotoMediaItem, clearsPhotoMessageMapOnSuccessForKey key: String?) {
        // 1 Get a reference to the stored image.
        let storageRef = Storage.storage().reference(forURL: photoURL)
        
        // 2 Get the image data from the storage.
        storageRef.getData(maxSize: INT64_MAX){ (data, error) in
            if let error = error {
                print("Error downloading image data: \(error)")
                return
            }
            
            // 3 Get the image metadata from the storage.
            storageRef.getMetadata(completion: { (metadata, metadataErr) in
                if let error = metadataErr {
                    print("Error downloading metadata: \(error)")
                    return
                }
                
                // 4 If the metadata suggests that the image is a GIF you use a category on UIImage that was pulled in via the SwiftGifOrigin Cocapod. This is needed because UIImage doesn’t handle GIF images out of the box. Otherwise you just use UIImage in the normal fashion.
                if (metadata?.contentType == "image/gif") {
                    mediaItem.image = UIImage.gifWithData(data!)
                } else {
                    mediaItem.image = UIImage.init(data: data!)
                }
                self.collectionView.reloadData()
                
                // 5 Finally, you remove the key from your photoMessageMap now that you’ve fetched the image data.
                guard key != nil else {
                    return
                }
                self.photoMessageMap.removeValue(forKey: key!)
            })
        }
    }
}

// MARK: Image Picker Delegate
//These two methods handle the cases when the user either selects an image or cancels the selection process. When selecting an image, the user can either get one from the photo library or take an image directly with their camera. Starting with choosing a photo from the library:
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true, completion:nil)
        
        // First, check to see if a photo URL is present in the info dictionary. If so, you know you have a photo from the library.
        if let photoReferenceUrl = info[UIImagePickerControllerReferenceURL] as? URL {
            // Handle picking a Photo from the Photo Library
            // Next, pull the PHAsset from the photo URL
            let assets = PHAsset.fetchAssets(withALAssetURLs: [photoReferenceUrl], options: nil)
            let asset = assets.firstObject
            
            // You call sendPhotoMessage and receive the Firebase key.
            if let key = sendPhotoMessage() {
                // Get the file URL for the image.
                asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
                    let imageFileURL = contentEditingInput?.fullSizeImageURL
                    
                    // Create a unique path based on the user’s unique ID and the current time.
                    let path = "\(String(describing: Auth.auth().currentUser?.uid))/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(photoReferenceUrl.lastPathComponent)"
                    
                    // And (finally!) save the image file to Firebase Storage
                    self.storageRef.child(path).putFile(from: imageFileURL!, metadata: nil) { (metadata, error) in
                        if let error = error {
                            print("Error uploading photo: \(error.localizedDescription)")
                            return
                        }
                        // Once the image has been saved, you call setImageURL() to update your photo message with the correct URL
                        self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                    }
                })
            }
        } else {
            // Handle picking a Photo from the Camera - TODO
            // 1 First you grab the image from the info dictionary.
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            // 2 Then call your sendPhotoMessage() method to save the fake image URL to Firebase.
            if let key = sendPhotoMessage() {
                // 3 Next you get a JPEG representation of the photo, ready to be sent to Firebase storage.
                let imageData = UIImageJPEGRepresentation(image, 1.0)
                // 4 As before, create a unique URL based on the user’s unique id and the current time.
                let imagePath = Auth.auth().currentUser!.uid + "/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
                // 5 Create a FIRStorageMetadata object and set the metadata to image/jpeg.
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                // 6 Then save the photo to Firebase Storage
                storageRef.child(imagePath).putData(imageData!, metadata: metadata) { (metadata, error) in
                    if let error = error {
                        print("Error uploading photo: \(error)")
                        return
                    }
                    // 7 Once the image has been saved, you call setImageURL() again.
                    self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion:nil)
    }
}
