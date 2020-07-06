# Getting Started with Core Bluetooth

It’s really hard to overstate how much smartphones and tablets have transformed the world. Starting with the iPhone in 2007, these devices combine gorgeous and intuitive touch interfaces with a full suite of network technologies.

As an iOS developer, I wouldn’t consider myself a stranger to networking. It’s almost a bread-and-butter requirement that every app these days has *some* kind of REST API that handles the encoding and decoding of data to and from a remote source.

But that side of the technology aside, one other huge side of networking on smartphone I’ve never personally explored before is Bluetooth. And yet, sitting here, writing this post wearing my wireless headphones, with an Apple Watch strapped to my wrist, after I just played some Animal Crossing on my Nintendo Switch with a wireless Pro Controller, I feel like Bluetooth is something I take for granted. It’s a black box of magic that I never worry about in my day-to-day life. It’s just there, and it just works™.

In all of my iOS engineering career, I’ve never been involved in a project, or had a need in any of my side projects to learn the Bluetooth APIs Apple provides. So when my buddy Max asked me if I’d be interested in writing an app in order to demonstrate how Core Bluetooth works, and then writing a blog post on the experience, I jumped at the chance.

This blog post is geared for anyone else in the same boat as me. Someone who might not necessarily be a newbie to developing for Apple platforms, but has just never stopped to learn how the Core Bluetooth APIs work. I’ll discuss the core concepts behind Core Bluetooth’s parent/child architecture, show how to send some basic data between devices, and then discuss some of the pitfalls I encountered.

## What is Core Bluetooth?

Core Bluetooth is an Apple public framework, and the only official way for third party apps to integrate Bluetooth functionality into their apps on iOS and iPadOS.

Up until this point, Core Bluetooth has been an abstraction over Bluetooth Low Energy (BLE), which is a standard different from “classic” Bluetooth in that allows far more energy efficient communication with supporting low-powered devices. 

What this has historically meant is that Core Bluetooth was aimed at low powered peripheral devices such as heart rate sensors, or home automation; the kinds of devices that primarily reside in a low power state and periodically broadcast small tidbits of information. 

Devices using classic Bluetooth by contrast, the much more high powered, constantly streaming data kinds (Things like game controllers, and wireless headphones) were previously impossible to access from third party apps.

However, as of iOS 13, Apple expanded Core Bluetooth to also cover classic Bluetooth devices as well. While the public API hasn’t changed through this, it does mean that a much wider variety of wireless devices now became available through it.

With all of these amazing capabilities, there has never been a better time to start learning how to adopt Core Bluetooth.

## Basic Concepts of Core Bluetooth

When working with Core Bluetooth, it is necessary to become accustomed with the specific terminology of all of the major components of the service and how they relate to each other.

### Centrals and Peripherals

Bluetooth operates in a very traditional server/client sort of model. One device acts in the capacity of a server that produces information, and another acts as a client that queries for this information and processes/displays it locally.

In Bluetooth, accessory devices that produce and store data are called "peripherals" and devices interested in accessing that data are called "centrals". In a traditional scenario, when two devices are wanting to connect to each other, the peripheral will broadcast an advertisement about itself, and the central will be scanning for that advertisement. As a general example, when pairing a pair of Bluetooth headphones to a smartphone, the smartphone would be the central, and the headphones would be the peripheral.

(Insert a picture of an iPhone and a BLE device, labelling them as such).

One very important thing to note. With the given parent/child terminology, it's very easy to assume that centrals act as the server, and peripherals act as the clients. 

However, as it turns out, this terminology is really only useful when designating the role of each device when connecting. One needs to be advertising, and one needs to be scanning.
 
Once a connection is formed, there is no longer any specific parent/child hierarchal relationship between the devices and both can behave as servers sending data between each other.

### Services

Obviously, depending on the type of BLE device in question will determine what sort of capabilities it has. For example, a heart rate monitor can record a wearer’s heart rate, but a smart thermostat would record the current temperature of its location.

