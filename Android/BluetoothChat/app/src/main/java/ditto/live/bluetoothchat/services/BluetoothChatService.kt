package ditto.live.bluetoothchat.services


import android.app.Application
import android.bluetooth.*
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import ditto.live.bluetoothchat.*


object BluetoothChatService {

    private val _messages = MutableLiveData<BLEMessage>()
    val messages = _messages as LiveData<BLEMessage>

    private var gattServer: BluetoothGattServer? = null
    private var gattServerCallback: BluetoothGattServerCallback? = null
    private var gattClient: BluetoothGatt? = null
    private var gattClientCallback: BluetoothGattCallback? = null
    private var gatt: BluetoothGatt? = null
    private var gattMessageCharacteristic: BluetoothGattCharacteristic? = null

    var currentDevice: BluetoothDevice? = null

    /**
     * A device has been selected in our JoinFragment
     * Set our current device and connect our devive with the current device
     */
    fun setCurrentDevice(context: Application, device: BluetoothDevice) {
        currentDevice = device
        connectDevices(context, device)
    }

    /**
     * Create The GattClientCallback to handle Bluetooth GATT callbacks
     * Set our GATT client to the remote device
     */
    private fun connectDevices(context: Application, device: BluetoothDevice) {
        gattClientCallback = GattClientCallback()
        gattClient = device.connectGatt(context, false, gattClientCallback)
    }

    /**
     * Function to write messages to the remote device
     */
    fun sendMessage(message: String): Boolean {
        gattMessageCharacteristic?.let { characteristic ->
            characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
            val messageBytes = message.toByteArray(Charsets.UTF_8)
            characteristic.value = messageBytes
            gatt?.let {
                val success = it.writeCharacteristic(gattMessageCharacteristic)
                if (success) {
                    _messages.value = LocalMessage(message)
                }
            }
        }
        return false
    }

    /**
     * Function to open a GATT server
     */
    fun createServer(bluetoothManager: BluetoothManager, app: Application) {
        gattServerCallback = GattServerCallback()
        gattServer = bluetoothManager.openGattServer(
            app,
            gattServerCallback
        ).apply {
            addService(setupGattService())
        }
    }

    /**
     * Function to create the GATT service
     * Set our custom service and characteristics
     */
    private fun setupGattService(): BluetoothGattService {
        val gattService = BluetoothGattService(chatDiscoveryServiceID, BluetoothGattService.SERVICE_TYPE_PRIMARY)
        val gattCharacteristic = BluetoothGattCharacteristic(
            chatMessageCharacteristicID,
            BluetoothGattCharacteristic.PROPERTY_WRITE,
            BluetoothGattCharacteristic.PERMISSION_WRITE
        )
        val confirmCharacteristic = BluetoothGattCharacteristic(
                confirmCharacteristicID,
            BluetoothGattCharacteristic.PROPERTY_WRITE,
            BluetoothGattCharacteristic.PERMISSION_WRITE
        )
        gattService.addCharacteristic(gattCharacteristic)
        gattService.addCharacteristic(confirmCharacteristic)

        return gattService
    }

    /**
     * Callback for the GATT Server this device implements
     * Get message from the request value
     * save as a remote message
     */
    private class GattServerCallback : BluetoothGattServerCallback() {
        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?
        ) {
            super.onCharacteristicWriteRequest(device, requestId, characteristic, preparedWrite, responseNeeded, offset, value)
            //check that the characteristic matches our constant value
            if (characteristic.uuid == chatMessageCharacteristicID) {
                //send response back to sender that message was successfully received
                gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null)
                val message = value?.toString(Charsets.UTF_8)
                message?.let {
                    _messages.postValue(RemoteMessage(it))
                }
            }
        }
    }

    private class GattClientCallback : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            super.onConnectionStateChange(gatt, status, newState)
            //Check if our GATT operation has successfully completed
            //Check if our profile is in the state of connected
            if (status == BluetoothGatt.GATT_SUCCESS && newState == BluetoothProfile.STATE_CONNECTED) {
                gatt.discoverServices()
            }
        }

        /**
         * new services have been discovered
         * set our GATT to the new discovery
         * use our UUID constants to set our message characteristic
         */
        override fun onServicesDiscovered(discoveredGatt: BluetoothGatt, status: Int) {
            super.onServicesDiscovered(discoveredGatt, status)
            if (status == BluetoothGatt.GATT_SUCCESS) {
                gatt = discoveredGatt
                val service = discoveredGatt.getService(chatDiscoveryServiceID)
                gattMessageCharacteristic = service.getCharacteristic(chatMessageCharacteristicID)
            }
        }
    }
}