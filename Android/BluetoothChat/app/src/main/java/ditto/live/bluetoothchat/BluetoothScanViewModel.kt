package ditto.live.bluetoothchat

import android.app.Application
import android.bluetooth.*
import android.bluetooth.le.*
import android.os.ParcelUuid
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData

class BluetoothScanViewModel(app: Application) : AndroidViewModel(app) {
    //our variables that will be set and used for the callback of nearby discovered devices
    private val _scanResults = MutableLiveData<MutableMap<String, BluetoothDevice>>()
    val scanResults = _scanResults as LiveData<Map<String, BluetoothDevice>>

    //get an instance of the local bluetooth adapter
    private val adapter: BluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
    //scanner we will use to discover nearby devices using our UUID
    private var scanner: BluetoothLeScanner? = null

    private var scanCallback: DeviceScanCallback? = null
    private val scanFilters: List<ScanFilter>
    private val scanSettings: ScanSettings

    init {
        scanFilters = createFilters()
        scanSettings = ScanSettings.Builder()
                .setScanMode(ScanSettings.SCAN_MODE_LOW_POWER)
                .build()
        startScan()
    }

    override fun onCleared() {
        super.onCleared()
        scanner?.stopScan(scanCallback)
        scanCallback = null
    }

    fun startScan() {
        if (scanCallback == null) {
            scanner = adapter.bluetoothLeScanner
            scanCallback = DeviceScanCallback()
            scanner?.startScan(scanFilters, scanSettings, scanCallback)
        }
    }

    /**
     * Use our unique UUID for filtering results for Bluetooth LE scans
     */
    private fun createFilters(): List<ScanFilter> {
        val builder = ScanFilter.Builder()
        builder.setServiceUuid(ParcelUuid(chatDiscoveryServiceID))
        val filter = builder.build()
        return listOf(filter)
    }

    /**
     * A callback on of device scanning
     * Set our scan results for discovered devices
     */
    private inner class DeviceScanCallback : ScanCallback() {
        override fun onBatchScanResults(results: List<ScanResult>) {
            super.onBatchScanResults(results)
            val res = mutableMapOf<String, BluetoothDevice>()
            for (item in results) {
                item.device?.let { device ->
                    res[device.address] = device
                }
            }
            _scanResults.value = res
        }

        override fun onScanResult(
            callbackType: Int,
            result: ScanResult
        ) {
            super.onScanResult(callbackType, result)
            val res = mutableMapOf<String, BluetoothDevice>()
            result.device?.let { device ->
                res[device.address] = device
            }
            _scanResults.value = res
        }
    }
}