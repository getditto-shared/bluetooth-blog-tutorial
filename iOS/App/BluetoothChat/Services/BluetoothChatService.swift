//
//  BluetoothChatService.swift
//  BluetoothChat
//
//  Created by Tim Oliver on 1/6/20.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import Foundation
import CoreBluetooth

enum BluetoothChatState {
    case scanning
    case advertising
    case chattingAsCentral
    case chattingAsPeripheral
}

class BluetoothChatService: NSObject {

    /// A closure that is called whenever we receive a message from our communicating device
    public var messageReceivedHandler: ((String) -> Void)?

    // The target device we'll be chatting with
    private var device: Device!

    // The current state we are in
    private var state = BluetoothChatState.scanning

    // The central manager that will scan for any peripherals matching our device
    private var centralManager: CBCentralManager?

    // A strong reference to a detected matching peripheral from the central manager
    private var peripheral: CBPeripheral?

    // The peripheral advertising ourselves
    private var peripheralManager: CBPeripheralManager?

    // If we join the connection as a peripheral, we maintain a reference to our central
    private var central: CBCentral?

    // The characteristic of the service that carries out chat data (when we are a central)
    private var centralCharacteristic: CBCharacteristic?

    // The characteristic of the service that carries out chat data (when we are a peripheral)
    private var peripheralCharacteristic: CBMutableCharacteristic?

    // While making the connection, buffer any pending message
    private var pendingMessageData: Data?

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

    /// Send a message to our chat target
    public func send(message: String) {
        let messageData = message.data(using: .utf8)!

        switch state {
        case .scanning:
            // If we're still in the base state (ie, we haven't established a connection yet),
            // make this device a peripheral and start advertising
            pendingMessageData = messageData
            startAdvertising()
        case .advertising:
            // If we're advertising, replace the last message
            pendingMessageData = messageData
        case .chattingAsCentral:
            sendCentralData(messageData)
        case .chattingAsPeripheral:
            sendPeripheralData(messageData)
        }
    }

    private func startAdvertising() {
        guard state == .scanning, peripheralManager == nil else { return }

        // Change our state to advertising as a peripheral
        state = .advertising

        // Create the peripheral manager, which will implicitly kick off the
        // update status delegate
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    private func sendCentralData(_ data: Data) {
        guard let characteristic = self.centralCharacteristic,
                    let peripheral = self.peripheral else { return }
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }

    private func sendPeripheralData(_ data: Data) {
        guard let characteristic = self.peripheralCharacteristic,
            let central = self.central else { return }

        peripheralManager?.updateValue(data, for: characteristic,
                                       onSubscribedCentrals: [central])
    }
}

extension BluetoothChatService: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else { return }
        guard central.isScanning == false else { return }

        // Reset state and start scanning
        resetCentral()
        startScan()
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Check if the identifier of the peripheral we detected matches the one we're looking for
        guard peripheral.identifier == device.peripheral.identifier else { return }

        // If this is the device we're expecting, start connecting
        centralManager?.connect(peripheral, options: nil)

        // Retain the peripheral
        self.peripheral = peripheral

        // Change our state to chatting as central
        state = .chattingAsCentral
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Stop scanning once we've connected
        central.stopScan()

        // Configure a delegate for the peripheral
        peripheral.delegate = self

        // Scan for the chat characteristic we'll use to communicate
        peripheral.discoverServices([BluetoothConstants.chatServiceID])
    }

    /// An error occurred when attempting to connect to the peripheral
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }

        // Reset the state and start scanning
        resetCentral()
        startScan()
    }

    /// The peripheral disconnected
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }

        // Reset the state and start scanning
        resetCentral()
        startScan()
    }

    private func resetCentral() {
        // Reset all state
        self.state = .scanning
        self.peripheral = nil
    }

    private func startScan() {
        guard let centralManager = centralManager, !centralManager.isScanning else { return }

        // Start scanning for a peripheral that matches our saved device
        centralManager.scanForPeripherals(withServices: [BluetoothConstants.chatServiceID],
                                   options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
}

extension BluetoothChatService: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        // Once we're powered on, configure the peripheral with the services
        // and characteristics we intend to support

        guard peripheral.state == .poweredOn else { return }

        // Create the characteristic which will be the conduit for our chat data.
        // Make sure the properties are set to writeable so we can send data upstream
        // to the central, and notifiable, so we'll receive callbacks when data comes downstream
        peripheralCharacteristic = CBMutableCharacteristic(type: BluetoothConstants.chatCharacteristicID,
                                                 properties: [.write, .notify],
                                                 value: nil,
                                                 permissions: .writeable)

        // Create the service that will represent this characteristic
        let service = CBMutableService(type: BluetoothConstants.chatServiceID, primary: true)
        service.characteristics = [self.peripheralCharacteristic!]

        // Register this service to the peripheral so it can now be advertised
        peripheralManager?.add(service)

        // Start advertising as a peripheral
        let advertisementData: [String: Any] = [CBAdvertisementDataServiceUUIDsKey: [BluetoothConstants.chatServiceID]]
        peripheralManager?.startAdvertising(advertisementData)
    }

    /// Called when someone else has subscribed to our characteristic, allowing us to send them data
    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didSubscribeTo characteristic: CBCharacteristic) {
        print("A central has subscribed to the peripheral")

        // Stop scanning as a central now
        centralManager?.stopScan()

        // Set our state as a full peripheral
        state = .chattingAsPeripheral

        // Capture the central so we can get information about it later
        self.central = central

        // If we had a pending message, send it
        if let data = pendingMessageData {
            sendPeripheralData(data)
            pendingMessageData = nil
        }
    }

    /// Called when the subscribing central has unsubscribed from us
    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("The central has unsubscribed from the peripheral")

        // Release the reference to the parent central
        self.central = nil

        // Resume scanning as a central ourselves
        centralManager?.scanForPeripherals(withServices: [BluetoothConstants.chatServiceID],
                                           options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    /// Called when the central has sent a message to this peripheral
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        guard let request = requests.first, let data = request.value else { return }

        // Decode the message string and trigger the callback
        let message = String(decoding: data, as: UTF8.self)
        messageReceivedHandler?(message)
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
            self.centralCharacteristic = characteristic
        }
    }

    /// More data has arrived via a notification from the characteristic we subscribed to
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Perform any error handling if one occurred
        if let error = error {
            print("Characteristic value update failed: \(error.localizedDescription)")
            return
        }

        // Decode the message string and trigger the callback
        guard let data = characteristic.value else { return }
        let message = String(decoding: data, as: UTF8.self)
        messageReceivedHandler?(message)
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

        if let data = pendingMessageData {
            sendCentralData(data)
            pendingMessageData = nil
        }
    }
}
