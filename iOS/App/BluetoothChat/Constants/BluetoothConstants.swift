//
//  BluetoothService.swift
//  BluetoothChat
//
//  Created by Tim Oliver on 18/5/20.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import Foundation
import CoreBluetooth

/// Bluetooth devices broadcast their supported capabilities
/// (eg, a heart monitor, or a thermometer) as uniquely identified services
/// For our chat app, we will define our own service with its own service ID
/// that we can detect when scanning
struct BluetoothService {
    static let chatID = CBUUID(string: "42332fe8-9915-11ea-bb37-0242ac130002")
}

/// Bluetooth services contain a number of characteristics, that represent a number
/// of specific functions of a service. For our example, our chat service will contain
/// a characteristic that is used to move data between devices.
struct BluetoothCharacteristic {
    static let chatID = CBUUID(string: "f0ab5a15-b003-4653-a248-73fd504c128f")
}
