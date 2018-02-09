//
//  ViewController.swift
//  TextToSpeech
//
//  Created by Luigi Secondo on 09/02/2018.
//  Copyright © 2018 Luigi Secondo. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    
    @IBOutlet weak var textView: UITextView!
    
    let synth = AVSpeechSynthesizer()
    var myUtterance = AVSpeechUtterance(string: "")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func textToSpeech(_ sender: UIButton) {
        myUtterance = AVSpeechUtterance(string: textView.text)
        myUtterance.rate = 0.5
        synth.speak(myUtterance)
    }
    
    // Speeches battery level of the device
    @IBAction func batterySpeech(_ sender: UIButton) {
        var batteryL: Float {
            return UIDevice.current.batteryLevel
        }
        UIDevice.current.isBatteryMonitoringEnabled = true
        var batteryLevel : Int
        batteryLevel = Int(batteryL * 100)
        let toSpeech = "My battery level is \(batteryLevel) per cent"
        myUtterance = AVSpeechUtterance( string: "\(toSpeech)")
        myUtterance.rate = 0.5
        synth.speak(myUtterance)
    }
    
    // Speeches the ip adress
    @IBAction func ipSpeech(_ sender: UIButton) {
        var ipAdress : [String]
        ipAdress = getIFAddresses()
        var toSpeech : String
        toSpeech = "My ip adress is \(ipAdress[0])"
        myUtterance = AVSpeechUtterance( string: toSpeech)
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
