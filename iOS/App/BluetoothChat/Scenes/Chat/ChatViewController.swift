//
//  ChatViewController.swift
//  BluetoothChat
//
//  Created by Tim Oliver on 31/5/20.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import UIKit
import MessageKit

class ChatViewController: MessagesViewController {

    private(set) public var device: Device!

    init(device: Device) {
        super.init(nibName: nil, bundle: nil)
        self.device = device
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the title visible in the title bar to the device name
        title = device.peripheral.name ?? device.peripheral.identifier.description
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Show the navigation bar for this view controller
        if let navigationController = self.navigationController {
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
    }

}
