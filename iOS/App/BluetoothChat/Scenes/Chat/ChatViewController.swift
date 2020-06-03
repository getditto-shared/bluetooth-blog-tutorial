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

    // The device we'll be communicating with
    private(set) public var device: Device!

    // The Bluetooth service that will handle chats for us
    private var chatService: BluetoothChatService!

    init(device: Device) {
        super.init(nibName: nil, bundle: nil)
        self.device = device
        self.chatService = BluetoothChatService(device: device)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the title visible in the title bar to the device name
        title = device.peripheral.name ?? device.peripheral.identifier.description

        // Configure ourselves as the delegates for MessageKit
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self

        // Suppress the avatars icons
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.textMessageSizeCalculator.incomingAvatarSize = .zero
        }

        // Send a chat message
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Show the navigation bar for this view controller
        if let navigationController = self.navigationController {
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
    }
}

extension ChatViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        return Sender(senderId: "000", displayName: "Ditto")
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        let sender = Sender(senderId: "000", displayName: "Ditto")
        return Message(sender: sender, message: "Hello World!")
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return 1
    }
}

// Conform to the MessageKit display and layout delegates (But we won't be implementing any logic here)
extension ChatViewController: MessagesDisplayDelegate, MessagesLayoutDelegate {}
