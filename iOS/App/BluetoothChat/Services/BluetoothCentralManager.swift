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

    // The Core Bluetooth object that manages our state as a central
    private var centralManager: CBCentralManager?

    // Whether scanning has been deferred
    private var scanPending = false

    /// Start scanning for peripherals in the area
    public func start() {
        // Create the central manager (This will also kickstart launching Bluetooth)
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }

        // We can't begin scanning until Bluetooth has finished powering on,
        // which might not be ready yet, so we have to defer
        guard centralManager?.state == .poweredOn else {
            scanPending = true
            return
        }

        // If Bluetooth was ready, start scanning now
        startScanning()
    }
}

// MARK: - Private -

extension BluetoothCentralManager {
    fileprivate func startScanning() {
        guard !(centralManager?.isScanning ?? true) else { return }

        centralManager?.scanForPeripherals(withServices: [BluetoothService.chatServiceID], options: nil)

        scanPending = false
    }
}

// MARK: - Central Manager Delegate -

extension BluetoothCentralManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("Bluetooth state has changed to is .unknown")
        case .resetting:
            print("Bluetooth state has changed to is .resetting")
        case .unsupported:
            print("Bluetooth state has changed to is .unsupported")
        case .unauthorized:
            print("Bluetooth state has changed to is .unauthorized")
        case .poweredOff:
            print("Bluetooth state has changed to is .poweredOff")
        case .poweredOn:
            print("Bluetooth state has changed to is .poweredOn")
            if scanPending { startScanning() }
        @unknown default:
            print("Bluetooth state has changed to an unknown state")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("FOUND")
    }

}
