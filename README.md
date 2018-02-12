# Verbal interaction with the robot Double
## Natural language generation

---

### Team

* Andrea Antoniazzi
* Luigi Secondo

___

### Plan draft

Work has been divided in two sub-programs:
- Develop an iOS application in swift to be run in the robot
- Develop a python server to be run in a computer 

1. SWIFT: elaborate internal state
2. PYTHON: create a web socket server
3. SWIFT: send state to server via web socket
4. PYTHON: generate from state a "human" sentence and send back
5. SWIFT: speech received sentence

___

### 1. Elaborate internal state
In order to elaborate internal state we decided to take care of these particular infos:
* __Battery level__: the following code is used to obtain battery level to be sent to the server: 
```swift
var batteryL: Float {
    return UIDevice.current.batteryLevel
}
print("bottone premuto")
UIDevice.current.isBatteryMonitoringEnabled = true
var batteryLevel : Int
batteryLevel = Int(batteryL * 100)
```

___

### 2. Create a web socket server
After a research for possible solutions to implement a web socket server in Phyton, we decided to use [Tornado](http://www.tornadoweb.org/en/stable/). It is a Python web framework and asynchronous networking library. Tornado can scale to tens of thousands of open connections, making it ideal for long polling, WebSockets, and other applications that require a long-lived connection to each user.

The server is developed generating a single class called `server` which implements all the functionalities of a web server.
It is requested to use Python 2.7  and to install Tornado. It is also necessary to import tornado libraries in the code: 
```python
import tornado.httpserver
import tornado.websocket
import tornado.ioloop
import tornado.web
import socket
```
Main server class:
```python
class server(tornado.websocket.WebSocketHandler):
    def open(self):
        # Called when a new connection is enstablished
        localtime = time.asctime(time.localtime(time.time()))
        print (colors.OKBLUE +'[' + localtime + ']'+ colors.ENDC +
            ' - Welcome new client! Ipv6: ' + self.request.remote_ip)

    def on_message(self, message):
        # called when a new message arrives from the clients
        localtime = time.asctime(time.localtime(time.time()))
        print (colors.OKBLUE +'[' + localtime + ']'+ colors.ENDC +
            ' - New Message recieved from: ' + self.request.remote_ip + ' -> ' + message)
        newMessage = messageHandler(message)
        self.write_message(newMessage)

    def on_close(self):
        # called when a connection is closed
        localtime = time.asctime(time.localtime(time.time()))
        print (colors.OKBLUE +'[' + localtime + ']'+ colors.ENDC +
            ' - Bye Bye ' + self.request.remote_ip)

    def check_origin(self, origin):
        return True
```

___

### 3. Send state server via web socket

After a research for possible solutions to implement a web socket client in swift, we decided to use the Swift framework called SwiftWebSocekt (here is link for [github repository](https://github.com/tidwall/SwiftWebSocket))
It is a library expressly developed to create a WebSocket client and the API is modeled after the Javascript API.
With a single function, called for each request, it is possible to manage all the aspects relative to a connection with a server.
It is required to add SwiftWebSocket framework to the project ( we suggest to use [Carthage](https://github.com/Carthage/Carthage)) and the directive `import SwiftWebSocket`.
```swift
func echoText(infoText : String){
        // set web server adress and port 
        let ws = WebSocket("ws://192.168.1.1:4040/websocketserver")
        // called to send data to server
        let send : ()->() = {
            ws.send(infoText)
        }
        // called to open a connection
        ws.event.open = {
            print("opened")
            send()
        }
        // called to close a connection
        ws.event.close = { code, reason, clean in
            print("close")
        }
        // connection error management
        ws.event.error = { error in
            print("error \(error)")
        }
        // generation of message to be sent
        ws.event.message = { message in
            let text = message
            print("recv: \(text)")
            // calling speech function (see point 5 for more details)
            self.speechFunc(speech: String(describing: message))
            }
        }
```
Internal state informations are sent via a predefined standard to compose a string as follows: 
```python
"Type value" + "_" + " value "

# Predefined value id:
iPad battery level: battery
ip adress of iPad: ipAdress

# Example: battery level is 56%
"battery_56"
```
___

### 4. Generate a natural language sentence

In order to compose natural language sentences we decided to formulate phrases dividing them in 3 blocks: first one is 
___

### 5. Speech received sentence

For speech generation we decided to use AVFoundation framework developed by Apple, because it is easly integrable in an iOS application. To utter a sentence you have to implement this symple code in the main class `ViewController: UIViewController`:
```swift
let synth = AVSpeechSynthesizer()
var myUtterance = AVSpeechUtterance(string: "")

func speechFunc(speech : String){
        myUtterance = AVSpeechUtterance( string: speech)
        myUtterance.rate = 0.5
        synth.speak(myUtterance)
    }
```
___

### Sources
* Swift: [Interacting with Objective-C APIs](https://developer.apple.com/library/content/documentation/Swift/Conceptual/BuildingCocoaApps/InteractingWithObjective-CAPIs.html#//apple_ref/doc/uid/TP40014216-CH4-ID35)
* Text to speech app swift 2014: [Tutorial](https://code.tutsplus.com/tutorials/create-a-text-to-speech-app-with-swift--cms-22229)
* Corso base di swift: [Pagina](https://www.xcoding.it/lezione/programmazione-ad-oggetti-in-swift/)
* Web socket Swift library: [SwiftWebSocket](https://github.com/tidwall/SwiftWebSocket)
* Web socket Python library: [Tornado](http://www.tornadoweb.org/en/stable/)
* Double API repository [Github](https://github.com/doublerobotics/Basic-Control-SDK-iOS)