Most apps will be built to support one or more specific class of device capability. For example, apps for tracking a users health would have no interest in connecting to devices that aren't health related, such as a thermostat. In order to encapsulate and report on the capabilities of specific peripherals, Bluetooth requires that peripherals identify their classes or capabilities as “services”.

Peripherals will make themselves discoverable to centrals by broadcasting advertisement packets defining the main identifying service they offer. When a central scanning at the same time detects these packets and determines that the peripheral device it found supports the same class of service that it is searching for, then the central can determine that they it is compatible with the peripheral and can begin the process of connecting to each other. Traditionally, while only the main service of the device is advertised, once a connection is formed, the central can then query the peripheral for any additional services it offers.

In order for the central to determine it is compatible with a peripheral, it needs to know the ID values of the services that the peripheral supports. For very specific apps and peripheral devices, it makes sense to define a service using a shared UUID between both devices.

However, in more general practice, it makes sense for peripherals to adopt Bluetooth services that are a standard capability globally. For example, it would make sense that any device that records blood pressure readings could be connected to *any* Bluetooth device capable of processing that data, regardless of whoever manufactured either device. As such, for common standards, [a public database exists](https://www.bluetooth.com/specifications/gatt/services/) that lists a standardized set of service IDs that can be used between both centrals and peripherals who want to adopt a specific use case.

### Characteristics

For any given service, any number of separate sets of information and/or services might be included within it. For example, a heart rate sensor peripheral might feature a heart rate service, but then contained within that service is both the raw current heart rate value, but also information on where the sensor is positioned over the wearer at the time.

As such, services may contain any number of “characteristics” which record various types of data, or perform various sub-functions of the service itself. They may be used to receive data from the peripheral, or send commands back to the peripheral. It is possible for centrals to explicitly query for information from a characteristic, or register an observer that will be called every time the characteristic has an update.

This concept of Bluetooth devices offering their capabilities as services and characteristics is officially called GATT, which is short for Generic Attribute Profile.

### Core Bluetooth Concepts Summary

Hopefully by this point, the basic layout of how Core Bluetooth will make sense to you. Parent devices are called centrals, and they connect to child devices known as peripherals. Peripherals manage their capabilities as services, who then manage their own capabilities via characteristics.

(Add a picture of a central linking to a peripheral)
(Add a picture of a peripheral pointing at a service, pointing at two characteristics)

## Putting it all into practice

Now that we've discussed the basic concepts of Core Bluetooth, we can start putting it into practice. For demonstrating the flow of connecting two devices, I've built a companion sample app around Core Bluetooth. The app is a very basic chat app that allows two devices to connect to each other, and to then send messages between each other. The app demonstrates how to both scan as a central and advertise a peripheral, to then connect to each other, and to then send messages both upstream and downstream through one pipeline.

### Getting Started

For starters, before we do anything else, we need to add the `NSBluetoothAlwaysUsageDescription` key to our app's Info.plist describing why we want to use Bluetooth. If this key isn't present, not only would the app be rejected by the App Store on submission, but the app itself throws an exception when trying to call any Core Bluetooth APIs. This is a security requirement of Apple, as all apps must get explicit permission from the user before Bluetooth is enabled. For our case, let's explain we need Bluetooth to enable our chat service.

```
Access to Bluetooth allows you to chat with others from their own devices!
```

Once that's in place, we can start using Core Bluetooth. In Swift, every source file that integrates the framework, must have the following import statement.

```swift
import CoreBluetooth
```

### Scanning as a Central

For iOS devices that fill the role of the central in a Bluetooth connection, they are represented by an object called `CBCentralManager`.

To begin, let's create a new instance:

```swift
let centralManager = CBCentralManager(delegate: self, queue: nil)
```
 
 As you can see, an object must be designated as a delegate upon instantiation. This object must conform to `CBCentralManagerDelegate`, and upon instantiation of this central manager, all of the necessary activity needed to start using Bluetooth is started immediately.
 
At this point, we can't start scanning yet. Bluetooth spends a non-trivial amount of time setting itself up to a state it could be considered as "powered on", so immediately after this, we must wait for the first delegate callback.
 
 ```swift
func centralManagerDidUpdateState(_ central: CBCentralManager) {
	guard central.state == .poweredOn else { return }
	// Start scanning for peripherals
}
 ```
 
 `centralManagerDidUpdateState` will be called every time the state of Bluetooth on this system changes. These include statuses such as when Bluetooth is resetting, or for if access is unauthorised for any reason. In a production-ready app, every single state should be properly handled, however in our case, we just need to only detect when the state of Bluetooth has reached "powered on". Once that has happened, we can then start scanning.
 
 Scanning for peripherals is very easy. We just need to call `scanForPeripherals` and specify the services we are interested in.
 
 ```swift
let service = CBUUID(string: "AAAA") 
centralManager.scanForPeripherals(withServices: [service], options: nil]
 ```
 
 As mentioned above, services carry unique identifiers so peripherals and centrals may match them. In Core Bluetooth, these identifications are handled via the `CBUUID` object, and for this specific case, we can use a simple string as the identifier.
 
 At this point, the device will now be scanning for peripherals with the same matching service identifier. At any point, a central can be checked if it is scanning by calling `centralManager.isScanning`.
 
### Advertising as a Peripheral

Now that our central is scanning, we need another device acting as a peripheral to advertise the same service we're scanning for.

Similar to how centrals are managed via a `CBCentralManager`, peripherals are managed by instances of `CBPeripheralManager`.

```swift
peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
```
 
And exactly the same as central managers, peripheral managers require a delegate upon creation (This time conforming to `CBPeripheralManagerDelegate`) that also must wait for the state of Bluetooth on the device to reach "powered on".

```swift
func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
	guard peripheral.state == .poweredOn else { return }
	
  // Start advertising this device as a peripheral
}
```

Once the state of the Bluetooth peripheral is powered on, the peripheral can then start advertising itself.

```swift

let characteristicID = CBUUID(string: "BBBB")

// Create and configure our characteristic     
let characteristic = CBMutableCharacteristic(type: characteristicID, properties: [.write, .notify], value: nil, permissions: .writeable)

// Create our service, and add our characteristic to it
let serviceID = CBUUID(string: "AAAA")
let service = CBMutableService(type: serviceID, primary: true)
service.characteristics = [characteristic]

// Register this service to our peripheral manager
peripheralManager.add(service)

// Begin advertising, explicitly requesting it includes our registered service via its identifier
peripheralManager.startAdvertising(
            [CBAdvertisementDataServiceUUIDsKey: [service],
             CBAdvertisementDataLocalNameKey: "Device Information"])
```

There's a fair bit to unpack here, but if we step through it one part at time it's nothing too complicated. 

1. We create a characteristic, and assign it the standardised characteristic UUID that the central will be expecting. We also need to explicitly mark the characteristic as writable here, so the central can send data back to the peripheral through it.
2. We then create a service object, with the standardised service UUID and we set its type to primary to ensure it is advertised as the "main" service of this peripheral.
3. We then advertise the peripheral with the same service UUID. In addition, while the `CBAdvertisementDataLocalNameKey` key normally holds the device name of this peripheral, it can be modified to hold additional data that the central could potentially use (eg, the current temperature for a thermostat).

### Detecting a Peripheral from a Central

Now that one device is scanning and one is advertising both with the same service ID, they should be able to detect each other.

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
`advertisementData[CBAdvertisementDataServiceUUIDsKey]`. In addition, the RSSI value ([Received Signal Strength Indicator](https://en.wikipedia.org/wiki/Received_signal_strength_indication)) is useful in determining the distance of the peripheral. Sometimes it may be necessary to require a specific proximity for proper functioning, and this value can be used to monitor for that.

If we are happy that this peripheral is the one we want to connect to, we can then call `centralManager.connect()` to begin connecting to it. At the same time, since there's no way to access these peripheral objects outside of the delegate, it is also a good idea to retain it to a local property in your class. 

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

As such, the first thing we do is assign ourselves as the delegate for this peripheral (Conforming to `CBPeripheralDelegate`) so we can receive events directly from it. Once we've done that, we then call `discoverServices` on the peripheral, which will let us confirm the services it supports, and then subsequently access the service characteristics we need.

### Discovering Characteristics inside a Peripheral's Service

Once we've set ourselves to be the delegate of a peripheral and performed the request to discover its services, the following method from `CBPeripheralDelegate` will be called:

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

If an error occurs at this point, we must handle it and exit as gracefully as we can. Otherwise our `peripheral` object has now been populated with all of the services that it supports.

Now, just like how services are identified via a `CBUUID` object, characteristics are identified in the same way. Before we can subscribe to a characteristic and start reading out the data it contains, we must also discover it as a member of a service. In addition, as peripherals can have multiple services, it becomes necessary to iterate through each one to discover which one has the characteristic we are interested in.

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

### Confirming Notifications from the Peripheral was set
One of the final steps in the process is that the peripheral will report whether setting the characteristic to notify the central was successful or not. Whether it succeeded or failed, the following delegate will be triggered

```swift
func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
	// Perform any error handling if one occurred
	if let error = error {
		print("Characteristic update notification failed: \(error.localizedDescription)")
		return
	}

	// Ensure this characteristic is the one we configured
	guard characteristic.uuid == characteristicUUID else { return }

	// Check if it is successfully set as notifying
  if characteristic.isNotifying {
		print("Characteristic notifications have begun.")
	} else {
		print("Characteristic notifications have stopped. Disconnecting.")
		centralManager.cancelPeripheralConnection(peripheral)
	}
	
	// Send any info to the peripheral from the central
}
```
While I don't think it is strictly explicitly required to implement this method, if the subscription failed, it would make sense to detect this and attempt to subscribe again (or perform any cleanup code if needed) at this point.

Additionally, if the central has data pending that it would like to send to the peripheral, this would be best place to send it.

### Sending data to the Peripheral
Once the central manager has successfully been able to capture both the peripheral and the relevant characteristic, the central can then start sending data to the peripheral via this characteristic. One thing to note is that the characteristic must have been explicitly configured on the peripheral's side to be writable by the central.

At any point after that, it's possible to send data to the peripheral by calling

```swift
let data = messageString.data(using: .utf8)!
peripheral.writeValue(data, for: characteristic, type: .withResponse)
```

The `type` argument lets you specify whether you want the peripheral to reply that it received the data or not. This is great for discerning between types of data that might be explicitly required in a certain order, and data that is often repeated, so if the peripheral didn't catch it, nothing of value was lost.

### Sending data to the Central
On the opposite side, sending data to a central from the peripheral's side is a similar method:

```swift
let data = messageString.data(using: .utf8)!
peripheralManager.updateValue(data, for: characteristic, onSubscribedCentrals: [central])
```

### Receiving Data from a Peripheral
Finally, after all that, we're ready to start receiving data from the peripheral. In order to be notified of when new data has arrived from a characteristic, you use the following delegate:

```swift
func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
	// Perform any error handling if one occurred
	if let error = error {
		print("Characteristic value update failed: \(error.localizedDescription)")
		return
	}

	// Retrieve the data from the characteristic
	guard let data = characteristic.value else { return }

	// Decode/Parse the data here
	let message = String(decoding: data, as: UTF8.self)
}
```

### Receiving Data from a Central
Last of all, when a peripheral receives data from a central, the following method of `CBPeripheralManager` will be called:

```swift
func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
	guard let request = requests.first, let data = request.value else { return }
	
	let message = String(decoding: data, as: UTF8.self)
}
```

One thing of which to be extra aware is that if the characteristic was not set as writeable at its time of creation, then sending data to the peripheral will silently fail and this delegate will never be called.

### Summary
So after going through each step, it's obvious to see that sending data over Core Bluetooth does involve quite a few steps. From the peripheral side, peripherals have to configure and advertise their services and characteristics, and manage when centrals subscribe and unsubscribe. From the central side, subscribing to a characteristic is a multi-step process from scanning for the peripheral, to connecting to the peripheral, discovering the peripheral's services, discovering the service's characteristics and then subscribing to them.

However with all that being said, once you understand the terminology, and how each object in the chain is related to the next, everything falls into place relatively easily.

## Challenges with the Chat App
While the above introduction to the Core Bluetooth API shows in general the basic steps of connecting a central and a peripheral, when writing the chat app, a rather large hurdle appeared immediately: who is the central and who is the peripheral?

In a classic use case where a low powered sensor is connected to an iPhone, the role of central and peripheral is clear cut. However, in a connection between two iPhones, suddenly who plays which role becomes a much harder decision.

One neat thing that might not be obvious from the start is that Core Bluetooth can make a device be a central and a peripheral at the same time, in that it is simultaneously both scanning and advertising.

// Show a screenshot of the discovery view controller

When a device has opened the app to the device discovery screen, it will create both a central manager and a peripheral manager, and will start scanning and advertising respectively at the same time. 

Any devices in range will be doing the same thing, so in this way, any other devices our device detects can be shown on-screen, and likewise any other devices that detect our device will show our device on their screen.

While the device discovery screen is interested in detecting all available devices we could potentially chat with, once we go into a chat session window, we only want to receive messages from the remote device we selected.

In this case, when the user taps on the device they want to talk to, the hardware UUID of the selected device is saved, and the chat window is opened up holding a copy of the UUID. When both devices have opened to the same chat window, both devices will be set to scan like a standard central, and a connection won't occur yet. To avoid detecting devices advertising for the device discovery menu, a different service UUID is used for these connections.

Both devices performing scanning continues to happen until the first time either participant in the chat submits a message in the chat. When this happens, that particular device becomes a peripheral and starts advertising itself as such. When this happens the other device detects the first device and connects to it as a central. In essence, whoever chats first becomes the peripheral, and whoever chats last remains the central and the two share a single connection. During the advertisement, the saved hardware UUID is used to determine the identity of the connecting device, to guarantee someone else from a different session who happened to start broadcasting didn't accidentally join instead.

Overall, this method might seem a bit strange. On a more pragmatic level, it might make more sense to set up and maintain 2 connections, where each device is its own central connected to another peripheral. However in practice, this can lead to more unreliably as now there are 2 connections that could potentially fail if there is any interference.

## Technical Reflection
Now that we've discussed the Core Bluetooth API and its design pattern, it should be easy to understand how to work with it. That being said, what we've looked at here has been the bare minimum of getting Core Bluetooth moving and *would absolutely not be sufficient for a production app*. 

The folks here at Ditto use Core Bluetooth in their flagship product, and by extension, Bluetooth Low Energy itself for Android support. In addition to some of the challenges and limitations I experienced in this project, here are some of the challenges the Ditto engineers have faced as well.

### Asymmetric Connections
As mentioned above, Bluetooth operates in a very traditional client/server model with regards to centrals and peripherals. In scenarios where this model makes sense, this is fine, but like our chat app, where ideally both devices should be identical, this comes up as a limitation. With enough effort however, it is possible to build an abstraction on top of this that makes the system perform like a traditional 2-way stream.

### Limited Message Sizes
One thing I completely glossed over is that the amount of data that can be sent through a characteristic has a very hard limit, and that limit changes between devices. Historically, it's been 20 bytes, but on more modern phone hardware, it can be around 180 bytes. For a chat app where the payload is very small per message, it isn't so much of a concern, but it certainly is something that a production app needs to take seriously. Core Bluetooth is capable of detecting and  reporting the acceptable length of each message, and if a device wants to send more than that, then it's the responsibility of your own code to chunk that data up and send it as multiple messages.

### Speed Limitations
The maximum speed of communicating via GATT is only really a few kilobytes per second. Again, in our chat app, this is a limitation that we would never bump up against, but in more heavier applications, this could easily become a bottleneck quickly. Depending on your use case, you might have to optimise your message payloads to be more efficient.

### Additional Speed Penalties With Reliable Delivery
When specifying writing data to a characteristic with the `.withResponse` attribute (guaranteeing the peripheral will confirm it received the data), this roundhouse operation also incurs an additional speed penalty. For use cases that require the absolute top most speed, it is usually best to rely on unreliable delivery instead and to implement your own error correction logic.

### Different Levels of Control Per Platform
While Core Bluetooth instigates its own specific policies, these may not apply to the equivalent BLE implementations on other devices such as Android. A big example of this is the limitations Core Bluetooth imposes on how much and what sort of data can be included in the advertising packets of a peripheral. As such, when building a product that might have an equivalent Android counterpart, care must be taken to ensure the interfaces behave the same way.

### Security/Privacy Policies with Backgrounded Apps
While the regular Bluetooth stack on iOS functions regardless of onscreen activity, Apple has implemented strict privacy policies on apps adopting BLE. When a peripheral device app is backgrounded, it will continue to advertise, but the "Local Name" property will no longer be included. Additionally backgrounded centrals will no longer receive repeating advertisements from any peripherals in range.

This particular limitation has been a big point of contention for organisations who have been trying to build COVID-19 contact tracing apps on top of Core Bluetooth.

### Extremely Complex API to Work With
While it certainly becomes easier to work with over time, Core Bluetooth certainly isn't an easy framework to get up and running quickly with. In order to start sending and receiving data, a very long process of steps need to be followed in order to slowly capture all of the objects you need. 

Compounding this, the steps are done via callbacks one after another, one at a time, and sometimes even where one delegate daisy-chains a new delegate (as is the case with `CBPeripheral`). Working out the process needed for your own use case can be very time-consuming and require a lot of cognitive load.

### Demands Bullet-Proof Error Checking and Handling
At any point of the delegate callback process, errors could easily happen that derails the whole process. As a wireless technology, Bluetooth is prone to interference, or randomly losing devices. As such, all of the delegate code needs to have bullet-proof error handling at every step in order to handle issues that can potentially occur at any step of the process. This can also sometimes potentially mean proactive heartbeats or state checks in case an expected callback failed to occur.

### Occasional Instability and General Odd Behaviour
Even though Core Bluetooth is quite old at this point, there is still some occasional odd behaviour that can happen quite reliably:

* Sometimes if the sending queue is filled to capacity, a callback to say it has cleared will sometimes be skipped. This requires periodically testing the queue to see its state.
* Certain specific devices (Like iPad mini 4 and iPhone 6) can potentially accidentally stop scanning if they are locked and then unlocked.

### Lack of Encryption
Given that some forms of data transmitted over Bluetooth could be quite private or personal (eg, a person's health records), encryption is always strongly recommended. While a form of BLE encryption exists, it is not reliable. As such, in your own implementations, you might need to consider writing your own encryption layer and all of the (error correcting) implications that would entail.

## Conclusion
When I first got the chat app working, and the text I typed on one phone automatically appeared on the other, it felt absolutely magical. I had a fantastic time learning Core Bluetooth in order to write this post, and I hope you found everything here useful!

But at the end of this, one thing is certainly clear. Implementing your own Core Bluetooth implementation is *hard*. It involves a lot of steps, and a lot can go wrong at any point in the user's whole experience. If you're an engineer researching Core Bluetooth because you're looking to build a new product that implements that sort of local communication, instead of rolling a new implementation from scratch, I'd recommend you consider checking out the synchronisation technology from Ditto. Ditto's tech stack has already taken care of all of the challenges listed above, and would make integrating communications into your app a breeze.

Thanks for reading!

