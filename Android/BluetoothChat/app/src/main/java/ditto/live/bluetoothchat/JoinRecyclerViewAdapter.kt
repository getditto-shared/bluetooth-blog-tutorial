package ditto.live.bluetoothchat

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.appcompat.widget.AppCompatTextView
import androidx.recyclerview.widget.RecyclerView

class JoinRecyclerViewAdapter(private val onDeviceSelected: (BluetoothDevice) -> Unit
): RecyclerView.Adapter<RecyclerView.ViewHolder>()  {
    private var devices = emptyList<BluetoothDevice>()
    private val bluetoothName: String

    companion object {
        private const val LOGO_TYPE = 0
        private const val HEADER_TYPE = 1
        private const val MY_DEVICE_TYPE = 2
        private const val DEVICE_TYPE = 3
        private const val STATIC_LIST_SIZE = 4
    }

    init {
        bluetoothName = BluetoothAdapter.getDefaultAdapter().name
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        val view: View
        if (viewType == LOGO_TYPE) {
            view = LayoutInflater.from(parent.context).inflate(R.layout.logo_item, parent, false)
            return LogoViewHolder(view)
        } else if (viewType == HEADER_TYPE) {
            view = LayoutInflater.from(parent.context).inflate(R.layout.join_header_item, parent, false)
            return HeaderViewHolder(view)
        } else {
            view = LayoutInflater.from(parent.context).inflate(R.layout.device_item, parent, false)
            return DeviceViewHolder(view)
        }
    }

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        if (getItemViewType(position) == HEADER_TYPE) {
            if (position == 1) {
                (holder as HeaderViewHolder).headerLabelView.text = "My Device Name"
            } else {
                (holder as HeaderViewHolder).headerLabelView.text = "DEVICE NAME"
            }
        } else if (getItemViewType(position) == MY_DEVICE_TYPE) {
            (holder as DeviceViewHolder).deviceNameLabelView.text = bluetoothName
        } else if (getItemViewType(position) == DEVICE_TYPE) {
            val device = devices[position - STATIC_LIST_SIZE]
            (holder as DeviceViewHolder).deviceNameLabelView.text = device.name
            holder.itemView.setOnClickListener {
                onDeviceSelected(device)
            }
        }
    }

    override fun getItemCount(): Int = devices.size + STATIC_LIST_SIZE

    inner class DeviceViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val deviceNameLabelView: AppCompatTextView = view.findViewById(R.id.device)
    }

    inner class LogoViewHolder(view: View) : RecyclerView.ViewHolder(view) {

    }

    inner class HeaderViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val headerLabelView: AppCompatTextView = view.findViewById(R.id.header)
    }

    fun updateDevices(devices: List<BluetoothDevice>) {
        this.devices = devices
        notifyDataSetChanged()
    }

    override fun getItemViewType(position: Int): Int {
        if (position == 0) {
            return LOGO_TYPE
        } else if (position == 1 || position == 3) {
            return HEADER_TYPE
        } else if (position == 2) {
            return MY_DEVICE_TYPE
        }

        return DEVICE_TYPE
    }
}