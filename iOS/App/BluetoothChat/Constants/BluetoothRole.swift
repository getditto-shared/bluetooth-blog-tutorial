//
//  BluetoothRole.swift
//  BluetoothChat
//
//  Created by Tim Oliver on 18/5/20.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import Foundation

/// There are two major types of devices in Bluetooth
/// Central - The host device managing the connection
/// Peripheral - Connects to and communicates with a host
enum BluetoothRole {
    case central // The host device
    case peripheral // A client connecting to a host
}
