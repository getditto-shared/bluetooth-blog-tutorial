//
//  File.swift
//  BluetoothChat
//
//  Created by Tim Oliver on 31/5/20.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import Foundation
import MessageKit

/// When chatting, these types uniquely identify
/// each user in a given chat room
struct Sender: SenderType {
    /// A unique value used to identify a specific user
    var senderId: String

    /// The visible name of this user
    var displayName: String
}
