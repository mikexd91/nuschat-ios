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
    
    private lazy var userRef: DatabaseReference = Database.database().reference().child("users")
    
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
        //        facebookSignIn.isEnabled = false
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue){
        
    }
    
    
    // MARK: View Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        googleSignIn.isEnabled = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SVProgressHUD.dismiss()
        //    Auth.auth().removeStateDidChangeListener(handle!)
    }
    override func viewDidLoad() {
        GIDSignIn.sharedInstance().uiDelegate = self
        //        GIDSignIn.sharedInstance().signIn()
    }
    
    
    
}

