//
//  GyroConfigViewController.swift
//  JoyKeyMapper
//
//  Created by Jacob Rienstra on 8/16/20.
//  Copyright © 2020 DarkHorse. All rights reserved.
//

import Cocoa
import RangeSlider

class GyroConfigViewController: NSViewController {
    
    var gyroConfig: GyroConfig!
    
    @IBOutlet weak var calibrateButton: NSButton!
    @IBOutlet weak var calibrateProgressIcon: NSProgressIndicator!
    @IBOutlet weak var enableAccelerationButton: NSButton!
    @IBOutlet weak var enableSmoothButton: NSButton!
    @IBOutlet weak var enableTightenButton: NSButton!
    @IBAction func AccThresholdSliderChanged(_ sender: RangeSlider) {
        print(sender.lowerValue)
        print(sender.upperValue)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let gyroConfig = self.gyroConfig else { return }

        
        // Do view setup here.
    }
    
    
    @IBAction func calibrateButtonPressed(_ sender: NSButton) {
    }
    
    @IBAction func defaultSensitivityChanged(_ sender: NSSliderCell) {
    }
   
    @IBAction func enableAccelerationToggle(_ sender: NSButton) {
    }
    
    @IBAction func slowAccThresholdChanged(_ sender: NSSlider) {
    }
    
    @IBAction func fastAccThresholdChanged(_ sender: NSSlider) {
    }
   
    @IBAction func slowAccSensitivityChanged(_ sender: NSSlider) {
    }
   
    @IBAction func fastAccSensitivityChanged(_ sender: NSSlider) {
    }
  
    @IBAction func enableSmoothingTogle(_ sender: NSButton) {
    }
    @IBAction func smoothThresholdChanged(_ sender: NSSlider) {
    }
    
    @IBAction func enableTighteningToggle(_ sender: NSButton) {
    }
    @IBAction func tightenThresholdChanged(_ sender: NSSlider) {
    }
   
    @IBAction func resetToDefaultButtonPress(_ sender: NSButton) {
    }
    
    @IBAction func okButtonPress(_ sender: NSButton) {
        guard let window = self.view.window else { return }
        window.sheetParent?.endSheet(window, returnCode: .OK)
    }
    
}
