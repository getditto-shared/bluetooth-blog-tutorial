//
//  BluetoothService.swift
//  BluetoothChat
//
//  Created by Tim Oliver on 18/5/20.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import Foundation
import CoreBluetooth

struct BluetoothConstants {

    /// Bluetooth devices broadcast their supported capabilities
    /// (eg, a heart monitor, or a thermometer) as uniquely identified services
    /// For our chat app, we will define our own service with its own service ID
    /// that we can detect when scanning
    static let chatServiceID = CBUUID(string: "42332fe8-9915-11ea-bb37-0242ac130002")

    /// Bluetooth services contain a number of characteristics, that represent a number
    /// of specific functions of a service. For our example, our chat service will contain
    /// a characteristic that is used to move data between devices.
    static let chatCharacteristicID = CBUUID(string: "f0ab5a15-b003-4653-a248-73fd504c128f")
}
