//
//  InviteFriendsTableViewController.swift
//  Lia arbete 5
//
//  Created by Daniel Trondsen Wallin on 2016-10-12.
//  Copyright © 2016 Daniel Trondsen Wallin. All rights reserved.
//

import UIKit

class InviteFriendsTableViewController: UITableViewController, SettingCellDelegate {
    
    
    @IBOutlet var yourTableView: UITableView!
    
    var name: [NSString] = []
    var profilePictures: [UIImage] = []
    
        
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        yourTableView.delegate = self
        yourTableView.dataSource = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getFriends()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows

        return name.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "Cell"
        
        let cell: CustomTableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! CustomTableViewCell
        cell.layoutIfNeeded()
        
        cell.nameLabel.text = self.name[(indexPath as NSIndexPath).row] as String
        cell.profilePictureImageView.layer.masksToBounds = true
        cell.profilePictureImageView.layer.borderWidth = 1
        cell.profilePictureImageView.layer.cornerRadius = cell.profilePictureImageView.frame.size.width / 2
        
        
        let image: UIImage = self.profilePictures[(indexPath as NSIndexPath).row] as UIImage
        
        cell.cellDelegate = self
        
        cell.profilePictureImageView.image = image
        
        return cell
        
    }
    
    func didChangeSwitchState(sender: CustomTableViewCell, isOn: Bool) {
        let indexPath = self.tableView.indexPath(for: sender)
        
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        print(name[(indexPath?.row)!])
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }

    
    func getFriends() {
        
        
        FBSDKGraphRequest(graphPath: "me/friends", parameters: ["fields": "id, name, picture.type(large)"]).start { (connection, result, error) in
            
            if (error != nil) {
                
                print("Error \(error)")
                return
            }
            
            guard var resultNew = result as? [String:Any] else {
                return
            }

            
            let summary = resultNew.removeValue(forKey: "summary") as! NSDictionary
            let count = summary.value(forKey: "total_count") as! NSNumber
            
            let params = ["fields": "id, name, picture.type(large)", "limit": "\(count)"]
            FBSDKGraphRequest(graphPath: "me/taggable_friends", parameters: params).start { (connection, result, error) in
                
                if ((error) != nil)
                {
                    print("Error: \(error)")
                    return
                }
                else
                {
                    guard var resultNew = result as? [String:Any] else {
                        return
                    }
                    let friends = resultNew.removeValue(forKey: "data") as? NSArray
                    if let array = friends as? [NSDictionary] {
                        
                        
                        for friend: NSDictionary in array {
                            
                            
                            let picture = friend.value(forKey: "picture") as! NSDictionary
                            let picData = picture.value(forKey: "data") as! NSDictionary
                            let url = picData.value(forKey: "url") as! String
                            let picURL = NSURL(string: url)
                            let data = NSData(contentsOf: picURL! as URL)
                            let profilePic = UIImage(data: data! as Data)
                            
                            //let id = friend.valueForKey("id") as! NSString
                            
                            let friendName = friend.value(forKey: "name") as! NSString
                            self.name.append(friendName)
                            self.profilePictures.append(profilePic!)
                            
                        }
                    }
                    self.tableView.reloadData()
                    print("done")
                    
                }
            }
        }
    }

}




