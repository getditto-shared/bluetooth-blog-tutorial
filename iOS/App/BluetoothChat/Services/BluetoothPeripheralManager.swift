//
//  BluetoothPeripheralManager.swift
//  BluetoothChat
//
//  Created by Tim Oliver on 18/5/20.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import Foundation
import CoreBluetooth

/// A centralised control center for acting as a client
/// in a connected Bluetooth session
final class BluetoothPeripheralManager: NSObject {

    // The Core Bluetooth object that manages our state as a peripheral
    private var peripheralManager: CBPeripheralManager?

    // The characteristic contained in the service that controls the chat data flow
    private var characteristic: CBMutableCharacteristic?

    // Whether advertising has been deferred
    private var advertPending = false

    public func start() {
        if peripheralManager == nil {
            peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        }

        guard peripheralManager?.state == .poweredOn else {
            advertPending = true
            return
        }

        startAdvertising()
    }
}

extension BluetoothPeripheralManager {
    private func startAdvertising() {
        guard !(peripheralManager?.isAdvertising ?? true) else { return }

        let advertisementData: [String: Any] = [CBAdvertisementDataLocalNameKey: "XD",
                                                 CBAdvertisementDataServiceUUIDsKey: [BluetoothService.chatID]]

        peripheralManager?.startAdvertising(advertisementData)
        advertPending = false
    }
}

extension BluetoothPeripheralManager: CBPeripheralManagerDelegate {

    /// Called whenever the Bluetooth state of this peripheral has changed
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        // Print out which state Bluetooth just entered
        switch peripheral.state {
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
        @unknown default:
            print("Bluetooth state has changed to an unknown state")
        }

        // Once we're powered on, configure the peripheral with the services
        // and characteristics we intend to support

        guard peripheral.state == .poweredOn else { return }

        // Create the characteristic which will be the conduit for our chat data
        characteristic = CBMutableCharacteristic(type: BluetoothCharacteristic.chatID,
                                                 properties: .notify,
                                                 value: nil,
                                                 permissions: .writeable)

        // Create the service that will represent this characteristic
        let service = CBMutableService(type: BluetoothService.chatID, primary: true)
        service.characteristics = [self.characteristic!]

        // Register this service to the peripheral so it can now be advertised
        peripheralManager?.add(service)

        // If we had already requested advertising before Bluetooth finished
        // powering up, start now
        if advertPending {
            startAdvertising()
        }
    }

    /// Called when someone else has subscribed to our characteristic, allowing us to send them data
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("A central has subscribed to the peripheral")


        if let characteristic = self.characteristic {
            // Send a message to the central
            let data = "Hello!".data(using: .utf8)!
            peripheralManager?.updateValue(data, for: characteristic, onSubscribedCentrals: nil)
        }
    }

    /// Called when the subscribing central has unsubscribed from us
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("The central has unsubscribed from the peripheral")
    }
}
