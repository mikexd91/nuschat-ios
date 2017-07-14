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

enum Sections: Int {
    case searchSection = 0
    case contactSection
}

class ContactsViewController: UITableViewController {
    
    var searchField: UISearchBar?
    
    //Create an empty array of Channel objects to store your channels.
    private var channels: [Channel] = []
    
    //used to store a reference to the list of channels in the database
    private lazy var channelRef: DatabaseReference = Database.database().reference().child("channels")
    
    //hold a handle to the reference so you can remove it later on.
    private var channelRefHandle: DatabaseHandle?
    
    //Create an empty array of Channel objects to store your channels.
    private var contacts: [Contacts] = []
    
    //used to store a reference to the list of channels in the database
    private lazy var userRef: DatabaseReference = Database.database().reference().child("users")
    
    //hold a handle to the reference so you can remove it later on.
    private var userRefHandle: DatabaseHandle?
    
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        title = "contacts"
        
        SVProgressHUD.show()
        observeContacts()
        
    }
    
    //stop observing database changes when the view controller dies by checking if channelRefHandle is set and then calling removeObserver(withHandle:).
    deinit {
        if let refHandle = userRefHandle {
            userRef.removeObserver(withHandle: refHandle)
        }
    }
    
    //TODO: Declare tableViewTapped here:
    func tableViewTapped() {
        searchField?.endEditing(true)
    }
    
    
    // MARK: Firebase related methods
    private func observeContacts() {
        
        userRefHandle = userRef.observe(.value, with: { (snapshot) in
            var newContacts: [Contacts] = []
            //The completion receives a DataSnapshot (stored in snapshot), which contains the data and other helpful methods.
            print(snapshot.value)
            for item in snapshot.children{
                let contactItem = Contacts(snapshot: item as! DataSnapshot)
                newContacts.append(contactItem)
            }
            self.contacts = newContacts
            print(self.contacts.count)
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
        if let currentSection: Sections = Sections(rawValue: section) {
            switch currentSection {
            case .searchSection:
                return 1
            case .contactSection:
                return contacts.count
            }
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath as NSIndexPath).section == Sections.searchSection.rawValue {
            return 44
        }
        return 50
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Define what goes in each cell. For the first section, you store the text field from the cell in your newChannelTextField property. For the second section, you just set the cell’s text label as your channel name
        
        let reuseIdentifier = (indexPath as NSIndexPath).section == Sections.searchSection.rawValue ? "SearchContactsCell" : "ContactsCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        if (indexPath as NSIndexPath).section == Sections.searchSection.rawValue {
            if let searchCell = cell as? SearchContactsTableViewCell {
                searchField = searchCell.searchContactBar
            }
        }else if (indexPath as NSIndexPath).section == Sections.contactSection.rawValue {
            if let contactCell = cell as? ContactsListTableViewCell {
                if let createCurrentCell = cell as? ContactsListTableViewCell {
                    createCurrentCell.profileName.text = contacts[(indexPath as NSIndexPath).row].username
                    createCurrentCell.profileStatus.text = contacts[(indexPath as NSIndexPath).row].onlineStatus
                    
                    createCurrentCell.profilePhoto.layer.cornerRadius = (createCurrentCell.profilePhoto.frame.width / 2)
                    createCurrentCell.profilePhoto.layer.masksToBounds = true
                }
            }
        }
        return cell
    }
    
}
