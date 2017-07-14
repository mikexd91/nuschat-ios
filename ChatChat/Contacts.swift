//
//  User.swift
//  nuschat
//
//  Created by Mike Zhang Xunda on 11/7/17.
//  Copyright © 2017 Mike Zhang Xunda. All rights reserved.
//

import Firebase

internal class Contacts{
    internal let id: String
    internal let name: String
    internal let email: String
    internal let username: String
    internal let photoUrl: String
    internal let onlineStatus: String
    internal let ref: DatabaseReference?
    
    init(id: String, name: String, ref: DatabaseReference, email: String, username: String, photoUrl: String, onlineStatus: String) {
        self.id = id
        self.name = name
        self.email = email
        self.username = username
        self.photoUrl = photoUrl
        self.ref = ref
        self.onlineStatus = onlineStatus
    }
    
    init(snapshot: DataSnapshot) {
        id = snapshot.key
        let snapshotValue = snapshot.value as! [String: AnyObject]
        name = snapshotValue["name"] as! String
        email = snapshotValue["email"] as! String
        username = snapshotValue["username"] as! String
        photoUrl = snapshotValue["photoUrl"] as! String
        ref = snapshot.ref
        onlineStatus = snapshotValue["onlineStatus"] as! String
    }
    
}
