/*
 * Copyright (c) 2015 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

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
        var nextStage: Bool = true
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
                if snapshot.hasChild("email"){
                    print("email exist")
                    nextStage = false
                }else{
                    print("email doesn't exist")
                    //Create a new channel reference with a unique key using childByAutoId().
                    let newUserRef = self.userRef.child(uid!)
                    //Create a dictionary to hold the data for this channel. A [String: AnyObject] works as a JSON-like object.
                    let data = ["photoUrl": user!.photoURL!.absoluteString,
                                "name": user!.displayName!,
                                "email": user!.email!]
                    //Finally, set the name on this new channel, which is saved to Firebase automatically!
                    newUserRef.setValue(data)
                }
            })
            if nextStage {
                SVProgressHUD.dismiss()
                let mainStoryboard: UIStoryboard = UIStoryboard(name:"Main", bundle: nil)
                self.window?.rootViewController?.performSegue(withIdentifier: "SetUsername", sender: nil)
            }
        })
    }
    
    
    
    
    
    
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
    
}

