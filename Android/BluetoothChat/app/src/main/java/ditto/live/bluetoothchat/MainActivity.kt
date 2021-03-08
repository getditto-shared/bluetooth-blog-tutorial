package ditto.live.bluetoothchat

import android.Manifest
import android.content.pm.PackageManager
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import androidx.core.content.ContextCompat
import ditto.live.bluetoothchat.services.BluetoothDeviceDiscovery

private const val LOCATION_REQUEST_CODE = 1001

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val fragment = JoinFragment()
        supportFragmentManager.beginTransaction()
            .add(R.id.container, fragment)
            .commit()
    }

    override fun onStart() {
        super.onStart()
        checkLocationPermission()
    }

    override fun onStop() {
        super.onStop()
        BluetoothDeviceDiscovery.stopDiscovery()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when(requestCode) {
            LOCATION_REQUEST_CODE -> {
                if (grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    BluetoothDeviceDiscovery.startDiscovery(application)
                }
            }
        }
    }

    /**
     * BLE SCAN
     * ACCESS_FINE_LOCATION is required for Android 10 and above
     */
    private fun checkLocationPermission() {
        val hasLocationPermission = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        if (hasLocationPermission) {
            BluetoothDeviceDiscovery.startDiscovery(application)
        } else {
            requestPermissions(
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                LOCATION_REQUEST_CODE
            )
        }
    }
}