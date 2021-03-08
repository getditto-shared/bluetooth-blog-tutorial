package ditto.live.bluetoothchat.services

import android.app.Application
import android.bluetooth.*
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.os.ParcelUuid
import ditto.live.bluetoothchat.*

object BluetoothDeviceDiscovery {
    private class BleAdvertiseCallback : AdvertiseCallback()
    private lateinit var bluetoothManager: BluetoothManager
    private val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()

    private var advertiser: BluetoothLeAdvertiser? = null
    private var advertiseCallback: AdvertiseCallback? = null

    fun startDiscovery(app: Application) {
        bluetoothManager = app.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        //
        BluetoothChatService.createServer(bluetoothManager, app)
        //start advertising once our BluetoothGattService has been created
        startAdvertisement()
    }

    /**
     * Stop advertising when our app is stopped
     */
    fun stopDiscovery() {
        stopAdvertising()
    }

    /**
     * Start Bluetooth LE advertising
     */
    private fun startAdvertisement() {
        //set our advertiser for future BLE advertising operations
        advertiser = bluetoothAdapter.bluetoothLeAdvertiser
        //create a new instance of AdvertiseCallback to be used in our advertisement
        advertiseCallback = BleAdvertiseCallback()
        //Set the advertisement settings to ADVERTISE_MODE_LOW_LATENCY
        //as we'll only be scanning for short periods looking for specfic devices
        val advertiseSettings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .build()
        //Use our unique service ID to advertise to other devices
        val advertiseData = AdvertiseData.Builder()
            .addServiceUuid(ParcelUuid(chatDiscoveryServiceID))
            .setIncludeDeviceName(true).build()
        advertiser?.startAdvertising(advertiseSettings, advertiseData, advertiseCallback)
    }

    /**
     * stop and deinit our advertisement
     */
    private fun stopAdvertising() {
        advertiser?.stopAdvertising(advertiseCallback)
        advertiseCallback = null
    }
}