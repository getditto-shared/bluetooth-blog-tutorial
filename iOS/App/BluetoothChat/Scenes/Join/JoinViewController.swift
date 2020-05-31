//
//  JoinViewController.swift
//  BluetoothChat
//
//  Created by Tim Oliver on 29/5/20.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import UIKit

struct Sections {
    static let name = 0
    static let availableDevices = 1
}

class JoinViewController: UITableViewController {

    // The static identifiers for the cells we'll be using
    static let deviceCellIdentifier = "DeviceCell"
    static let nameCellIdentifier = "NameCell"

    // The name of this device
    private var deviceName = UIDevice.current.name {
        didSet { deviceDiscovery.deviceName = deviceName }
    }

    // The Bluetooth service manager for advertising and scanning
    private var deviceDiscovery: BluetoothDeviceDiscovery!

    // MARK: - Class Creation -

    init() {
        super.init(style: .insetGrouped)
        tableView.cellLayoutMarginsFollowReadableWidth = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Configuration -

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up and run the device discovery service
        deviceDiscovery = BluetoothDeviceDiscovery(deviceName: deviceName)
        deviceDiscovery.devicesListUpdatedHandler = { [weak self] in
            guard let tableView = self?.tableView else { return }
            tableView.reloadSections([Sections.availableDevices], with: .automatic)
        }

        // Register the cells we plan to use
        tableView.register(DeviceTableViewCell.self,
                           forCellReuseIdentifier: JoinViewController.deviceCellIdentifier)
        tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil),
                           forCellReuseIdentifier: JoinViewController.nameCellIdentifier)

        // Set up the header view
        tableView.tableHeaderView = JoinTableHeaderView.instantiate()
    }

    override func viewDidAppear(_ animated: Bool) {
        // If we're in a navigation controller, hide the bar
        if let navigationController = self.navigationController {
            navigationController.setNavigationBarHidden(true, animated: animated)
        }
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Sections.name { return 1 }
        return max(deviceDiscovery.devices.count, 1)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // For the name section, dequeue a text field cell and configure it
        if indexPath.section == Sections.name {
            let cell = tableView.dequeueReusableCell(withIdentifier: JoinViewController.nameCellIdentifier,
                                                     for: indexPath)
            if let nameCell = cell as? TextFieldTableViewCell {
                nameCell.textField.text = deviceName
                nameCell.textFieldChangedHandler = { [weak self] name in
                    self?.deviceName = name
                }
            }

            return cell
        }

        // For the devices cells, dequeue one of the device cells and configure
        let cell = tableView.dequeueReusableCell(withIdentifier: JoinViewController.deviceCellIdentifier,
                                                 for: indexPath)
        if let deviceCell = cell as? DeviceTableViewCell {

            // If we have a list of devices, configure each cell with its name
            if deviceDiscovery.devices.count > 0 {
                let device = deviceDiscovery.devices[indexPath.row]
                deviceCell.configureForDevice(named: device.name)
            } else {
                // If no devices found, show "no devices"
                deviceCell.configureForNoDevicesFound()
            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == Sections.availableDevices { return "Devices" }
        return "Device Name"
    }
}
