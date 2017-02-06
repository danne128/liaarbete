//
//  WelcomePageViewController.swift
//  Lia arbete 5
//
//  Created by Daniel Trondsen Wallin on 2016-10-09.
//  Copyright © 2016 Daniel Trondsen Wallin. All rights reserved.
//

import UIKit
import Parse
import ParseFacebookUtilsV4

class WelcomePageViewController: UIViewController, FBSDKAppInviteDialogDelegate {
    
    var name: String = ""
    var moveOn: Bool = false
    var email: String = ""
    var objectID: String = ""
    
    var menuShowing: Bool = false
    
    var friendsName: [NSString] = []
    var profilePictures: [UIImage] = []

    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var inviteFriendsButton: UIButton!
    @IBOutlet weak var inviteFriendsOwnButton: UIButton!
    @IBOutlet weak var mapsButton: UIButton!
    @IBOutlet weak var connectWithFacebookButton: UIButton!
    @IBOutlet weak var customLoginButton: UIButton!
    @IBOutlet weak var menuView: UIView!
    
    
    @IBOutlet weak var leadingConstrait: NSLayoutConstraint!
    
    
    
    @IBAction func openMenu(_ sender: Any) {
        
        if menuShowing {
            leadingConstrait.constant = -200
            
            menuView.layer.shadowOpacity = 0.0
            menuView.layer.shadowRadius = 6
            UIView.animate(withDuration: 0.3, animations: {
                self.view?.backgroundColor = UIColor(white: 1, alpha: 1.0)
                self.view.layoutIfNeeded()
            })
            
        }
        else {
            leadingConstrait.constant = 0
            
            menuView.layer.shadowOpacity = 1.0
            menuView.layer.shadowRadius = 6
            UIView.animate(withDuration: 0.3, animations: {
                self.view?.backgroundColor = UIColor(white: 1, alpha: 0.3)
                self.view.layoutIfNeeded()
            })
            
        }
        
        menuShowing = !menuShowing
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        menuView.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        menuView.isHidden = true
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fullNameLabel.text = name
        
        self.navigationItem.hidesBackButton = true
        
        if FBSDKAccessToken.current() != nil {
            inviteFriendsButton.isEnabled = true
            inviteFriendsOwnButton.isEnabled = false
            connectWithFacebookButton.isHidden = true
            customLoginButton.isHidden = false
            print("fb log in")
        }
        
        if PFUser.current() != nil {
            fetchUserProfile()
            mapsButton.isEnabled = true
            inviteFriendsButton.isEnabled = true
            print("parse log in")
            if let userEmail = PFUser.current()?["email"] as? String {
                self.email = userEmail
            }
            
        }
        
        
        if PFUser.current() != nil && FBSDKAccessToken.current() != nil {
            if let user = PFUser.current()?["FBandParse"] as? Bool {
                if user == true {
                    connectWithFacebookButton.isHidden = true
                    customLoginButton.isHidden = true
                }
            }
        }
        else if PFUser.current() != nil && FBSDKAccessToken.current() == nil {
            connectWithFacebookButton.isHidden = false
            customLoginButton.isHidden = true
        }

        // Do any additional setup after loading the view.
    }
    
