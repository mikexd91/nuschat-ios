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

enum Section: Int {
    case createNewChannelSection = 0
    case currentChannelSection
}

class ChannelListViewController: UITableViewController {
    
    // MARK: Properties
    //Add a simple property to store the sender’s name.
    var senderDisplayName: String?
    
    //Add a text field, which you’ll use later for adding new Channels.
    var newChannelTextField: UITextField?
    
    //Create an empty array of Channel objects to store your channels.
    private var channels: [Channel] = []
    
    //used to store a reference to the list of channels in the database
    private lazy var channelRef: DatabaseReference = Database.database().reference().child("channels")
    
    //hold a handle to the reference so you can remove it later on.
    private var channelRefHandle: DatabaseHandle?
    
    
    @IBOutlet weak var channelTableView: UITableView!
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)

        title = "NUSChat"
        SVProgressHUD.show()
        observeChannels()
        
    }
    
    //stop observing database changes when the view controller dies by checking if channelRefHandle is set and then calling removeObserver(withHandle:).
    deinit {
        if let refHandle = channelRefHandle {
            channelRef.removeObserver(withHandle: refHandle)
        }
    }
    
    //TODO: Declare tableViewTapped here:
    func tableViewTapped() {
        newChannelTextField?.endEditing(true)
    }
    
    
    // MARK: Firebase related methods
    private func observeChannels() {
        //use the observe methods to listen for new channel channels being written to the Firebase DB
        
        // call observe:with: on your channel reference, storing a handle to the reference. This calls the completion block every time a new channel is added to your database.
        channelRefHandle = channelRef.observe(.childAdded, with: { (snapshot) in
            
            //The completion receives a DataSnapshot (stored in snapshot), which contains the data and other helpful methods.
            let channelData = snapshot.value as! Dictionary<String, AnyObject>
            let id = snapshot.key
            //You pull the data out of the snapshot and, if successful, create a Channel model and add it to your channels array.
            if let name = channelData["name"] as! String!, name.characters.count > 0 {
                self.channels.append(Channel(id: id, name: name))
                self.tableView.reloadData()
                SVProgressHUD.dismiss()
            }else {
                print("Error! Could not decode channel data")
            }
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
                return channels.count
            }
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Define what goes in each cell. For the first section, you store the text field from the cell in your newChannelTextField property. For the second section, you just set the cell’s text label as your channel name
        let reuseIdentifier = (indexPath as NSIndexPath).section == Section.createNewChannelSection.rawValue ? "NewChannel" : "ExistingChannel"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        if (indexPath as NSIndexPath).section == Section.createNewChannelSection.rawValue {
            if let createNewChannelCell = cell as? CreateChannelCell {
                newChannelTextField = createNewChannelCell.newChannelNameField
            }
        }else if (indexPath as NSIndexPath).section == Section.currentChannelSection.rawValue {
            cell.textLabel?.text = channels[(indexPath as NSIndexPath).row].name
        }
        return cell
    }
    
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //triggers the ShowChannel segue when the user taps a channel cell.
        if indexPath.section == Section.currentChannelSection.rawValue {
            let channel = channels[(indexPath as NSIndexPath).row]
            self.performSegue(withIdentifier: "ShowChannel", sender: channel)
        }
    }
    
    // MARK :Actions
    @IBAction func createChannel(_ sender: Any) {
        //First check if you have a channel name in the text field.
        if let name = newChannelTextField?.text {
            //Create a new channel reference with a unique key using childByAutoId().
            let newChannelRef = channelRef.childByAutoId()
            //Create a dictionary to hold the data for this channel. A [String: AnyObject] works as a JSON-like object.
            let channelItem = ["name": name]
            //Finally, set the name on this new channel, which is saved to Firebase automatically!
            newChannelRef.setValue(channelItem)
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
        }
    }

}
