//
//  ViewController.swift
//  Lia arbete 5
//
//  Created by Daniel Trondsen Wallin on 2016-10-09.
//  Copyright © 2016 Daniel Trondsen Wallin. All rights reserved.
//

import UIKit
import Parse

class ViewController: UIViewController {
    
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.isToolbarHidden = true
        
        signInButton.setTitleColor(UIColor.init(red: 138.0/255.0, green: 141/255.0, blue: 143.0/255.0, alpha: 1.0), for: UIControlState())
        signUpButton.setTitleColor(UIColor.init(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0), for: UIControlState())
        
        signInButton.backgroundColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        signUpButton.backgroundColor = UIColor(red: 217.0/255.0, green: 33.0/255.0, blue: 91.0/255.0, alpha: 1.0)
        
        view.backgroundColor = UIColor(red: 73.0/255.0, green: 114.0/255.0, blue: 207.0/255.0, alpha: 1.0)
        
        titleLabel.textColor = UIColor.white
        
        if PFUser.current() != nil {
            PFSession.getCurrentSessionInBackground(block: { (session, error) in
                if error != nil {
                    PFUser.logOut()
                    print(error!.localizedDescription as Any)
                }
                else if session != nil {
                    self.performSegue(withIdentifier: "UserAlreadyLoggedIn", sender: self)
                    print(session as Any)
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }


}

