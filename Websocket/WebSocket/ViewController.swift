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
    var name: String
}
let ws = WebSocket("ws://130.251.13.162:8080/websocketserver")

class ViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: Properties
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var userNameLabel: UILabel!
    
    
    
    let synth = AVSpeechSynthesizer()
    var myUtterance = AVSpeechUtterance(string: "")
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        nameTextField.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        userNameLabel.text = textField.text
    }
    
    //MARK: actions
    @IBAction func setDefaultName(_ sender: UIButton) {
        userNameLabel.text = "Emaro student"
        nameTextField.text = ""
    }
    
    @IBAction func Battery(_ sender: UIButton) {
        var batteryL: Float {
            return UIDevice.current.batteryLevel
        }
        UIDevice.current.isBatteryMonitoringEnabled = true
        var batteryLevel : Int
        batteryLevel = Int(batteryL * 100)
//        var toSpeech : String
        let toSpeech = DoubleMessage(typeID: "battery", value: String(batteryLevel), name: userNameLabel.text!)
        let jsonEncoder = JSONEncoder()
        let jsonData = try? jsonEncoder.encode(toSpeech)
        let jsonString = String(data: jsonData!, encoding: .utf8)
        echoText(infoText : jsonString!)
    }
    
    @IBAction func ipAdress(_ sender: UIButton) {
        var ipAdress : [String]
        ipAdress = getIFAddresses()
        let toSpeech = DoubleMessage(typeID: "ipAddress", value: ipAdress[2], name: userNameLabel.text!)
        let jsonEncoder = JSONEncoder()
        let jsonData = try? jsonEncoder.encode(toSpeech)
        let jsonString = String(data: jsonData!, encoding: .utf8)
        echoText(infoText : jsonString!)
    }
    
    func echoText(infoText : String){
        
        let send : ()->() = {
            ws.send(infoText)
        }
        ws.event.open = {
            print("opened")
            send()
        }
        ws.event.close = { code, reason, clean in
            print("close")
        }
        ws.event.error = { error in
            print("error \(error)")
        }
        ws.event.message = { message in
            let text = message
            print("recv: \(text)")
            self.speechFunc(speech: String(describing: message))
            }
        }

    func speechFunc(speech : String){
        myUtterance = AVSpeechUtterance( string: speech)
        myUtterance.rate = 0.5
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
