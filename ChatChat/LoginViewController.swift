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
import GoogleSignIn

class LoginViewController: UIViewController, GIDSignInUIDelegate {
    
  @IBOutlet weak var bottomLayoutGuideConstraint: NSLayoutConstraint!
  @IBOutlet weak var loginView: UIView!

    @IBOutlet weak var facebookSignIn: UIButton!
    @IBOutlet weak var googleSignIn: GIDSignInButton!

    @IBAction func facebookSignIn(_ sender: Any) {
    }
    @IBAction func googleSignIn(_ sender: GIDSignInButton) {
        SVProgressHUD.show()
        GIDSignIn.sharedInstance().signIn()
        googleSignIn.isEnabled = false
        facebookSignIn.isEnabled = false
    }
    private lazy var userRef: DatabaseReference = Database.database().reference().child("users")
  var handle: AuthStateDidChangeListenerHandle?
  // MARK: View Lifecycle
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // [START auth_listener]
    handle = Auth.auth().addStateDidChangeListener { (auth, user) in
        // [START_EXCLUDE]
        
        print(user!)
        // [END_EXCLUDE]
    }
    // [END auth_listener]
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    Auth.auth().removeStateDidChangeListener(handle!)
  }
    override func viewDidLoad() {
        
        GIDSignIn.sharedInstance().uiDelegate = self
//        GIDSignIn.sharedInstance().signIn()

    }
  
  @IBAction func loginDidTouch(_ sender: AnyObject) {
    //First, you check to confirm the name field isn’t empty.
//    if nameField?.text != "" { // 1
//        SVProgressHUD.show()
//        //Then you use the Firebase Auth API to sign in anonymously. This method takes a completion handler which is passed a user and, if necessary, an error.
//        Auth.auth().signInAnonymously(completion: { (user, error) in // 2
//            //In the completion handler, check to see if you have an authentication error. If so, abort.
//            if let err = error { // 3
//                print(err.localizedDescription)
//                return
//            }
//            SVProgressHUD.dismiss()
//            //Finally, if there wasn’t an error, trigger the segue to move to the ChannelListViewController.
//            self.performSegue(withIdentifier: "LoginToChat", sender: nil) // 4
//        })
//    }
  }
  

  
  // MARK: Navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        super.prepare(for: segue, sender: sender)
//        //Retrieve the destination view controller from segue and cast it to a UINavigationController.
//        let userVc = segue.destination as! SetUserViewController
//        //Cast the first view controller of the UINavigationController to a ChannelListViewController.
////        let channelVc = navVc.viewControllers.first as! ChannelListViewController
//        
//        //Set the senderDisplayName in the ChannelListViewController to the name provided in the nameField by the user.
//        
//                    
//      
//
//        
//    }
}

