//
//  DeviceTableViewCell.swift
//  BluetoothChat
//
//  Created by Tim Oliver on 29/5/20.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import UIKit

class DeviceTableViewCell: UITableViewCell {

    // Configure for when a specific device that was found
    public func configureForDevice(named device: String, selectable: Bool = true) {
        textLabel?.alpha = 1.0
        selectionStyle = selectable ? .blue : .none
        accessoryType = selectable ? .disclosureIndicator : .none
        textLabel?.text = device
    }

    // Configure for a default placeholder state when no devices are found
    public func configureForNoDevicesFound() {
        textLabel?.alpha = 0.5
        selectionStyle = .none
        accessoryType = .none
        textLabel?.text = "No devices found."
    }
}
