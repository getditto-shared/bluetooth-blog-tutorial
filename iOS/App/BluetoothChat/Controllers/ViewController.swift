//
//  ViewController.swift
//  BluetoothChat
//
//  Created by Tim Oliver on 14/5/20.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    //private var bluetoothCentral = BluetoothCentralManager()
    private var bluetoothPeripheral = BluetoothPeripheralManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        //bluetoothCentral.start()
        bluetoothPeripheral.start()
    }
}
