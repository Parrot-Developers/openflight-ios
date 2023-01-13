![OpenFlight](https://developer.parrot.com/img/openflight@2x.png "OpenFlight")

**Get an ARCGIS Key (in order to display the map)**
Get a new Key : [https://developers.arcgis.com/](https://developers.arcgis.com/)

Put your Api Key here : AppDelegate.swift, L74
// ARCGIS KEY - Openflight
AGSArcGISRuntimeEnvironment.apiKey = "put your key here"


# **Install with pods**

_CocoaPods is a dependency manager for Swift and Objective-C Cocoa projects. It has over 30 thousand libraries and is used in over 1.9 million apps. CocoaPods can help you scale your projects elegantly._ [https://cocoapods.org](https://cocoapods.org/)

_ **You first need to install CocoaPods.** _

CocoaPods is built with Ruby and it will be installable with the default Ruby available on macOS. You can use a Ruby Version manager, however we recommend that you use the standard Ruby available on macOS unless you know what you&#39;re doing.

Using the default Ruby install will require you to use `sudo` when installing gems. (This is only an issue for the duration of the gem installation, though.)

`$ sudo gem install cocoapods`

**Install the Openflight App and Pods**

Clone OpenFlight:

`$ git clone https://github.com/Parrot-Developers/openflight-ios.git`

Or download the zip file:

[https://github.com/Parrot-Developers/openflight-ios/archive/main.zip](https://github.com/Parrot-Developers/openflight-ios/archive/main.zip)

Open Terminal and navigate to the directory that contains your OpenFlightApp by using the `cd` command:

`$ cd ~/Path/To/Folder/Containing/OpenFlight`

Enter the command (be sure to close Xcode before):

`$ pod install`

Once the installation completes, you can open the  **OpenFlightApp**  with the Xcode workspace: _OpenFlight.xcworkspace_ 

Or using the `xed` command:

`$ xed ~/Path/To/Folder/Containing/OpenFlight` or `$ xed .` if already inside the path that contains OpenFlight.

