//
//  SetUserViewController.swift
//  nuschat
//
//  Created by Mike Zhang Xunda on 11/7/17.
//  Copyright © 2017 Mike Zhang Xunda. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class SetUserViewController: UIViewController {
    
    let delegate = UIApplication.shared.delegate as! AppDelegate
    var fileDirectory: String = String()
    
    var senderDisplayname: String?
    
    private lazy var userRef: DatabaseReference = Database.database().reference().child("users")
    var databaseRef: DatabaseReference!
    
    @IBOutlet weak var bottomLayoutGuideConstraint: NSLayoutConstraint!
    @IBOutlet var loginView: UIView!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var setUsername: UIButton!
    @IBAction func loginToChat(_ sender: Any) {
        self.performSegue(withIdentifier: "LoginToChat", sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //TODO: Set the tapGesture here:
        let tapGesture = UITapGestureRecognizer(target: self, action:#selector(tableViewTapped))
        loginView.addGestureRecognizer(tapGesture)
        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShowNotification(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHideNotification(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Notifications
    
    func keyboardWillShowNotification(_ notification: Notification) {
        let keyboardEndFrame = ((notification as NSNotification).userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let convertedKeyboardEndFrame = view.convert(keyboardEndFrame, from: view.window)
        bottomLayoutGuideConstraint.constant = view.bounds.maxY - convertedKeyboardEndFrame.minY + 25
    }
    
    func keyboardWillHideNotification(_ notification: Notification) {
        bottomLayoutGuideConstraint.constant = 247
    }
    
    //TODO: Declare tableViewTapped here:
    func tableViewTapped() {
        nameField.endEditing(true)
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        //Retrieve the destination view controller from segue and cast it to a UINavigationController.
        //Cast the first view controller of the UINavigationController to a ChannelListViewController.
        
//        let barViewControllers = segue.destination as! UITabBarController
//        let nav = barViewControllers.viewControllers!.first as! UINavigationController
//        let destinationViewController = nav.viewControllers.first as! ChannelListViewController
        
        let uid = Auth.auth().currentUser?.uid
        self.userRef.child(uid!).observeSingleEvent(of: .value, with: { (snapshot) in
            print(snapshot.value!)
            print(uid!)
            let name = self.nameField?.text
            let childUpdates = ["/\(uid!)/username": name]
            self.userRef.updateChildValues(childUpdates)
            
        })
        
        //Set the senderDisplayName in the ChannelListViewController to the name provided in the nameField by the user.
        
//        destinationViewController.senderDisplayName = nameField?.text
    }
    
    
}
