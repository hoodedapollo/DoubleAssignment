//
//  ViewController.swift
//  WebSocket
//
//  Created by Luigi Secondo on 11/02/2018.
//  Copyright © 2018 Luigi Secondo. All rights reserved.
//

import UIKit
import SwiftWebSocket
import AVFoundation

struct DoubleMessage : Codable {
    var typeID: String
    var value: String
    var userName: String
}
// set web server adress and port variable (they can be changed directly in the app)
var ws = WebSocket()

class ViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: Properties
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var serverIpLabel: UILabel!
    @IBOutlet weak var serverIpText: UITextField!
    @IBOutlet weak var serverPortText: UITextField!
    @IBOutlet weak var serverPortLabel: UILabel!
    
    
    
    let synth = AVSpeechSynthesizer()
    var myUtterance = AVSpeechUtterance(string: "")
    

    override func viewDidLoad() {
        super.viewDidLoad()
        //set default webserver address (it can be changed in the user interface)
        // to be fixed
        nameTextField.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        userNameLabel.text = textField.text
    }
    
    // Username  actions
    @IBAction func setDefaultName(_ sender: UIButton) {
        userNameLabel.text = "Emaro student"
        nameTextField.text = ""
    }
    
    @IBAction func Battery(_ sender: UIButton) {
        // This function is called to get device's battery
        var batteryL: Float {
            return UIDevice.current.batteryLevel
        }
        UIDevice.current.isBatteryMonitoringEnabled = true
        var batteryLevel : Int
        batteryLevel = Int(batteryL * 100)
        // Once obtained battery state, the value is stored in the structure and then encoded in JSON string
        let toSpeech = DoubleMessage(typeID: "battery", value: String(batteryLevel), userName: userNameLabel.text!)
        let jsonEncoder = JSONEncoder()
        let jsonData = try? jsonEncoder.encode(toSpeech)
        let jsonString = String(data: jsonData!, encoding: .utf8)
        echoText(infoText : jsonString!)
    }
    
    @IBAction func ipAdress(_ sender: UIButton) {
        var ipAdress : [String]
        ipAdress = getIFAddresses()
        // Select the desired ip address from the returned list in order to use it. ex: ipAdress[1]
        // Once obtained ip address, the value is stored in the structure and then encoded in JSON string
        let toSpeech = DoubleMessage(typeID: "ipAddress", value: ipAdress[1], userName: userNameLabel.text!)
        let jsonEncoder = JSONEncoder()
        let jsonData = try? jsonEncoder.encode(toSpeech)
        let jsonString = String(data: jsonData!, encoding: .utf8)
        echoText(infoText : jsonString!)
    }
    
    func echoText(infoText : String){
        // set web server address via user interface
        let sendadress1 = "ws://" + serverIpText.text!
        let sendadress2 = ":" + serverPortText.text! + "/websocketserver"
        let sendadress = sendadress1 + sendadress2
        ws = WebSocket(sendadress)
        
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
            // calling speech function
            self.speechFunc(speech: String(describing: message))
            }
        }

    func speechFunc(speech : String){
        myUtterance = AVSpeechUtterance( string: speech)
        myUtterance.rate = 0.2
        synth.speak(myUtterance)
    }
    func getIFAddresses() -> [String] {
        var addresses = [String]()
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return [] }
        guard let firstAddr = ifaddr else { return [] }
        
        // For each interface ...
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee
        
            // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
            if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
        
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if (getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                        let address = String(cString: hostname)
                        addresses.append(address)
                    }
                }
            }
        }
        freeifaddrs(ifaddr)
        return addresses
    }
}
