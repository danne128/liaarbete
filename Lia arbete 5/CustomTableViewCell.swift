//
//  CustomTableViewCell.swift
//  Lia arbete 5
//
//  Created by Daniel Trondsen Wallin on 2016-10-14.
//  Copyright © 2016 Daniel Trondsen Wallin. All rights reserved.
//

import UIKit

class CustomTableViewCell: UITableViewCell {

    
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var inviteSwitch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
    }
    
    var cellDelegate: SettingCellDelegate?
    
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func handleChange(_ sender: UISwitch) {
        self.cellDelegate?.didChangeSwitchState(sender: self, isOn: inviteSwitch.isOn)
    }
}

protocol SettingCellDelegate {
    func didChangeSwitchState(sender: CustomTableViewCell, isOn: Bool)
}
