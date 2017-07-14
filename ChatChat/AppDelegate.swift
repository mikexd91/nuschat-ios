//
//  AppDelegate.swift
//  nuschat
//
//  Created by Mike Zhang Xunda on 4/7/17.
//  Copyright © 2017 Mike Zhang Xunda. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import SVProgressHUD

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    
    var window: UIWindow?
    private lazy var userRef: DatabaseReference = Database.database().reference().child("users")
    var databaseRef: DatabaseReference!
    var filePath: String = String() {
        didSet {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshView"), object: nil)
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        return true
    }
    
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any])
        -> Bool {
            return GIDSignIn.sharedInstance().handle(url,sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,annotation: [:])
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        // ...
        SVProgressHUD.show()
        var nextStage: Bool = false
        if let error = error {
            // ...
            print(error.localizedDescription)
            return
        }
        print("User signed into google")
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,accessToken: authentication.accessToken)
        // ...
        Auth.auth().signIn(with: credential, completion: { (user, error) in
            print("User Signed into Firebase")
            print(user!.photoURL!)
            print(user!.displayName!)
            print(user!.email!)
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
                                "onlineStatus": ""]
                    //Finally, set the name on this new channel, which is saved to Firebase automatically!
                    newUserRef.setValue(data)
                    nextStage = true
                }
                SVProgressHUD.dismiss()
                let mainStoryboard: UIStoryboard = UIStoryboard(name:"Main", bundle: nil)
                if nextStage {
                    self.window?.rootViewController?.performSegue(withIdentifier: "SetUsername", sender: nil)
                } else {
                    self.window?.rootViewController?.performSegue(withIdentifier: "SignInToChat", sender: nil)
                }
            })
            
        })
    }
    
    
    
    
    
    
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
    
}

