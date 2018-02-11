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

class ViewController: UIViewController {
    
    let synth = AVSpeechSynthesizer()
    var myUtterance = AVSpeechUtterance(string: "")
    
    var operationDictionary : [String : String] = ["battery":"0","other":"0"]
    


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func Battery(_ sender: UIButton) {
        
        var batteryL: Float {
            return UIDevice.current.batteryLevel
        }
        print("bottone premuto")
        UIDevice.current.isBatteryMonitoringEnabled = true
        var batteryLevel : Int
        batteryLevel = Int(batteryL * 100)
        var toSpeech : String
        toSpeech = String(batteryLevel)
//        echoTest()
        echoText(infoText : toSpeech)
    }
    
    func echoText(infoText : String){
        let ws = WebSocket("ws://192.168.1.11:4040/websocketserver")
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
}
