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
import UserNotifications
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    
    var window: UIWindow?
    private lazy var userRef: DatabaseReference = Database.database().reference().child("users")
    var databaseRef: DatabaseReference!
    let kUserDefault = UserDefaults.standard
    var pushToken: String?
    var filePath: String = String() {
        didSet {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshView"), object: nil)
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            // For iOS 10 data message (sent via FCM
            Messaging.messaging().remoteMessageDelegate = self
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        FirebaseApp.configure()
        
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        Database.database().isPersistenceEnabled = true
        
        pushToken = Messaging.messaging().fcmToken
        print("FCM token: \(pushToken ?? "")")
        /*
        let signInMethod = kUserDefault.bool(forKey: "isGoogleSignIn")
        print(signInMethod)
        if (signInMethod){
            GIDSignIn.sharedInstance().signInSilently()
            let mainStoryboard: UIStoryboard = UIStoryboard(name:"Main", bundle: nil)
            let viewController = mainStoryboard.instantiateViewController(withIdentifier: "vcLogin") as UIViewController
            self.window?.rootViewController = viewController
            self.window?.makeKeyAndVisible()
            
            //self.window?.rootViewController?.performSegue(withIdentifier: "SignInToChat", sender: nil)
        }
 */
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if(url.scheme!.isEqual("fb183677615483082")) {
            return FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
            
        } else {
            return GIDSignIn.sharedInstance().handle(url as URL!,
                                                     sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String!,
                                                     annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        }
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
                                "onlineStatus": "",
                                "pushToken": Messaging.messaging().fcmToken]
                    //Finally, set the name on this new channel, which is saved to Firebase automatically!
                    newUserRef.setValue(data)
                    nextStage = true
                    
                }
                self.kUserDefault.set(true, forKey: "isGoogleSignIn")
                self.kUserDefault.set(false, forKey: "isFacebookSignIn")
                self.kUserDefault.synchronize()
                
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
    
    // Called when APNs has assigned the device a unique token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        InstanceID.instanceID().setAPNSToken(deviceToken, type: InstanceIDAPNSTokenType.sandbox)
        // Convert token to string
        //pushToken = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        
        // Print it to console
        // print("APNs device token: \(pushToken)")
        
        // Persist it in your backend in case it's new
    }
    
    // Called when APNs failed to register the device for push notifications
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Print the error to console (you should alert the user that registration failed)
        print("APNs registration failed: \(error)")
    }
    
    
    
    // The callback to handle data message received via FCM for devices running iOS 10 or above.
    func application(received remoteMessage: MessagingRemoteMessage) {
        print(remoteMessage.appData)
    }
    

    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
    }
    
    func application(application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        Messaging.messaging().apnsToken = deviceToken as Data
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
//        if let messageID = userInfo[gcmMessageIDKey] {
//            print("Message ID: \(messageID)")
//        }
        
        // Print full message.
        print("Push notification received: \(userInfo)")
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
//        if let messageID = userInfo[gcmMessageIDKey] {
//            print("Message ID: \(messageID)")
//        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }

    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
    
}

