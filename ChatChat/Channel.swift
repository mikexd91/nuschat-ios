//
//  Channel.swift
//  nuschat
//
//  Created by Mike Zhang Xunda on 4/7/17.
//  Copyright © 2017 Mike Zhang Xunda. All rights reserved.
//

import Firebase

internal class Channel {
    internal let id: String
    internal let name: String
    internal let createdBy: String
    internal let lastMessage: String
    internal let lastMessageSender: String
    internal let lastMessageSenderId: String
    internal let ref: DatabaseReference?
    
    init(id: String, name: String, createdBy: String, ref: DatabaseReference, lastMessage: String, lastMessageSender: String, lastMessageSenderId: String) {
        self.id = id
        self.name = name
        self.createdBy = createdBy
        self.ref = ref
        self.lastMessage = lastMessage
        self.lastMessageSender = lastMessageSender
        self.lastMessageSenderId = lastMessageSenderId
    }
    
    init(snapshot: DataSnapshot) {
        id = snapshot.key
        let snapshotValue = snapshot.value as! [String: AnyObject]
        name = snapshotValue["name"] as! String
        createdBy = snapshotValue["createdBy"] as! String
        ref = snapshot.ref
        lastMessage = snapshotValue["lastMessage"] as! String
        lastMessageSender = snapshotValue["lastMessageSender"] as! String
        lastMessageSenderId = snapshotValue["lastMessageSenderId"] as! String
    }
    
}
