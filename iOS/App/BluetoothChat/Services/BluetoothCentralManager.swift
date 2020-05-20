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

        centralManager?.scanForPeripherals(withServices: [BluetoothService.chatID], options: nil)

        scanPending = false
    }

    /// If we finshed up, or if any kind of error occurred mid-connection,
    /// clean up the state so we can start again from scratch
    fileprivate func cleanUp() {
        // Nothing to clean up if we haven't connected to a peripheral, or if the peripheral isn't connected
        guard let peripheral = peripheral,
                    peripheral.state != .disconnected else { return }

        // Loop through all of the characteristics in each service,
        // and if any were configured to notify us, disconnect them
        peripheral.services?.forEach { service in
            service.characteristics?.forEach { characteristic in
                if characteristic.uuid != BluetoothCharacteristic.chatID { return }
                if characteristic.isNotifying {
                    peripheral.setNotifyValue(false, for: characteristic)
                }
            }
        }

        // Cancel the connection
        centralManager?.cancelPeripheralConnection(peripheral)
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

        // Once a connection is established, we can stop scanning
        centralManager?.stopScan()

        // Once we've successfully connected, we can start receiving callbacks from the peripheral
        peripheral.delegate = self

        // Query the peripheral for the service we want, so we can then access the characteristic
        peripheral.discoverServices([BluetoothService.chatID])
    }

    /// Called when our peripheral was disconnected
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Peripheral disconnected")

        // Clean out the reference to that peripheral
        self.peripheral = nil

        // Start scanning again
        startScanning()
    }
}

// MARK: - Peripheral Delegate -

extension BluetoothCentralManager: CBPeripheralDelegate {

    /// The peripheral was able to discover a service matching our specified ID.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // If an error occurred, print it, and then reset all of the state
        if let error = error {
            print("Unable to discover service: \(error.localizedDescription)")
            cleanUp()
            return
        }

        // It's possible there may be more than one service, so loop through each one to discover
        // the characteristic that we want
        peripheral.services?.forEach { service in
            peripheral.discoverCharacteristics([BluetoothCharacteristic.chatID], for: service)
        }
    }

    /// A characteristic matching the ID that we specifed was discovered in one of the services of the peripheral
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Handle if any errors occurred
        if let error = error {
            print("Unable to discover characteristics: \(error.localizedDescription)")
            cleanUp()
            return
        }

        // Perform a loop in case we received more than one
        service.characteristics?.forEach { characteristic in
            guard characteristic.uuid == BluetoothCharacteristic.chatID else { return }

            // Subscribe to this characteristic, so we can be notified when data comes from it
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    /// More data has arrived via a notification from the characteristic we subscribed to
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Perform any error handling if one occurred
        if let error = error {
            print("Characteristic value update failed: \(error.localizedDescription)")
            return
        }

        // Retrieve the payload from the characteristic
        let data = characteristic.value
    }

    /// The peripheral returned back whether our subscription to the characteristic was successful or not
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        // Perform any error handling if one occurred
        if let error = error {
            print("Characteristic update notification failed: \(error.localizedDescription)")
            return
        }

        // Ensure this characteristic is the one we configured
        guard characteristic.uuid == BluetoothCharacteristic.chatID else { return }

        // Check if it is successfully set as notifying
        if characteristic.isNotifying {
            print("Characteristic notifications have begun.")
        } else {
            print("Characteristic notifications have stopped. Disconnecting.")
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
}
