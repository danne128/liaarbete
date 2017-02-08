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

class WelcomePageViewController: UIViewController, FBSDKAppInviteDialogDelegate, UIGestureRecognizerDelegate {
    
    var name: String = ""
    var moveOn: Bool = false
    var email: String = ""
    var objectID: String = ""
    
    var menuShowing: Bool = false
    
    var friendsName: [NSString] = []
    var profilePictures: [UIImage] = []
    
    let disconnectFromFacebookButton = UIButton()

    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var inviteFriendsButton: UIButton!
    @IBOutlet weak var inviteFriendsOwnButton: UIButton!
    @IBOutlet weak var mapsButton: UIButton!
    @IBOutlet weak var connectWithFacebookButton: UIButton!
    @IBOutlet weak var customLoginButton: UIButton!
    
    @IBOutlet weak var menuView: UIView!
    
    
    @IBOutlet weak var leadingConstrait: NSLayoutConstraint!
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        menuView.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        menuView.isHidden = true
        self.dismissMenu()
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        disconnectFromFacebookButton.frame = CGRect(x: connectWithFacebookButton.frame.origin.x, y: connectWithFacebookButton.frame.origin.y, width: connectWithFacebookButton.frame.width, height: connectWithFacebookButton.frame.height)
        disconnectFromFacebookButton.setTitle("Disconnect from facebook", for: .normal)
        disconnectFromFacebookButton.titleLabel!.font = connectWithFacebookButton.titleLabel!.font
        disconnectFromFacebookButton.titleLabel!.textColor = connectWithFacebookButton.titleLabel!.textColor
        disconnectFromFacebookButton.titleLabel!.numberOfLines = 1
        disconnectFromFacebookButton.titleLabel!.adjustsFontSizeToFitWidth = true
        disconnectFromFacebookButton.titleLabel!.lineBreakMode = NSLineBreakMode.byClipping
        disconnectFromFacebookButton.addTarget(self, action: #selector(WelcomePageViewController.disconnectFromFacebook), for: .touchUpInside)
        disconnectFromFacebookButton.isHidden = true
        menuView.addSubview(disconnectFromFacebookButton)
        
        
        
        fullNameLabel.text = name
        
        self.navigationItem.hidesBackButton = true
        
        if FBSDKAccessToken.current() != nil {
            if let user = PFUser.current()?["FBandParse"] as? Bool {
                if user == true {
                    connectWithFacebookButton.isHidden = true
                    customLoginButton.isHidden = true
                    disconnectFromFacebookButton.isHidden = false
                }
                else {
                    inviteFriendsButton.isEnabled = true
                    inviteFriendsOwnButton.isEnabled = false
                    connectWithFacebookButton.isHidden = true
                    customLoginButton.isHidden = false
                }
            }
            
        }
        else if FBSDKAccessToken.current() == nil {
            connectWithFacebookButton.isHidden = false
            customLoginButton.isHidden = true
        }

        // Do any additional setup after loading the view.
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissMenu))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        fetchUserProfile()
        
        
        
        
    }
    
    
    func fetchUserProfile() {
        
        if let fullname = PFUser.current()?["fullname"] as? String {
            
            self.fullNameLabel.text = fullname
            
        }
    }
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchPoint: CGPoint = touch.location(in: self.view)
        return !menuView.frame.contains((touchPoint))
    }
    
    
    func dismissMenu() {
        
        if menuShowing == true {
            
            leadingConstrait.constant = -200
            
            menuView.layer.shadowOpacity = 0.0
            menuView.layer.shadowRadius = 6
            UIView.animate(withDuration: 0.3, animations: {
                self.view?.backgroundColor = UIColor(white: 1, alpha: 1.0)
                self.view.layoutIfNeeded()
            })
            
            menuShowing = false
            
        }
    }
    
    
    
    func disconnectFromFacebook() {
        PFFacebookUtils.unlinkUser(inBackground: PFUser.current()!) { (success, error) in
            if error != nil {
                print(error!.localizedDescription as Any)
            }
            else if success == true {
                let user = PFUser.current()
                user?["FBandParse"] = false
                user?.saveInBackground(block: { (success, error) in
                    if error != nil {
                        print(error!.localizedDescription as Any)
                    }
                    else {
                        self.disconnectFromFacebookButton.isHidden = true
                        self.connectWithFacebookButton.isHidden = false
                        print("success")
                    }
                })
            }
        }
    }
    
    
    
    
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
                    
                    //print("\n \(self.objectID) \n")
                    // Use the ObjectID to update the users location to the new one
                    
                    let newQuery = PFQuery(className: "UserLocations")
                    newQuery.getObjectInBackground(withId: self.objectID, block: { (object, error) in
                        object?.deleteInBackground()
                        
                        PFUser.logOut()
                        print("logged out")
                        
                        self.dismiss(animated: true, completion: {})
                        _ = self.navigationController?.popToRootViewController(animated: true)
                        
                    })
                }
                else {
                    
                    PFUser.logOut()
                    print("logged out")
                    
                    self.dismiss(animated: true, completion: {})
                    _ = self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
        else {
            /*let loginManager = FBSDKLoginManager()
            loginManager.logOut()*/
            
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
                user?["phone"] = "0987654321"
                user?["FBandParse"] = true
                user?.saveInBackground(block: { (success, error) in
                    if error != nil {
                        print(error!.localizedDescription as Any)
                        PFFacebookUtils.unlinkUser(inBackground: PFUser.current()!, block: { (success, error) in
                            if error != nil {
                                print(error!.localizedDescription as Any)
                            }
                            else {
                                print("success unlinking account")
                            }
                        })
                    }
                    else {
                        print("success")
                        self.connectWithFacebookButton.isHidden = true
                        self.customLoginButton.isHidden = true
                        self.inviteFriendsButton.isEnabled = true
                        self.disconnectFromFacebookButton.isHidden = false
                        self.dismissMenu()
                    }
                })
            }
        }
    }
    
    
    
    @IBAction func createACustomLogin(_ sender: Any) {
        let alert = UIAlertController(title: "Notice", message: "Share Location", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addTextField { (emailTextfield) in
            emailTextfield.text = (PFUser.current()?.email)! as String
            emailTextfield.isEnabled = false
        }
        
        alert.addTextField { (phoneTextfield) in
            phoneTextfield.keyboardType = UIKeyboardType.numberPad
            phoneTextfield.placeholder = "0701234567"
        }
        
        alert.addTextField { (socialTextfield) in
            socialTextfield.placeholder = "19901212"
        }
        
        alert.addTextField { (passwordTexfield) in
            passwordTexfield.isSecureTextEntry = true
            passwordTexfield.placeholder = "Password"
        }
        
        alert.addAction(UIAlertAction(title: "Save login", style: UIAlertActionStyle.default, handler: { (handler) in
            
            
            if let emailTextfield = alert.textFields?[0].text, !emailTextfield.isEmpty, let phoneTextfield = alert.textFields?[1].text, !phoneTextfield.isEmpty, let socialTextfield = alert.textFields?[2].text, !socialTextfield.isEmpty, let passwordTextfield = alert.textFields?[3].text, !passwordTextfield.isEmpty  {
                
                PFFacebookUtils.linkUser(inBackground: PFUser.current()!, with: FBSDKAccessToken.current()) { (success, error) in
                    if error != nil {
                        print(error!.localizedDescription as Any)
                    }
                    else {
                        let user = PFUser.current()
                        let personalNumber = Int(socialTextfield)
                        user?.password = passwordTextfield
                        user?.username = emailTextfield
                        user?["personnummer"] = personalNumber
                        user?["phone"] = phoneTextfield
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
                                self.disconnectFromFacebookButton.isHidden = false
                                self.dismissMenu()
                            }
                        })
                    }
                }
                
            }
            else {
                print("error")
                return
            }
            
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        
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
