//
//  CompleteInformationViewController.swift
//  Lia arbete 5
//
//  Created by Daniel Trondsen Wallin on 2016-10-09.
//  Copyright © 2016 Daniel Trondsen Wallin. All rights reserved.
//

import UIKit
import Parse

class CompleteInformationViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    @IBOutlet weak var somethingWrongLabel: UILabel!
    
    @IBOutlet weak var profilePictureImageView: UIImageView!
    
    var numberWithOutSpace: String = ""
    var numberWithOutSpaceAndDash: String = ""
    
    var email: String = ""
    var password: String = ""
    var phone: String = ""
    var fullName: String = ""
    
    var moveOn: Bool = false
    var facebookMoveOn: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        PFUser.registerSubclass()
        
        somethingWrongLabel.text = nil
        
        moveOn = false
        facebookMoveOn = false
        
        emailTextField.text = email
        passwordTextField.text = password
        phoneNumberTextField.text = phone
        fullNameTextField.text = fullName
        // Do any additional setup after loading the view.
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        phoneNumberTextField.delegate = self
        fullNameTextField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(CompleteInformationViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CompleteInformationViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        profilePictureImageView.frame.size.width = 100
        profilePictureImageView.frame.size.height = 100
        profilePictureImageView.layer.masksToBounds = true
        profilePictureImageView.layer.cornerRadius = profilePictureImageView.frame.width / 2
        let image = UIImage(named: "defaultPhoto.png")
        profilePictureImageView.image = image
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(CompleteInformationViewController.imageTapped(_:)))
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dissmissKeyboard))
        self.view.addGestureRecognizer(tap)
        
        profilePictureImageView.addGestureRecognizer(tapGesture)
        profilePictureImageView.isUserInteractionEnabled = true
        
        if FBSDKAccessToken.current() != nil {
            fetchProfile()
        }
        
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
        fullNameTextField.resignFirstResponder()
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
    
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return moveOn
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "moveOnToWelcome") {
            let destination = segue.destination as! WelcomePageViewController
            
            destination.name = fullNameTextField.text!
        }
    }
    
    func imageTapped(_ gesture: UIGestureRecognizer) {
        
        if (gesture.view as? UIImageView) != nil {
            //print("Image tapped")
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
                
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
                imagePicker.allowsEditing = true
                self.present(imagePicker, animated: true, completion: nil)
            }
        }
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        profilePictureImageView.image = image
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func seeIfMoveOnAvailable() {
        if moveOn == true {
             performSegue(withIdentifier: "moveOnToWelcome", sender: self)
        }
        
        if facebookMoveOn == true {
            performSegue(withIdentifier: "ContinueWithFacebook", sender: self)
        }
    }
    
    
    
    func fetchProfile() {
        
        let parameters = ["fields": "first_name, last_name, email, picture.type(large)"]
        FBSDKGraphRequest(graphPath: "me", parameters: parameters).start { (connection, result, error) in
            
            if error != nil {
                print(error as Any)
                let loginManager = FBSDKLoginManager()
                loginManager.logOut()
                _ = self.navigationController?.popViewController(animated: true)
                return
            }
            
            guard let resultNew = result as? [String:Any] else {
                return
            }
            
            if let firstName = resultNew["first_name"] as? String, let lastName = resultNew["last_name"] as? String, let email = resultNew["email"] as? String, let picture = resultNew["picture"] as? NSDictionary, let data = picture["data"] as? NSDictionary, let url = data["url"] as? String {
                
                //print(picture)
                self.fullNameTextField.text = firstName + " " + lastName
                self.emailTextField.text = email
                let picURL = NSURL(string: url)
                let data = NSData(contentsOf: picURL! as URL)
                self.profilePictureImageView.image = UIImage(data: data! as Data)
                
            }
        }
    }
    
    
    
    
    func validateEmail(_ candidate: String) -> Bool {
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: candidate)
    }
    
    func validatePhoneNumber(_ candidate: String) -> Bool {
        let phoneRegex = "^\\d{10}$"
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: candidate)
    }
    
    
    @IBAction func doneButtonWasPressed(_ sender: AnyObject) {
        
        self.dissmissKeyboard()
        
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        
        somethingWrongLabel.text = ""
        
        numberWithOutSpace = phoneNumberTextField.text!.replacingOccurrences(of: " ", with: "")
        numberWithOutSpaceAndDash = numberWithOutSpace.replacingOccurrences(of: "-", with: "")
        
        
        guard let check = fullNameTextField.text, let check2 = emailTextField.text, let check3 = passwordTextField.text, let check4 = phoneNumberTextField.text , !check.isEmpty && !check2.isEmpty && !check3.isEmpty && !check4.isEmpty else {
            
            if fullNameTextField.text == "" {
                somethingWrongLabel.text = "Your full name field is empty"
            }
            else if emailTextField.text == "" {
                somethingWrongLabel.text = "Your email field is empty"
            }
            else if passwordTextField.text == "" {
                somethingWrongLabel.text = "Your password field is empty"
            }
            else if phoneNumberTextField.text == "" {
                somethingWrongLabel.text = "Your phonenumber field is empty"
            }
            
            
            moveOn = false
            //print("NAHASDASD")
            return
        }
        
        if (validateEmail(emailTextField.text!) == true) && (validatePhoneNumber(numberWithOutSpaceAndDash) == true) {
            
            let newUser = PFUser()
            
            newUser.email = emailTextField.text
            newUser.password = passwordTextField.text
            newUser.username = emailTextField.text
            newUser["phone"] = phoneNumberTextField.text
            newUser["fullname"] = fullNameTextField.text
            newUser["FBandParse"] = false
            
            newUser.signUpInBackground(block: { (succeed, error) in
                
                if error != nil {
                    self.somethingWrongLabel.text = "\(error!.localizedDescription)"
                }
                else {
                    self.moveOn = true
                    self.seeIfMoveOnAvailable()
                }
                
            })
            
        }
        else if (validateEmail(emailTextField.text!) == false) {
            somethingWrongLabel.text = "Your email is invalid"
        }
        else if (validatePhoneNumber(numberWithOutSpaceAndDash) == false) {
            somethingWrongLabel.text = "Your phone number is invalid"
        }
    }
    
    
    @IBAction func ContinueWithFacebookWasPressed(_ sender: AnyObject) {
        
        self.dissmissKeyboard()
        
        if FBSDKAccessToken.current() != nil {
            facebookMoveOn = true
            seeIfMoveOnAvailable()
        }
        else if (FBSDKAccessToken.current() == nil){
            let facebookLoginManager: FBSDKLoginManager = FBSDKLoginManager()
            facebookLoginManager.logIn(withReadPermissions: ["email"], from: self, handler: { (result, error) in
                if error == nil {
                    if (result?.isCancelled)! {
                        return
                    }
                    else {
                        print("logged in through facebook")
                        self.facebookMoveOn = true
                        self.seeIfMoveOnAvailable()
                    }
                }
                else {
                    print(error as Any)
                    return
                }
            })
        }
    }

}










