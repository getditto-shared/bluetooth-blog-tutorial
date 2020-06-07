# Getting Started with Core Bluetooth

It’s really hard to overstate how much smartphones and tablets have transformed the world. Starting with the iPhone in 2007, these devices combine gorgeous and intuitive touch interfaces with a full suite of network technologies.

As an iOS developer, I wouldn’t consider myself a stranger to networking. It’s almost a bread-and-butter requirement that every app these days has *some* kind of REST API that handles the encoding and decoding of data to and from a remote source.

But all of that technology aside, one other massive side of smartphone networking I’ve never personally explored before is Bluetooth. And yet, sitting here, writing this post wearing wireless headphones, with an Apple Watch strapped to my wrist, after I just played some Animal Crossing on my Nintendo Switch with a wireless Pro Controller, I feel like Bluetooth is something I take for granted. It’s a black box of magic that I never worry about in my day-to-day life. It’s just there, and it just works™.

In all of my iOS engineering career, I’ve never been involved in a project, or had a need in any of my side projects to learn the Bluetooth APIs Apple provides. So when my buddy Max asked me if I’d be interested in writing an app to learn how Core Bluetooth works, and then write a blog on what I learned, I jumped at the chance.

This blog post is geared for anyone else in the same boat as me. Someone who might not necessarily be a newbie to developing for Apple platforms, but has just never stopped to learn how the APIs work. I’ll discuss the core concepts behind Core Bluetooth’s parent/child architecture, show how to send some basic data between devices, and then discuss some of the pitfalls I encountered.

## What is Core Bluetooth?

Core Bluetooth is Apple’s official public framework, and the only official way, for third party apps to integrate Bluetooth functionality into their apps on iOS and iPadOS.

Up until this point, Core Bluetooth has been an abstraction over Bluetooth Low Energy (BLE), which is a standard different from “classic” Bluetooth in that allows far more energy efficient communication with supporting low-powered devices. 

What this has historically meant is that Core Bluetooth was aimed at low powered peripheral devices such as heart rate sensors, or home automation. The sort of devices that primarily reside in a low power state and periodically broadcast small tidbits of information. 

Devices using classic Bluetooth for high powered, constant streaming of data (Things like game controllers, and wireless headphones) that consume much larger amounts of power were impossible to access from third party apps.

However, as of iOS 13, Apple expanded Core Bluetooth to also cover classic Bluetooth devices as well. While the public API hasn’t changed through this, it does mean that a much wider variety of wireless devices now became available through it.

With all of these amazing capabilities, there has never been a better time to start learning how to adopt Core Bluetooth.

## Basic Concepts of Core Bluetooth

When working with Core Bluetooth, it is necessary to become accustomed with the specific terminology of all of the major components of the service.

### Centrals and Peripherals

Bluetooth operates in a very traditional server-client sort of model. One device acts in a child capacity that produces information, and another acts as the overarching parent that receives this information and acts upon it.

In Bluetooth, these parent devices are referred to as “centrals” and child devices are referred to as “peripherals”. In most traditional Core Bluetooth setups, the iOS device will almost certainly always be the central, and any BLE devices paired to the iOS device will act as a peripheral.

(Insert a picture of an iPhone and a BLE device, labeling them as such).

### Services

Obviously, depending on the type of BLE device in question will determine what sort of capabilities it has. For example, a heart rate monitor can record a wearer’s heart rate, but a smart thermostat would record the current temperature of its location.

Most apps will be built to support a specific device’s capabilities. A health tracking app would have no interest in a thermostat. In order to encapsulate and report on the capabilities of specific peripherals, Bluetooth requires that peripherals identify their capabilities as “services”.

Peripherals will make themselves discoverable to centrals by broadcasting advertisement packets which will container which services they support. When a central scanning at the same time detects these packets and determines that the device it found supports services that it supports, then the two devices are recognized as compatible and can then connect to each other.

In order for centrals and peripherals to be able to recognize each others’ supported services, it is necessary for the ID of these services to match. For very specific apps and peripheral devices, it makes sense to define a service using a shared UUID between both devices.

