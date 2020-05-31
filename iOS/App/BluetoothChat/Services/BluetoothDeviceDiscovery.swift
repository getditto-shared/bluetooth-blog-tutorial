//
//  BluetoothDeviceDiscovery.swift
//  BluetoothChat
//
//  Created by Tim Oliver on 31/5/20.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import Foundation
import CoreBluetooth

/// A service that both advertises this current device,
/// and scans for other devices also performing the same advertisement
/// over Bluetooth.
class BluetoothDeviceDiscovery: NSObject {

    // The central manager scans for other devices advertising themselves
    private var centralManager: CBCentralManager!

    // The peripheral manager handles advertising this device to other devices
    private var peripheralManager: CBPeripheralManager!

    override init() {
        super.init()

        // Create the Bluetooth devices (Which will immediately start warming them up)
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
}

extension BluetoothDeviceDiscovery: CBCentralManagerDelegate {
    // Called when the Bluetooth central state changes
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else { return }

        // Start scanning for peripherals
        centralManager.scanForPeripherals(withServices: [BluetoothConstants.chatServiceID],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    // Called when a peripheral is detected
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
    }
}

extension BluetoothDeviceDiscovery: CBPeripheralManagerDelegate {
    // Called when the Bluetooth peripheral state changes
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn else { return }

    }
}
