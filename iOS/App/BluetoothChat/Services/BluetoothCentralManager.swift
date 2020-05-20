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

    // The peripheral we've connected to
    private var peripheral: CBPeripheral?

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
    /// Once Bluetooth is powered up and ready, start scanning for peripherals
    /// advertising the service we support
    fileprivate func startScanning() {
        guard !(centralManager?.isScanning ?? true) else { return }

        centralManager?.scanForPeripherals(withServices: [BluetoothService.chatServiceID], options: nil)

        scanPending = false
    }

}

// MARK: - Central Manager Delegate -

extension BluetoothCentralManager: CBCentralManagerDelegate {
    /// Called whenever the state of the Bluetooth Manager changes.
    /// This will primarily be used to detect when Bluetooth has finished powering on
    /// at the beginning
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

    /// Called when a potentially compatible device was discovered during a scan
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {

        // Ignore any other peripherals we see in the meanwhile
        guard self.peripheral == nil else { return }

        //
        if let deviceName = advertisementData[CBAdvertisementDataLocalNameKey] {
            print("Peripheral \(deviceName) discovered.")
        } else {
            print("Compatible device discovered.")
        }

        // Print the Relative Signal Strength
        print("RSSI is \(RSSI)")

        // We *must* retain a strong reference to the peripheral object, otherwise it will be released
        // while we're connecting to it
        self.peripheral = peripheral

        // Once we've discovered a peripheral matching our service ID, try connecting to it
        centralManager?.connect(peripheral, options: nil)
    }

    /// Called when we've managed to establish a connection to a peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {



    }

}
