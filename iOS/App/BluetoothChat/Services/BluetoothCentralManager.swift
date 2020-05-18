//
//  BluetoothManager.swift
//  BluetoothChat
//
//  Created by Tim Oliver on 18/5/20.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import UIKit
import CoreBluetooth

/// A centralised control center for acting as the host
/// in a connected Bluetooth session
final class BluetoothCentralManager: NSObject {

    private var centralManager: CBCentralManager!

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)

    }

    public func start() {
        centralManager.scanForPeripherals(withServices: [BluetoothService.chatServiceID], options: nil)
    }
}

extension BluetoothCentralManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {

    }

}
