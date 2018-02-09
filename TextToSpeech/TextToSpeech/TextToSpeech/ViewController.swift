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
        myUtterance.rate = 0.3
        synth.speak(myUtterance)
    }
    @IBAction func batterySpeech(_ sender: UIButton) {
        var batteryLevel: Float {
            return UIDevice.current.batteryLevel
        }
        var toSpeech = "Ciao"
        myUtterance = AVSpeechUtterance( string: toSpeech)
        myUtterance.rate = 0.3
        synth.speak(myUtterance)
    }
    
}


