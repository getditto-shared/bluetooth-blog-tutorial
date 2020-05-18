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
                                                 CBAdvertisementDataServiceUUIDsKey: [BluetoothService.chatServiceID]]

        peripheralManager?.startAdvertising(advertisementData)
        advertPending = false
    }
}

extension BluetoothPeripheralManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
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
            if advertPending { startAdvertising() }
        @unknown default:
            print("Bluetooth state has changed to an unknown state")
        }
    }
}
