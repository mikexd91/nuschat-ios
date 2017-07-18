//
//  ContactsListTableViewCell.swift
//  ChatChat
//
//  Created by Mike Zhang Xunda on 13/7/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import UIKit

class ContactsListTableViewCell: UITableViewCell {

    @IBOutlet weak var myProfilePhoto: UIImageView!
    
    @IBOutlet weak var myProfileName: UILabel!
    
    @IBOutlet weak var myOnlineStatus: UILabel!
    
    @IBOutlet weak var profilePhoto: UIImageView!

    @IBOutlet weak var profileName: UILabel!

    @IBOutlet weak var profileStatus: UILabel!
    
    @IBOutlet weak var searchField: UISearchBar!
    
    @IBOutlet weak var staticLbl: UILabel!
}
