//
//  ContactsViewController.swift
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

class ContactsViewController: UITableViewController, UISearchBarDelegate {
    
    var searchField: UISearchBar = UISearchBar()
    //Create an empty array of Channel objects to store your channels.
    private var channels: [Channel] = []
    
    //used to store a reference to the list of channels in the database
    private lazy var channelRef: DatabaseReference = Database.database().reference().child("channels")
    
    //hold a handle to the reference so you can remove it later on.
    private var channelRefHandle: DatabaseHandle?
    
    //Create an empty array of Channel objects to store your channels.
    private var contacts: [Contacts] = []
    var filteredContacts = [Contacts]()
    var inSearchMode = false
    
    //used to store a reference to the list of channels in the database
    private lazy var userRef: DatabaseReference = Database.database().reference().child("users")
    
    private lazy var onlineRef: DatabaseReference = Database.database().reference().child("online")
    
    //hold a handle to the reference so you can remove it later on.
    private var userRefHandle: DatabaseHandle?
    
    var userCountBarButtonItem : UIBarButtonItem!
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        searchField.searchBarStyle = UISearchBarStyle.prominent
        searchField.placeholder = " Search Contacts..."
        searchField.sizeToFit()
        searchField.isTranslucent = false
        searchField.backgroundImage = UIImage()
        searchField.delegate = self
        searchField.returnKeyType = UIReturnKeyType.done
        tableView.tableHeaderView = searchField
        
        userCountBarButtonItem = UIBarButtonItem(title: "1",
                                                 style: .plain,
                                                 target: self,
                                                 action: #selector(userCountButtonDidTouch))
        
        userCountBarButtonItem.tintColor = self.view.tintColor
        navigationItem.rightBarButtonItem = userCountBarButtonItem
        
        title = "#contacts"
        
        SVProgressHUD.show()
        
        Auth.auth().addStateDidChangeListener { auth, user in
            guard let user = user else { return }
            // 1 Create a child reference using a user’s uid, which is generated when Firebase creates an account.
            let currentUserRef = self.onlineRef.child(user.uid)
            // 2 Use this reference to save the current user’s email.
            currentUserRef.setValue(user.email)
            // 3 Call onDisconnectRemoveValue() on currentUserRef. This removes the value at the reference’s location after the connection to Firebase closes, for instance when a user quits your app. This is perfect for monitoring users who have gone offline.
            currentUserRef.onDisconnectRemoveValue()
        }
        
        observeContacts()
        
        onlineRef.observe(.value, with: { snapshot in
            if snapshot.exists() {
                self.userCountBarButtonItem?.title = "\(snapshot.childrenCount.description) Online"
            } else {
                self.userCountBarButtonItem?.title = "0 Online"
            }
        })
        
    }
    
    //stop observing database changes when the view controller dies by checking if channelRefHandle is set and then calling removeObserver(withHandle:).
    deinit {
        if let refHandle = userRefHandle {
            userRef.removeObserver(withHandle: refHandle)
        }
    }
    
    //TODO: Declare tableViewTapped here:
    func tableViewTapped() {
        searchField.endEditing(true)
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
    
    func userCountButtonDidTouch() {
//        performSegue(withIdentifier: listToUsers, sender: nil)
    }
    
    // MARK: UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        //Set the number of sections. The first section will include a form for adding new channels, and the second section will show a list of channels.
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //Set the number of rows for each section. This is always 1 for the first section, and the number of channels for the second section.

      if inSearchMode{
          return filteredContacts.count
      }else {
        return contacts.count
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
        
        let reuseIdentifier = "ContactsCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
            if let contactCell = cell as? ContactsListTableViewCell {
                if let createCurrentCell = cell as? ContactsListTableViewCell {
                    let user: Contacts!
                    if inSearchMode{
                        user = filteredContacts[(indexPath as NSIndexPath).row]
                    }else{
                        user = contacts[(indexPath as NSIndexPath).row]
                    }
                    createCurrentCell.profileName.text = user.username
                    createCurrentCell.profileStatus.text = user.onlineStatus
                    createCurrentCell.profilePhoto.layer.cornerRadius = (createCurrentCell.profilePhoto.frame.width / 2)
                    createCurrentCell.profilePhoto.layer.masksToBounds = true
                }
            }
        
        return cell
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
            filteredContacts = contacts.filter({$0.username?.range(of: lower!) != nil})
            tableView.reloadData()
        }
    }
    
}
