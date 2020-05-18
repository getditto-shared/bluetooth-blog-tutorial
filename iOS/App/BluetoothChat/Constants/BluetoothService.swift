//
//  BluetoothService.swift
//  BluetoothChat
//
//  Created by Tim Oliver on 18/5/20.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import Foundation
import CoreBluetooth

/// Bluetooth devices broadcast their capabilities
/// (eg, a heart monitor, or a thermometer) as uniquely identified services
/// For our chat app, we will define our own service with its own service ID
/// that we can detect when scanning
struct BluetoothService {
    static let chatServiceID = CBUUID(string: "42332fe8-9915-11ea-bb37-0242ac130002")
}