    func fetchUserProfile() {
        
        if let fullname = PFUser.current()?["fullname"] as? String {
            
            self.fullNameLabel.text = fullname
            
        }
    }
    
    
    func fetchProfile() {
        
        let parameters = ["fields": "first_name, last_name, name"]
        FBSDKGraphRequest(graphPath: "me", parameters: parameters).start { (connection, result, error) in
            
            if error != nil {
                print(error as Any)
                return
            }
            
            guard let resultNew = result as? [String:Any] else {
                return
            }
            
            if let firstName = resultNew["first_name"] as? String, let lastName = resultNew["last_name"] as? String {
                self.fullNameLabel.text = firstName + " " + lastName
                
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func logoutButtonWasClicked(_ sender: AnyObject) {
        if PFUser.current() != nil {
            let query = PFQuery(className: "UserLocations")
            query.whereKey("userEmail", equalTo: self.email)
            
            // Get all the information with the logged in users email
            query.findObjectsInBackground { (objects, error) in
                if error != nil {
                    print(error!.localizedDescription)
                    return
                }
                // See if user already has saved position
                else if (objects?.count)! > 0 {
                    print("already exist")
                    
                    if let returnedObjects = objects {
                        for object in returnedObjects {
                            // Get the users ObjectID
                            self.objectID = object.objectId!
                        }
                    }
                    
                    print("\n \(self.objectID) \n")
                    // Use the ObjectID to update the users location to the new one
                    
                    let newQuery = PFQuery(className: "UserLocations")
                    newQuery.getObjectInBackground(withId: self.objectID, block: { (object, error) in
                        print("6")
                        object?.deleteInBackground()
                        
                        let loginManager = FBSDKLoginManager()
                        loginManager.logOut()
                        
                        PFUser.logOut()
                        print("logged out")
                        
                        self.dismiss(animated: true, completion: {})
                        _ = self.navigationController?.popToRootViewController(animated: true)
                        
                    })
                }
                else {
                    let loginManager = FBSDKLoginManager()
                    loginManager.logOut()
                    
                    PFUser.logOut()
                    print("logged out")
                    
                    self.dismiss(animated: true, completion: {})
                    _ = self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
        else {
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
            
            PFUser.logOut()
            print("logged out")
            
            self.dismiss(animated: true, completion: {})
            _ = self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    
    @IBAction func connectWithFacebook(_ sender: Any) {
        
        PFFacebookUtils.linkUser(inBackground: PFUser.current()!, withReadPermissions: ["public_profile", "email"]) { (success, error) in
            if error != nil {
                print(error!.localizedDescription as Any)
            }
            else if success == true {
                let user = PFUser.current()
                user?.password = "test"
                user?["personnummer"] = 123456789012
                user?["phone"] = 0987654321
                user?["FBandParse"] = true
                user?.saveInBackground(block: { (success, error) in
                    if error != nil {
                        print(error!.localizedDescription as Any)
                    }
                    else {
                        print("success")
                        self.connectWithFacebookButton.isHidden = true
                        self.customLoginButton.isHidden = true
                        self.inviteFriendsButton.isEnabled = true
                    }
                })
            }
        }
    }
    
    
    @IBAction func createACustomLogin(_ sender: Any) {
        
        
        PFFacebookUtils.linkUser(inBackground: PFUser.current()!, with: FBSDKAccessToken.current()) { (success, error) in
            if error != nil {
                print(error!.localizedDescription as Any)
            }
            else {
                let user = PFUser.current()
                
                user?.password = "test"
                user?.username = "danne_tw@hotmail.com"
                user?["personnummer"] = 123456789012
                user?["phone"] = "0987654321"
                user?["FBandParse"] = true
                user?.saveInBackground(block: { (success, error) in
                    print("hej")
                    if error != nil {
                        print(error!.localizedDescription as Any)
                    }
                    else {
                        print("success")
                        self.connectWithFacebookButton.isHidden = true
                        self.customLoginButton.isHidden = true
                        self.inviteFriendsButton.isEnabled = true
                    }
                })
            }
        }
        
    }
    
    
    
    
    @IBAction func inviteFriendsWithFacebook(_ sender: AnyObject) {
        let content = FBSDKAppInviteContent()
        content.appLinkURL = URL(string: "https://fb.me/629949127184048")
        FBSDKAppInviteDialog.show(from: self, with: content, delegate: self)
        
        /*PFFacebookUtils.logInInBackground(withReadPermissions: ["public_profile", "email"]) { (user, error) in
            print(user as Any)
        }*/
    }
    
    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [AnyHashable: Any]!) {
        print("succesfully invited people")
    }
    
    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: Error!) {
        print("it did not work")
    }
    
    
}
