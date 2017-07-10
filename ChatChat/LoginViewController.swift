//
//  LoginViewController.swift
//  nuschat
//
//  Created by Mike Zhang Xunda on 4/7/17.
//  Copyright © 2017 Mike Zhang Xunda. All rights reserved.
//


import UIKit
import Firebase
import SVProgressHUD

class LoginViewController: UIViewController {
  
  @IBOutlet weak var nameField: UITextField!
  @IBOutlet weak var bottomLayoutGuideConstraint: NSLayoutConstraint!
  @IBOutlet weak var loginView: UIView!
  // MARK: View Lifecycle
  
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
    override func viewDidLoad() {
        //TODO: Set the tapGesture here:
        let tapGesture = UITapGestureRecognizer(target:
            self, action:#selector(tableViewTapped))
        loginView.addGestureRecognizer(tapGesture)
        
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                Auth.auth().signInAnonymously(completion: { (user, error) in // 2
                    //In the completion handler, check to see if you have an authentication error. If so, abort.
                    if let err = error { // 3
                        print(err.localizedDescription)
                        return
                    }
                    SVProgressHUD.dismiss()
                    //Finally, if there wasn’t an error, trigger the segue to move to the ChannelListViewController.
                    self.performSegue(withIdentifier: "LoginToChat", sender: nil) // 4
                })
            }else{
                
            }
        }
    }
  
  @IBAction func loginDidTouch(_ sender: AnyObject) {
    //First, you check to confirm the name field isn’t empty.
    if nameField?.text != "" { // 1
        SVProgressHUD.show()
        //Then you use the Firebase Auth API to sign in anonymously. This method takes a completion handler which is passed a user and, if necessary, an error.
        Auth.auth().signInAnonymously(completion: { (user, error) in // 2
            //In the completion handler, check to see if you have an authentication error. If so, abort.
            if let err = error { // 3
                print(err.localizedDescription)
                return
            }
            SVProgressHUD.dismiss()
            //Finally, if there wasn’t an error, trigger the segue to move to the ChannelListViewController.
            self.performSegue(withIdentifier: "LoginToChat", sender: nil) // 4
        })
    }
  }
  
  // MARK: - Notifications
  
  func keyboardWillShowNotification(_ notification: Notification) {
    let keyboardEndFrame = ((notification as NSNotification).userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
    let convertedKeyboardEndFrame = view.convert(keyboardEndFrame, from: view.window)
    bottomLayoutGuideConstraint.constant = view.bounds.maxY - convertedKeyboardEndFrame.minY
  }
  
  func keyboardWillHideNotification(_ notification: Notification) {
    bottomLayoutGuideConstraint.constant = 48
  }
    
    //TODO: Declare tableViewTapped here:
    func tableViewTapped() {
        nameField.endEditing(true)
    }
  
  // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        //Retrieve the destination view controller from segue and cast it to a UINavigationController.
        let navVc = segue.destination as! UINavigationController
        //Cast the first view controller of the UINavigationController to a ChannelListViewController.
        let channelVc = navVc.viewControllers.first as! ChannelListViewController
        
        //Set the senderDisplayName in the ChannelListViewController to the name provided in the nameField by the user.
        channelVc.senderDisplayName = nameField?.text
    }
}

