//
//  SignInViewController.swift
//  Lia arbete 5
//
//  Created by Daniel Trondsen Wallin on 2016-10-09.
//  Copyright © 2016 Daniel Trondsen Wallin. All rights reserved.
//

import UIKit
import Parse

class SignInViewController: UIViewController, FBSDKLoginButtonDelegate, UITextFieldDelegate {
    
    
    var moveOn: Bool = false
    var moveOnParse: Bool = false
    var fullName: String = ""

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var somethingWrongLabel: UILabel!
    
    let loginButton: FBSDKLoginButton = {
        let button = FBSDKLoginButton()
        button.readPermissions = ["email", "user_friends"]
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(loginButton)
        loginButton.center = view.center
        loginButton.delegate = self
        
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
        
        let parameters = ["fields": "first_name, last_name"]
        FBSDKGraphRequest(graphPath: "me", parameters: parameters).start { (connection, result, error) in
            
            if error != nil {
                print(error as Any)
                self.moveOn = false
                return
            }
            
            guard let resultNew = result as? [String:Any] else {
                return
            }
            
            if let firstName = resultNew["first_name"] as? String, let lastName = resultNew["last_name"] as? String {
             self.fullName = firstName + " " + lastName
             self.moveOn = true
             self.seeIfMoveOnAvailable()
            
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
        return true
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
