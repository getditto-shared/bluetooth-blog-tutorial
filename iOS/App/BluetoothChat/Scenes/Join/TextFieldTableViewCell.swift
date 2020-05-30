//
//  TextFieldTableViewCell.swift
//  BluetoothChat
//
//  Created by Tim Oliver on 29/5/20.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import UIKit

class TextFieldTableViewCell: UITableViewCell, UITextFieldDelegate {

    // MARK: Text Field Delegate

    func textFieldDidEndEditing(_ textField: UITextField) {

    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }

}
