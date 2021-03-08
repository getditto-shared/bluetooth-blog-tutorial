package ditto.live.bluetoothchat

import android.bluetooth.BluetoothAdapter
import android.graphics.Bitmap
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.lifecycle.Observer
import com.github.bassaer.chatmessageview.model.ChatUser
import com.github.bassaer.chatmessageview.model.Message
import com.github.bassaer.chatmessageview.view.ChatView
import ditto.live.bluetoothchat.services.BluetoothChatService

class ChatFragment: Fragment() {
    private lateinit var chatView: ChatView
    private lateinit var name: String

    private val messageObserver = Observer<BLEMessage> { message ->
        updateMessages(message)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        name = BluetoothAdapter.getDefaultAdapter().name
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        val view = inflater.inflate(R.layout.fragment_chat, container, false)
        setupChatView(view)
        return view
    }

    override fun onStart() {
        super.onStart()
        BluetoothChatService.messages.observe(viewLifecycleOwner, messageObserver)
    }

    private fun setupChatView(view: View) {
        chatView = view.findViewById(R.id.chat_view)
        chatView.setOnClickSendButtonListener({ onClickSend() })
        chatView.setAutoScroll(true)
        chatView.setSendTimeTextColor(0)
        chatView.setMessageFontSize(50F)
    }

    private fun onClickSend() {
        val text = chatView.inputText
        if (chatView.inputText.isEmpty()) return
        BluetoothChatService.sendMessage(text)
        chatView.inputText = ""
    }

    private fun updateMessages(message: BLEMessage) {
        val emptyIcon = Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888)
        val myUser = message is LocalMessage
        val username = if (myUser) BluetoothChatService.currentDevice!!.name else BluetoothAdapter.getDefaultAdapter().name
        val user = ChatUser(0, username, emptyIcon)
        val messageBuilder = Message.Builder()
                .setUser(user)
                .setRight(myUser)
                .setText(message.text)
                .hideIcon(true)

        requireActivity().runOnUiThread {
            chatView.receive(messageBuilder.build())
        }
    }
}