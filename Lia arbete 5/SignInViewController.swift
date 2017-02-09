//
//  SignInViewController.swift
//  Lia arbete 5
//
//  Created by Daniel Trondsen Wallin on 2016-10-09.
//  Copyright © 2016 Daniel Trondsen Wallin. All rights reserved.
//

import UIKit
import Parse
import ParseFacebookUtilsV4

class SignInViewController: UIViewController, FBSDKLoginButtonDelegate, UITextFieldDelegate {
    
    
    var moveOn: Bool = false
    var moveOnParse: Bool = false
    var fullName: String = ""

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var somethingWrongLabel: UILabel!
    
    /*let loginButton: FBSDKLoginButton = {
        let button = FBSDKLoginButton()
        button.readPermissions = ["email", "user_friends"]
        return button
    }()*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 180, height: 40)
        button.setTitle("Log in with facebook", for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.sizeToFit()
        button.center = self.view.center
        button.backgroundColor = UIColor(red: 59/255, green: 89/255, blue: 152/255, alpha: 1.0)
        button.addTarget(self, action: #selector(SignInViewController.fetchProfile), for: .touchUpInside)
        view.addSubview(button)
        
        
        /*view.addSubview(loginButton)
        loginButton.center = view.center
        loginButton.delegate = self*/
        
        somethingWrongLabel.text = nil
        
        if FBSDKAccessToken.current() != nil {
            fetchProfile()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(SignUpViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SignUpViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dissmissKeyboard))
        self.view.addGestureRecognizer(tap)
        
        // Do any additional setup after loading the view.
    }
    
    
    func dissmissKeyboard() {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()

        return true
    }
    
    
    func keyboardWillShow(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
    
    
    func fetchProfile() {
        PFFacebookUtils.logInInBackground(withReadPermissions: ["email", "public_profile", "user_friends"]) { (user, error) in
            
            if let user = user {
                if user.isNew {
                    print("new user")
                    let parameters = ["fields": "first_name, last_name, email"]
                    FBSDKGraphRequest(graphPath: "me", parameters: parameters).start { (connection, result, error) in
                        
                        if error != nil {
                            print(error!.localizedDescription as Any)
                            self.moveOn = false
                            return
                        }
                        
                        guard let resultNew = result as? [String:Any] else {
                            print("error")
                            return
                        }
                        
                        if let firstName = resultNew["first_name"] as? String, let lastName = resultNew["last_name"] as? String, let email = resultNew["email"] as? String {
                            self.fullName = firstName + " " + lastName
                            user.email = email
                            user["fullname"] = self.fullName
                            user["FBandParse"] = false
                            user.saveInBackground(block: { (success, error) in
                                if success == true {
                                    self.moveOn = true
                                    self.seeIfMoveOnAvailable()
                                }
                                else {
                                    print(error!.localizedDescription as Any)
                                    self.somethingWrongLabel.text = error!.localizedDescription
                                    self.somethingWrongLabel.numberOfLines = 1
                                    self.somethingWrongLabel.adjustsFontSizeToFitWidth = true
                                    self.somethingWrongLabel.lineBreakMode = NSLineBreakMode.byClipping
                                    PFUser.current()?.deleteInBackground(block: { (success, error) in
                                        if error != nil {
                                            print(error!.localizedDescription as Any)
                                        }
                                        else {
                                            let facebookRequest: FBSDKGraphRequest! = FBSDKGraphRequest(graphPath: "/me/permissions", parameters: nil, httpMethod: "DELETE")
                                            
                                            facebookRequest.start(completionHandler: { (connection, result, error) in
                                                if error != nil {
                                                    print(error!.localizedDescription as Any)
                                                }
                                                else if error == nil && result != nil {
                                                    print("facebook disconnected")
                                                    PFUser.logOut()
                                                }
                                            })
                                        }
                                    })
                                }
                            })
                        }
                    }
                }
                else {
                    print("old user")
                    self.moveOn = true
                    self.seeIfMoveOnAvailable()
                }
            }
            else {
                print("didn't work")
                PFUser.logOut()
            }
            
        }
    }


    func seeIfMoveOnAvailable() {
        if moveOn == true {
            performSegue(withIdentifier: "signInFacebookToWelcome", sender: self)
        }
        else if moveOnParse == true {
            performSegue(withIdentifier: "signInParseToWelcome", sender: self)
        }
    }
    

    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        fetchProfile()
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        
    }
    
    func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool {
        return false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func signInWasPressed(_ sender: AnyObject) {
        
        self.dissmissKeyboard()
        
        somethingWrongLabel.text = nil
        let email = emailTextField.text!
        let password = passwordTextField.text!
        
        PFUser.logInWithUsername(inBackground: email, password: password) { (user, error) in
            if error != nil {
                self.somethingWrongLabel.text = error!.localizedDescription
            }
            else {
                self.moveOnParse = true
                self.seeIfMoveOnAvailable()
            }
        }
    }
    
    
}
