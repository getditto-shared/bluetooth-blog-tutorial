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
    /// For our chat app, we will define a service used to detect other devices we can connect to
    static let chatDiscoveryServiceID = CBUUID(string: "42332fe8-9915-11ea-bb37-0242ac130002")

    /// Once two devices have been confirmed to connect to each other, they'll broadcast a different
    /// service so as to not interfere with device discovery
    static let chatServiceID = CBUUID(string: "43eb0d29-4188-4c84-b1e8-73231e02af95")

    /// Bluetooth services contain a number of characteristics, that represent a number
    /// of specific functions of a service. For our example, our chat service will contain
    /// a characteristic that is used to move data between devices.
    static let chatCharacteristicID = CBUUID(string: "f0ab5a15-b003-4653-a248-73fd504c128f")
}
