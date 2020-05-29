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

    static let deviceCellIdentifier = "DeviceCell"
    static let nameCellIdentifier = "NameCell"

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

        // Register the cells we plan to use
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: JoinViewController.deviceCellIdentifier)
        tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil),
                           forCellReuseIdentifier: JoinViewController.nameCellIdentifier)
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Sections.name { return 1 }
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == Sections.name {
            let cell = tableView.dequeueReusableCell(withIdentifier: JoinViewController.nameCellIdentifier,
                                                     for: indexPath)
            return cell
        }

        return tableView.dequeueReusableCell(withIdentifier: JoinViewController.deviceCellIdentifier, for: indexPath)
    }
}
