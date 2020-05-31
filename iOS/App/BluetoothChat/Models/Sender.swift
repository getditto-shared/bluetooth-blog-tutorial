//
//  File.swift
//  BluetoothChat
//
//  Created by Tim Oliver on 31/5/20.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import Foundation
import MessageKit

/// A struct for uniquely identifying
/// different members in our chat room
struct Sender: SenderType {
    var senderId: String
    var displayName: String
}
