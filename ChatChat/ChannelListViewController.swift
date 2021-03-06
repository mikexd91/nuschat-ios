//
//  ChannelListViewController.swift
//  nuschat
//
//  Created by Mike Zhang Xunda on 4/7/17.
//  Copyright © 2017 Mike Zhang Xunda. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD
import IGIdenticon
import GoogleSignIn

enum Section: Int {
    case createNewChannelSection = 0
    case currentChannelSection
}

class ChannelListViewController: UITableViewController, UISearchBarDelegate{
    
    // MARK: Properties
    //Add a simple property to store the sender’s name.
    var senderDisplayName: String?
    
    //Add a text field, which you’ll use later for adding new Channels.
    var newChannelTextField: UITextField?
    
    //Create an empty array of Channel objects to store your channels.
    private var channels: [Channel] = []
    var filteredChannels = [Channel]()
    var inSearchMode = false
    
    //used to store a reference to the list of channels in the database
    private lazy var channelRef: DatabaseReference = Database.database().reference().child("channels")
    
    //hold a handle to the reference so you can remove it later on.
    private var channelRefHandle: DatabaseHandle?
    
    private lazy var userRef: DatabaseReference = Database.database().reference().child("users")
    
    var searchField: UISearchBar = UISearchBar()
    
    @IBOutlet weak var channelTableView: UITableView!
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        title = "#nuschat"
        
        searchField.searchBarStyle = UISearchBarStyle.prominent
        searchField.placeholder = " Search Channels..."
        searchField.sizeToFit()
        searchField.isTranslucent = false
        searchField.backgroundImage = UIImage()
        searchField.delegate = self
        searchField.returnKeyType = UIReturnKeyType.done
        tableView.tableHeaderView = searchField
        
        Messaging.messaging().subscribe(toTopic: "/channels")
        
