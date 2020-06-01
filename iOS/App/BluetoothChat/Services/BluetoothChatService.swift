//
//  BluetoothChatService.swift
//  BluetoothChat
//
//  Created by Tim Oliver on 1/6/20.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import Foundation
import CoreBluetooth

class BluetoothChatService: NSObject {

    // The target device we'll be chatting with
    private var device: Device!

    // The central manager that will scan for any peripherals matching our device
    private var centralManager: CBCentralManager?

    // A strong reference to a detected matching peripheral from the central manager
    private var peripheral: CBPeripheral?

    // The peripheral advertising ourselves
    private var peripheralManager: CBPeripheralManager?

    // The characteristic of the service that carries out chat data
    private var characteristic: CBCharacteristic?

    /// Create a new instance of the chat service with a target device
    /// that we'll be attempting to chat to.
    /// - Parameter device: The target device we're aiming to chat with
    init(device: Device) {
        super.init()

        // Save the device
        self.device = device

        // Start the central, scanning immediately
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}

extension BluetoothChatService: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else { return }
        guard central.isScanning == false else { return }

        // Start scanning for a peripheral that matches our saved device
        central.scanForPeripherals(withServices: [BluetoothConstants.chatServiceID],
                                   options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Check if the identifier of the peripheral we detected matches the one we're looking for
        guard peripheral.identifier == device.peripheral.identifier else { return }

        // If this is the device we're expecting, start connecting
        centralManager?.connect(peripheral, options: nil)

        // Retain the peripheral
        self.peripheral = peripheral
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Stop scanning once we've connected
        central.stopScan()

        // Configure a delegate for the peripheral
        peripheral.delegate = self

        // Scan for the chat characteristic we'll use to communicate
        peripheral.discoverServices([BluetoothConstants.chatServiceID])
    }
}

extension BluetoothChatService: CBPeripheralDelegate {

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
                if characteristic.uuid != BluetoothConstants.chatCharacteristicID { return }
                if characteristic.isNotifying {
                    peripheral.setNotifyValue(false, for: characteristic)
                }
            }
        }

        // Cancel the connection
        centralManager?.cancelPeripheralConnection(peripheral)
    }

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
            peripheral.discoverCharacteristics([BluetoothConstants.chatCharacteristicID], for: service)
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
            guard characteristic.uuid == BluetoothConstants.chatCharacteristicID else { return }

            // Subscribe to this characteristic, so we can be notified when data comes from it
            peripheral.setNotifyValue(true, for: characteristic)

            // Hold onto a reference for this characteristic for sending data
            self.characteristic = characteristic
        }
    }

    /// More data has arrived via a notification from the characteristic we subscribed to
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Perform any error handling if one occurred
        if let error = error {
            print("Characteristic value update failed: \(error.localizedDescription)")
            return
        }

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
        guard characteristic.uuid == BluetoothConstants.chatCharacteristicID else { return }

        // Check if it is successfully set as notifying
        if characteristic.isNotifying {
            print("Characteristic notifications have begun.")
        } else {
            print("Characteristic notifications have stopped. Disconnecting.")
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
}
