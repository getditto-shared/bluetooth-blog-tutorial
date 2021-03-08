package ditto.live.bluetoothchat

import android.bluetooth.BluetoothDevice
import android.os.Bundle
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.viewModels
import androidx.lifecycle.Observer
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import ditto.live.bluetoothchat.services.BluetoothChatService

class JoinFragment : Fragment() {

    private val viewModel: BluetoothScanViewModel by viewModels()

    private val adapter by lazy {
        JoinRecyclerViewAdapter(onDeviceSelected)
    }

    private val onDeviceSelected: (BluetoothDevice) -> Unit = { device ->
        BluetoothChatService.setCurrentDevice(requireActivity().application, device)
        val fragment = ChatFragment()
        requireActivity().supportFragmentManager.beginTransaction()
                .add(R.id.container, fragment)
                .commit()
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        val view = inflater.inflate(R.layout.fragment_join, container, false) as RecyclerView
        view.layoutManager = LinearLayoutManager(context)
        view.adapter = adapter
        return view
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        viewModel.scanResults.observe(viewLifecycleOwner, scanResultObserver)
    }

    private val scanResultObserver = Observer<Map<String, BluetoothDevice>> { results ->
        showResults(results)
    }

    private fun showResults(devices: Map<String, BluetoothDevice>) {
        adapter.updateDevices(devices.values.toList())
    }
}