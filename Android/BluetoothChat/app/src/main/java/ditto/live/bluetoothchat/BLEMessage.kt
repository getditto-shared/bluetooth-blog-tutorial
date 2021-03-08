package ditto.live.bluetoothchat

abstract class BLEMessage(val text: String)
class RemoteMessage(text: String) : BLEMessage(text)
class LocalMessage(text: String) : BLEMessage(text)