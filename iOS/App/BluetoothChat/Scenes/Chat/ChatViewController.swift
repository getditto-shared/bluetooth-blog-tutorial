//
//  ChatViewController.swift
//  BluetoothChat
//
//  Created by Tim Oliver on 31/5/20.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView

/// The entire UI scene for a chat session with another device
class ChatViewController: MessagesViewController {

    // The device we'll be communicating with
    private(set) public var device: Device!

    // The Bluetooth service that will handle chats for us
    fileprivate var chatService: BluetoothChatService!

    // The sender object representing us
    fileprivate var currentDeviceSender: Sender!

    // All of the messages in this chat session
    fileprivate var messages = [Message]()

    init(device: Device, currentDeviceName: String) {
        super.init(nibName: nil, bundle: nil)
        self.device = device
        self.chatService = BluetoothChatService(device: device)
        self.currentDeviceSender = Sender(senderId: "{self}", displayName: currentDeviceName)
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

        // Subscribe to the user inputting messages into the text bar
        messageInputBar.delegate = self

        // Suppress the avatars icons
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.textMessageSizeCalculator.incomingAvatarSize = .zero
        }

        // Subscribe to messages from the chat service
        chatService.messageReceivedHandler = { [weak self] message in
            guard let self = self else { return }

            // Fetch the peripheral from where this message came
            let peripheral = self.device.peripheral

            // Configure a sender
            let senderId = peripheral.identifier.uuidString
            let senderName = peripheral.name ?? peripheral.identifier.uuidString
            let sender = Sender(senderId: senderId, displayName: senderName)

            // Configure a message and submit it
            let message = Message(sender: sender, message: message)
            self.appendNewMessage(message)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Show the navigation bar for this view controller
        if let navigationController = self.navigationController {
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
    }

    private func appendNewMessage(_ message: Message) {
        messages.append(message)
        messagesCollectionView.insertSections([messages.count - 1])
        messagesCollectionView.scrollToBottom(animated: true)
    }
}

// MARK: - Messages Data Source -

extension ChatViewController: MessagesDataSource {

    /// Used to identiy which sender object represents this device
    func currentSender() -> SenderType {
        return currentDeviceSender
    }

    /// Returns the number of chat messages in this session
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }

    /// Returns the messages for each row in this chat view controller
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
}

// MARK: - Input Bar Accessory View Delegate -

extension ChatViewController: InputBarAccessoryViewDelegate {

    /// Called when the user taps the "Send" button
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        // Send the message to our partner in the session
        chatService.send(message: text)

        // Clear the text from the text field
        inputBar.inputTextView.text = nil

        // Insert this message into our local UI
        let message = Message(sender: currentDeviceSender, message: text)
        appendNewMessage(message)
    }
}

// Conform to the MessageKit display and layout delegates (But we won't be implementing any logic here)
extension ChatViewController: MessagesDisplayDelegate, MessagesLayoutDelegate {}
