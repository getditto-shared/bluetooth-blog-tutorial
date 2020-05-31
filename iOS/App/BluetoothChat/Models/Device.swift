//
//  Device.swift
//  BluetoothChat
//
//  Created by Tim Oliver on 31/5/20.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import Foundation
import CoreBluetooth

/// A device, as detected through Bluetooth
/// service advertisement
struct Device {
    let peripheral: CBPeripheral
    let name: String

    init(peripheral: CBPeripheral, name: String = "Unknown") {
        self.peripheral = peripheral
        self.name = name
    }
}
