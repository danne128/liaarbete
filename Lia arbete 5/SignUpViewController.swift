//
//  SignUpViewController.swift
//  Lia arbete 5
//
//  Created by Daniel Trondsen Wallin on 2016-10-09.
//  Copyright © 2016 Daniel Trondsen Wallin. All rights reserved.
//

import UIKit
import Parse
import ParseFacebookUtilsV4

class SignUpViewController: UIViewController, FBSDKLoginButtonDelegate, UITextFieldDelegate {
    
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var somethingWrongLabel: UILabel!
    
    var fullName: String = ""
    var facebookEmail: String = ""
    
    var numberWithOutSpace: String = ""
    var numberWithOutSpaceAndDash: String = ""
    
    var moveOn: Bool = false
    var moveOnWithFacebook: Bool = false
    
    
    /*let loginButton: FBSDKLoginButton = {
        let button = FBSDKLoginButton()
        button.readPermissions = ["email", "user_friends"]
        return button
    }()*/
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        somethingWrongLabel.text = nil
        
        emailTextField.delegate = self
        phoneNumberTextField.delegate = self
        passwordTextField.delegate = self
        
        
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 180, height: 40)
        button.setTitle("Sign up with facebook", for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.sizeToFit()
        button.center = self.view.center
        button.frame.origin.y -= 20
        button.backgroundColor = UIColor(red: 59/255, green: 89/255, blue: 152/255, alpha: 1.0)
        button.addTarget(self, action: #selector(SignUpViewController.fetchProfile), for: .touchUpInside)
        view.addSubview(button)
        
        NotificationCenter.default.addObserver(self, selector: #selector(SignUpViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SignUpViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dissmissKeyboard))
        self.view.addGestureRecognizer(tap)
        
        // Do any additional setup after loading the view.
    }
    
    func dissmissKeyboard() {
        emailTextField.resignFirstResponder()
        phoneNumberTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        phoneNumberTextField.resignFirstResponder()
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        somethingWrongLabel.text = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "moveToCompleteInformation") {
            let destination = segue.destination as! CompleteInformationViewController
            
            destination.email = emailTextField.text!
            destination.phone = phoneNumberTextField.text!
            destination.password = passwordTextField.text!
            
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
                            print(error as Any)
                            self.moveOn = false
                            return
                        }
                        
                        guard let resultNew = result as? [String:Any] else {
                            return
                        }
                        
                        if let firstName = resultNew["first_name"] as? String, let lastName = resultNew["last_name"] as? String, let email = resultNew["email"] as? String {
                            self.fullName = firstName + " " + lastName
                            user.email = email
                            user["fullname"] = self.fullName
                            user["FBandParse"] = false
                            user.saveInBackground(block: { (success, error) in
                                if success == true {
                                    self.moveOnWithFacebook = true
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
                                            PFUser.logOut()
                                        }
                                    })
                                }
                            })
                        }
                    }
                }
                else {
                    print("old user")
                    self.moveOnWithFacebook = true
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
            performSegue(withIdentifier: "moveToCompleteInformation", sender: self)
        }
        else if moveOnWithFacebook == true {
            performSegue(withIdentifier: "SignedUpWithFacebook", sender: self)
        }
    }
    
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if FBSDKAccessToken.current() != nil {
            performSegue(withIdentifier: "SignedUpWithFacebook", sender: self)
        }
        
    }
    
    func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool {
        return false
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        
    }
    
    
    func validateEmail(_ candidate: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: candidate)
    }
    
    func validatePhoneNumber(_ candidate: String) -> Bool {
        let phoneRegex = "^\\d{10}$"
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: candidate)
    }
    
    
    
    @IBAction func continueWasClicked(_ sender: AnyObject) {
        
        self.dissmissKeyboard()
        
        somethingWrongLabel.text = ""
        
        numberWithOutSpace = phoneNumberTextField.text!.replacingOccurrences(of: " ", with: "")
        numberWithOutSpaceAndDash = numberWithOutSpace.replacingOccurrences(of: "-", with: "")
        
        guard let check = emailTextField.text, let check2 = passwordTextField.text, let check3 = phoneNumberTextField.text , !check.isEmpty && !check2.isEmpty && !check3.isEmpty else {
            
            if emailTextField.text == "" {
                somethingWrongLabel.text = "Your email field is empty"
            }
            else if phoneNumberTextField.text == "" {
                somethingWrongLabel.text = "Your phonenumber field is empty"
            }
            else if passwordTextField.text == "" {
                somethingWrongLabel.text = "Your password field is empty"
            }
            
            moveOn = false
            //print("Something went wrong")
            return
        }
        
        if (validateEmail(emailTextField.text!) == true) && (validatePhoneNumber(numberWithOutSpaceAndDash) == true) {
            
            self.moveOn = true
            seeIfMoveOnAvailable()
            
        }
        else if (validateEmail(emailTextField.text!) == false) {
            somethingWrongLabel.text = "Your email is invalid"
        }
        else if (validatePhoneNumber(numberWithOutSpaceAndDash) == false) {
            somethingWrongLabel.text = "Your phone number is invalid"
        }
        
    }
    

}