However, in more general practice, it makes sense for peripherals to adopt Bluetooth services that are a standard capability globally. For example, it would make sense that any device that records blood pressure readings could be connected to *any* Bluetooth device capable of processing that data, regardless of whoever manufactured either device. As such, for common standards, [a public database exists](https://www.bluetooth.com/specifications/gatt/services/) that lists a standardized set of service IDs that can be used between both centrals and peripherals who want to adopt a specific use case.

### Characteristics

For any given service, any number of separate sets of information and/or services might be included with it. For example, a heart rate sensor peripheral might feature a heart rate service, but then contained within that service is both the raw current heart rate value, but also information on where the sensor is positioned over the wearer.

As such, services may contain any number of “characteristics” which perform various sub-functions of the service itself. They may be used to receive data from the peripheral, or send commands back to the peripheral. It is possible for centrals to explicitly query for information from a characteristic, or register an observer that will be called every time the characteristic has an update.

### Core Bluetooth Concepts Sum-up

Hopefully by this point, the basic layout of how Core Bluetooth will make sense to you. Parent devices are called centrals, and they connect to child devices known as peripherals. Peripherals manage their capabilities as services, which them themselves manage their capabilities via characteristics.

(Add a picture of a central linking to a peripheral)
(Add a picture of a peripheral pointing at a service, pointing at two characteristics)

## Putting it all into practice

Now that we've discussed the basic concepts of Core Bluetooth, we can start putting it into practice. For this post, I've built a companion sample app around Core Bluetooth. The app is a very chat app that allows two devices to connect to each other, and to then send messages between each other. The app demonstrates how to both scan as a central, and advertise a peripheral, to then connect to each other, and to then send messages both up-stream and downstream through one pipeline.

### Getting Started

For starters, before we do anything else, we need to add the `NSBluetoothAlwaysUsageDescription` key to our app's Info.plist describing why we want to use Bluetooth. If this key isn't present, not only would the app be rejected by the App Store on submission, but the app itself throws an exception when trying to call any Core Bluetooth APIs. This is a security requirement of Apple, as all apps must get explicit permission from the users before Bluetooth is enabled. For our case, let's explain we need Bluetooth to enable our chat service.

```
Access to Bluetooth allows you to chat with others on their own devices!
```

Once that's in place, we can start using Core Bluetooth. In Swift, every source file that integrates the framework, must have the following import statement.

```swift
import CoreBluetooth
```

### Scanning as a Central

For any iOS devices that fill the role of the central in a Bluetooth connection, they are represented by an object called `CBCentralManager`.

To begin, let's create a new instance:

```swift
let centralManager = CBCentralManager(delegate: self, queue: nil)
```
 
 As you can see, an object must be designated as a delegate upon instantiation. This object must conform to `CBCentralManagerDelegate`, and upon instantiation of this central manager, all of the necessary activity needed to start using Bluetooth is started immediately.
 
 Unfortunately, at this point, we can't start advertising yet. Bluetooth spends a non-trivial amount of time setting itself up to a state it could be considered as "powered on", so immediately after this, we must wait for the first delegate callback.
 
 ```swift
func centralManagerDidUpdateState(_ central: CBCentralManager) {
	guard central.state == .poweredOn else { return }
	// Start scanning for peripherals
}
 ```
 
 `centralManagerDidUpdateState` will be called every time the state of Bluetooth on this system changes. These include statuses such as when Bluetooth is resetting, or for if access is unauthorised for any reason. In a production-ready app, every single state should be properly handled, however in our case, we just need to only detect when the state of Bluetooth has reached "powered on". Once that has happened, we can start scanning.
 
 Scanning for peripherals is very easy. We just need to call `scanForPeripherals` and specify the services we are interested in.
 
 ```swift
let service = CBUUID(string: "AAAA") 
centralManager.scanForPeripherals(withServices: [service], options: nil]
 ```
 
 As mentioned above, services carry unique identifiers so peripherals and centrals may match them. In Core Bluetooth, these identifications are handled via the `CBUUID` object. In this case, we can use a simple string as the identifier.
 
 At this point, the device will now be scanning for peripherals with the same matching service identifier. At any point, a central can be checked if it is scanning by calling `centralManager.isScanning`.
 
### Advertising as a Peripheral

Now that our central is scanning, we need another device acting as a peripheral to advertise the same service were scanning for.

Similar to how centrals are managed via a `CBCentralManager`, peripherals are managed by instances of `CBPeripheralManager`.

```swift
.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
```
 
And exactly the same as central managers, peripheral managers take a delegate upon creation (This time conforming to `CBPeripheralManagerDelegate`) that also must wait for the state of Bluetooth to reach "powered on".

```swift
func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
	guard peripheral.state == .poweredOn else { return }
	
  // Start advertising this device as a peripheral
}
```

Once the state of the Bluetooth peripheral is powered on, the peripheral can then start advertising itself.

```swift
let service = CBUUID(string: "AAAA") 
peripheralManager.startAdvertising(
            [CBAdvertisementDataServiceUUIDsKey: [service],
             CBAdvertisementDataLocalNameKey: "Device Information"])
```

When advertising, similar to the central manager, supported services are specified as an array of `CBUUID` objects via the `CBAdvertisementDataServiceUUIDsKey`. One other key that may be used is the `CBAdvertisementDataLocalNameKey` key, which by default contains the name of this device (eg, "Tim's iPhone"), but may be modified to include more information about the state of this device that the central might find useful. For example, for a thermostat device, sending along the current temperate would mean the central device could immediately start displaying information before the connection has even started.

### Detecting a Peripheral from a Central

Now that one device is scanning, and one is advertising, both with the same service ID, they should be able to detect each other.

On the central side, when a peripheral is detected, the following delegate callback is called:

```swift
func centralManager(_ centralManager: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {

	// Perform any checks on `advertisementData` to confirm this is the correct device

	// Attempt to connect to this device
  centralManager.connect(peripheral, options: nil)

  // Retain the peripheral
  self.peripheral = peripheral
}
```

`didDiscoverPeripheral` will provide a lot of interesting information about the peripheral. The `advertismentData` dictionary will contain information about it like the devices name and manufacturer name, in addition to all of the service UUIDs it supports.

If necessary, it's possible to check if this peripheral supports  the services this central wants by checking the value of 
`advertisementData[CBAdvertisementDataServiceUUIDsKey]`. In addition, the RSSI value ([Received Signal Strength Indicator](https://en.wikipedia.org/wiki/Received_signal_strength_indication)) is useful in determining the distance of the peripheral. Sometimes it may be necessary to require a specific proximity for proper functioning, and this can be used to monitor that.

If we are happy that this peripheral is the one we want to connect to, we can then call `centralManager.connect()` to begin connecting to this peripheral. At the same time, since there's no way to access these peripheral objects outside of the delegate, it is also a good idea to retain it to a local property in your class. 

### Connecting to a Peripheral

Once we've discovered a peripheral and called `centralManager.connect()` on it, the central will attempt to connect to it. When it does, the following delegate method will be called:

```swift
func centralManager(_ centralManager: CBCentralManager, didConnect peripheral: CBPeripheral) {
  // Stop scanning once we've connected
  centralManager.stopScan()
  
	// Configure a delegate for the peripheral
  peripheral.delegate = self

	let service = CBUUID(string: "AAAA") 
  // Scan for the chat characteristic we'll use to communicate
  peripheral.discoverServices([service])
}
```

At this point, we have now become responsible for that peripheral, and instead of acting through the central manager object, we now work directly with the peripheral object. This peripheral object is of the type `CBPeripheral`, which is distinctly different from `CBPeripheralManager`.

As such, the first thing we do is assign ourselves as the delegate for this peripheral (Conforming to `CBPeripheralDelegate`) so we can receive events directly from it. Once we've done that, we then call `discoverServices` on the peripheral, which will let us access the characteristics inside of it.

### Discovering Characteristics inside a Peripheral's Service

Once we've set ourselves to be the delegate of a peripheral and requested to discover its services, the following method from `CBPeripheralDelegate` will be called:

```swift
func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
	// If an error occurred, print it, and then return
	if let error = error {
		print("Unable to discover services: \(error.localizedDescription)")
		return
	}

	// Specify the characteristic we want
	let characteristic = CBUUID("BBBB")

	// It's possible there may be more than one service, so loop through each one to discover the one that we want
	peripheral.services?.forEach { service in
		peripheral.discoverCharacteristics([characteristic], for: service)
	}
}
```

If an error occurs at this point, we must handle it and exit as gracefully as we can. Otherwise, our `peripheral` object is now populated with all of the services that it supports.

Now, just like how services are identified via a `CBUUID` object, so too are characteristics. Before we can subscribe to a characteristic and start reading out the data it contains, we must also discover it as a member of a service. In addition, as peripherals can have multiple services, it becomes necessary to iterate through each one to discover which one has the characteristic we are interested in.

As such, we iterate through all of the services in `peripheral.services` and attempt to discover the characteristic we want via its ID.

### Subscribing to a Characteristic
For a chat app, we're not interested in a passive stream of data from a peripheral; we want to be notified immediately when new data comes through. As such, we need to configure the peripheral to alert us whenever the characteristic is updated.

From above, once the characteristics of a service have been discovered, the following delegate callback will be called;

```swift
func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
	// Handle if any errors occurred
	if let error = error {
		print("Unable to discover characteristics: \(error.localizedDescription)")
		return
	}

	// Specify the characteristic we want
	let characteristicUUID = CBUUID("BBBB")

	// Perform a loop in case we received more than one characteristic
	service.characteristics?.forEach { characteristic in
		guard characteristic.uuid == characteristicUUID else { return }

		// Subscribe to this characteristic, so we can be notified when data comes from it
		peripheral.setNotifyValue(true, for: characteristic)

		// Hold onto a reference for this characteristic for sending data
		self.characteristic = characteristic
	}
}
```

From here, again, first we do any appropriate error handling if anything failed during the process.

Secondly, we've received a `service` object, but since a service can have any number of characteristics inside it, we must loop through it to discover the main one we want.

Once we've discovered the characteristic we want, we can then call `peripheral.setNotifyValue()` to `true` in order to start getting notified when the data in it changes.