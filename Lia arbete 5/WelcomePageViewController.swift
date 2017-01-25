//
//  WelcomePageViewController.swift
//  Lia arbete 5
//
//  Created by Daniel Trondsen Wallin on 2016-10-09.
//  Copyright © 2016 Daniel Trondsen Wallin. All rights reserved.
//

import UIKit
import Parse

class WelcomePageViewController: UIViewController, FBSDKAppInviteDialogDelegate {
    
    var name: String = ""
    var moveOn: Bool = false
    var email: String = ""
    var objectID: String = ""
    
    
    var friendsName: [NSString] = []
    var profilePictures: [UIImage] = []

    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var inviteFriendsButton: UIButton!
    @IBOutlet weak var inviteFriendsOwnButton: UIButton!
    @IBOutlet weak var mapsButton: UIButton!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fullNameLabel.text = name
        
        self.navigationItem.hidesBackButton = true
        
        if FBSDKAccessToken.current() != nil {
            fetchProfile()
            inviteFriendsButton.isEnabled = true
            inviteFriendsOwnButton.isEnabled = true
        }
        
        if PFUser.current() != nil {
            fetchUserProfile()
            mapsButton.isEnabled = true
            
            if let userEmail = PFUser.current()?["email"] as? String {
                self.email = userEmail
            }
            
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
                        
                        object?.deleteInBackground()
                        
                        let loginManager = FBSDKLoginManager()
                        loginManager.logOut()
                        
                        PFUser.logOut()
                        print("logged out")
                        
                        self.dismiss(animated: true, completion: {})
                        _ = self.navigationController?.popToRootViewController(animated: true)
                        
                    })
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
    
    
    @IBAction func inviteFriendsWithFacebook(_ sender: AnyObject) {
        let content = FBSDKAppInviteContent()
        content.appLinkURL = URL(string: "https://fb.me/629949127184048")
        FBSDKAppInviteDialog.show(from: self, with: content, delegate: self)
    }
    
    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [AnyHashable: Any]!) {
        print("succesfully invited people")
    }
    
    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: Error!) {
        print("it did not work")
    }
    
    
}
