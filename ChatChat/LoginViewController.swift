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
import FBSDKLoginKit

class LoginViewController: UIViewController, GIDSignInUIDelegate {
    
    private lazy var userRef: DatabaseReference = Database.database().reference().child("users")
    let kUserDefault = UserDefaults.standard
    
    @IBOutlet weak var bottomLayoutGuideConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var facebookSignIn: UIButton!
    @IBOutlet weak var googleSignIn: UIButton!
    
    
    @IBAction func facebookSignIn(_ sender: Any) {
        let fbLoginManager = FBSDKLoginManager()
        
        //Sign in
        if kUserDefault.bool(forKey: "isFacebookSignIn")  {
            fbSignIn()
        }else {
            fbLoginManager.logIn(withReadPermissions: ["public_profile", "email"], from: self) { (result, error) in
                SVProgressHUD.show()
                if let error = error {
                    print("Failed to login: \(error.localizedDescription)")
                    return
                }
                
                guard let accessToken = FBSDKAccessToken.current() else {
                    print("Failed to get access token")
                    return
                }
                
                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
                
                self.googleSignIn.isEnabled = false
                self.facebookSignIn.isEnabled = false
                
                // Perform login by calling Firebase APIs
                Auth.auth().signIn(with: credential, completion: { (user, error) in
                    print("Sign up to Firebase as fb user")
                    print(user!.email!)
                    print(user!.displayName!)
                    print(user!.photoURL!)
                    
                    if let error = error {
                        print("Login error: \(error.localizedDescription)")
                        let alertController = UIAlertController(title: "Login Error", message: error.localizedDescription, preferredStyle: .alert)
                        let okayAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                        alertController.addAction(okayAction)
                        self.present(alertController, animated: true, completion: nil)
                        
                        return
                    }
                    
                    var nextStage: Bool = false
                    print(user!.uid)
                    let uid = Auth.auth().currentUser?.uid
                    self.userRef.child(uid!).observeSingleEvent(of: .value, with: { (snapshot) in
                        print(snapshot.value!)
                        print(uid!)
                        if snapshot.hasChild("username"){
                            print("username exist")
                            nextStage = false
                            
                        }else{
                            print("username doesn't exist")
                            //Create a new channel reference with a unique key using childByAutoId().
                            let newUserRef = self.userRef.child(uid!)
                            //Create a dictionary to hold the data for this channel. A [String: AnyObject] works as a JSON-like object.
                            let data = ["photoUrl": user!.photoURL!.absoluteString,
                                        "name": user!.displayName!,
                                        "email": user!.email!,
                                        "onlineStatus": "",
                                        "pushToken": Messaging.messaging().fcmToken]
                            //Finally, set the name on this new channel, which is saved to Firebase automatically!
                            newUserRef.setValue(data)
                            nextStage = true
                            
                        }
                        self.kUserDefault.set(true, forKey: "isFacebookSignIn")
                        self.kUserDefault.set(false, forKey: "isGoogleSignIn")
                        self.kUserDefault.synchronize()

                        if nextStage {
                            if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "SetUsername") {
                                UIApplication.shared.keyWindow?.rootViewController = viewController
                                self.dismiss(animated: true, completion: nil)
                                SVProgressHUD.dismiss()
                            }
                        } else {
                            self.performSegue(withIdentifier: "SignInToChat", sender: self)
                        }
                    })
                    
                })
                
            }

        }

        
    }
    
    func fbSignIn() {
        SVProgressHUD.show()
        guard let accessToken = FBSDKAccessToken.current() else {
            print("Failed to get access token")
            return
        }

        let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
        
        googleSignIn.isEnabled = false
        facebookSignIn.isEnabled = false
        
        Auth.auth().signIn(with: credential, completion: { (user, error) in
            print("Sign Into Firebase as fb user")
            print(user!.email!)
            print(user!.displayName!)
            print(user!.photoURL!)
            
            if let error = error {
                print("Login error: \(error.localizedDescription)")
                let alertController = UIAlertController(title: "Login Error", message: error.localizedDescription, preferredStyle: .alert)
                let okayAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alertController.addAction(okayAction)
                self.present(alertController, animated: true, completion: nil)
                
                return
            }
            
            self.kUserDefault.set(false, forKey: "isGoogleSignIn")
            self.kUserDefault.set(true, forKey: "isFacebookSignIn")
            self.kUserDefault.synchronize()
        
            print(user!.uid)
            let uid = Auth.auth().currentUser?.uid
            self.userRef.child(uid!).observeSingleEvent(of: .value, with: { (snapshot) in
                print(snapshot.value!)
                print(uid!)
                self.performSegue(withIdentifier: "SignInToChat", sender: self)
                
            })
        })

    }
    
    @IBAction func googleSignIn(_ sender: UIButton) {
        SVProgressHUD.show()
        googleSignIn.isEnabled = false
        facebookSignIn.isEnabled = false
        GIDSignIn.sharedInstance().signIn()
        
        
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue){
        
    }
    
    
    // MARK: View Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        googleSignIn.isEnabled = true
        facebookSignIn.isEnabled = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SVProgressHUD.dismiss()
        //    Auth.auth().removeStateDidChangeListener(handle!)
    }
    override func viewDidLoad() {
        GIDSignIn.sharedInstance().uiDelegate = self
        facebookSignIn.layer.cornerRadius = 20
        googleSignIn.layer.cornerRadius = 20
        //        GIDSignIn.sharedInstance().signIn()
        /*
        if kUserDefault.bool(forKey: "isGoogleSignIn") {
                     googleSignIn.isEnabled = false
                        GIDSignIn.sharedInstance().signIn()
        }
        */
        

    }
    

    
    
}