        SVProgressHUD.show()
        observeChannels()
        UIApplication.shared.applicationIconBadgeNumber = 0
        
    }
    
    override func viewWillAppear(_ animated: Bool) {

    }
    
    //stop observing database changes when the view controller dies by checking if channelRefHandle is set and then calling removeObserver(withHandle:).
    deinit {
        if let refHandle = channelRefHandle {
            channelRef.removeObserver(withHandle: refHandle)
        }
        if let refHandle = channelRefHandle {
            userRef.removeObserver(withHandle: refHandle)
        }
    }
    
    //TODO: Declare tableViewTapped here:
    func tableViewTapped() {
        newChannelTextField?.endEditing(true)
    }
    
    
    // MARK: Firebase related methods
    private func observeChannels() {
        let uid = Auth.auth().currentUser?.uid
        channelRefHandle = userRef.child(uid!).child("username").observe(.value, with: { (snapshot) in
            self.senderDisplayName = snapshot.value! as? String
        })
        
        //use the observe methods to listen for new channel channels being written to the Firebase DB
        
        // call observe:with: on your channel reference, storing a handle to the reference. This calls the completion block every time a new channel is added to your database.
        channelRefHandle = channelRef.observe(.value, with: { (snapshot) in
            var newChannels: [Channel] = []
            //The completion receives a DataSnapshot (stored in snapshot), which contains the data and other helpful methods.
            print(snapshot.value)
            for item in snapshot.children{
                let channelItem = Channel(snapshot: item as! DataSnapshot)
                newChannels.append(channelItem)
            }
            self.channels = newChannels
            self.tableView.reloadData()
            SVProgressHUD.dismiss()
            
        })
    }
    
    
    
    // MARK: UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        //Set the number of sections. The first section will include a form for adding new channels, and the second section will show a list of channels.
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //Set the number of rows for each section. This is always 1 for the first section, and the number of channels for the second section.
        if let currentSection: Section = Section(rawValue: section) {
            switch currentSection {
            case .createNewChannelSection:
                return 1
            case .currentChannelSection:
                if inSearchMode{
                    return filteredChannels.count
                }else {
                    return channels.count
                }
            }
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath as NSIndexPath).section == Section.createNewChannelSection.rawValue {
            return 44
        }
        return 70
    }
    //
    //    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    //        return 100
    //    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Define what goes in each cell. For the first section, you store the text field from the cell in your newChannelTextField property. For the second section, you just set the cell’s text label as your channel name
        let lastMessage: String
        let reuseIdentifier = (indexPath as NSIndexPath).section == Section.createNewChannelSection.rawValue ? "NewChannel" : "ExistingChannel"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        if (indexPath as NSIndexPath).section == Section.createNewChannelSection.rawValue {
            if let createNewChannelCell = cell as? CreateChannelCell {
                newChannelTextField = createNewChannelCell.newChannelNameField
            }
        }else if (indexPath as NSIndexPath).section == Section.currentChannelSection.rawValue {
            if let createCurrentCell = cell as? ChannelListTableViewCell {
                let channelDisplayed: Channel!
                if inSearchMode{
                    channelDisplayed = filteredChannels[(indexPath as NSIndexPath).row]
                }else{
                    channelDisplayed = channels[(indexPath as NSIndexPath).row]
                }
                createCurrentCell.channelTitle.text = channelDisplayed.name
                
                if channelDisplayed.lastMessage != ""{
                    if channelDisplayed.lastMessageSenderId == Auth.auth().currentUser?.uid {
                        lastMessage = "You: \(channelDisplayed.lastMessage)"
                    }else{
                        lastMessage =  "\(channelDisplayed.lastMessageSender): \(channelDisplayed.lastMessage)"
                    }
                }else {
                    lastMessage = ""
                }
                createCurrentCell.channelLastMsg.text = lastMessage

                createCurrentCell.channelPhoto.image = Identicon().icon(from: channels[(indexPath as NSIndexPath).row].name, size: CGSize(width: 100, height: 100))
                createCurrentCell.channelPhoto.layer.cornerRadius = (createCurrentCell.channelPhoto.frame.width / 2) //instead of let radius = CGRectGetWidth(self.frame) / 2
                createCurrentCell.channelPhoto.layer.masksToBounds = true
            }
        }
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let userid = Auth.auth().currentUser?.uid
        let channel = channels[(indexPath as NSIndexPath).row]
        
        if userid == channel.createdBy {
            print("xunda hereeee")
            if editingStyle == .delete {
                print(channel.ref)
                channel.ref?.removeValue()
                observeChannels()
            }
        }
        
    }
    
    
    
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //triggers the ShowChannel segue when the user taps a channel cell.
        print(indexPath.section)
        if indexPath.section == Section.currentChannelSection.rawValue {
            let channel = channels[(indexPath as NSIndexPath).row]
            self.performSegue(withIdentifier: "ShowChannel", sender: channel)
        }else{
            print("not currentChannel")
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == Section.createNewChannelSection.rawValue {
            return nil
        }
        return indexPath
    }
    
    
    // MARK :Actions
    @IBAction func createChannel(_ sender: Any) {
        //First check if you have a channel name in the text field.
        if let name = newChannelTextField?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            //Create a new channel reference with a unique key using childByAutoId().
            let newChannelRef = channelRef.childByAutoId()
            //Create a dictionary to hold the data for this channel. A [String: AnyObject] works as a JSON-like object.
            let uid = Auth.auth().currentUser?.uid
            let channelItem = ["name": name,
                               "createdBy": uid,
                               "lastMessage":"",
                               "lastMessageSender":"",
                               "lastMessageSenderId":""]
            //Finally, set the name on this new channel, which is saved to Firebase automatically!
            newChannelRef.setValue(channelItem)
            newChannelTextField?.text=""
        }else{
            newChannelTextField?.text=""
        }
        
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let channel = sender as? Channel {
            let chatVc = segue.destination as! ChatViewController
            
            chatVc.senderDisplayName = senderDisplayName
            chatVc.channel = channel
            chatVc.channelRef = channelRef.child(channel.id)
            chatVc.hidesBottomBarWhenPushed = true
        }
    }
    
    // MARK: search table
    func searchBarSearchButtonClicked(_ searchField: UISearchBar) {
        view.endEditing(true)
    }
    
    func searchBar(_ searchField: UISearchBar, textDidChange searchText: String) {
        if searchField.text == nil || searchField.text == "" {
            inSearchMode = false
            tableView.reloadData()
            view.endEditing(true)
        }else {
            inSearchMode = true
            let lower = searchField.text?.lowercased()
            //$0 place holder
            filteredChannels = channels.filter({$0.name.range(of: lower!) != nil})
            tableView.reloadData()
        }
    }
    
}
