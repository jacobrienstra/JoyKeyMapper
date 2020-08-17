//
//  GyroConfigViewController.swift
//  JoyKeyMapper
//
//  Created by Jacob Rienstra on 8/16/20.
//  Copyright © 2020 DarkHorse. All rights reserved.
//

import Cocoa

class GyroConfigViewController: NSViewController {
    
    var gyroConfig: GyroConfig!
    
    @IBOutlet weak var calibrateButton: NSButton!
    @IBOutlet weak var calibrateProgressIcon: NSProgressIndicator!
    @IBOutlet weak var defaultSensitivitySlider: NSSlider!
    @IBOutlet weak var defaultSensitivityLabel: NSTextField!
    @IBOutlet weak var enableAccelerationButton: NSButton!
    @IBOutlet weak var slowAccThresholdSlider: NSSliderCell!
    @IBOutlet weak var slowAccThresholdLabel: NSTextField!
    @IBOutlet weak var fastAccThresholdSlider: NSSlider!
    @IBOutlet weak var fastAccThresholdLabel: NSTextField!
    @IBOutlet weak var slowAccSensitivitySlider: NSSlider!
    @IBOutlet weak var slowAccSensitivityLabel: NSTextField!
    @IBOutlet weak var fastAccSensitivitySlider: NSSlider!
    @IBOutlet weak var fastAccSensitivityLabel: NSTextField!
    @IBOutlet weak var enableSmoothButton: NSButton!
    @IBOutlet weak var smoothThresholdSlider: NSSlider!
    @IBOutlet weak var smoothThresholdLabel: NSTextField!
    @IBOutlet weak var enableTightenButton: NSButton!
    @IBOutlet weak var tightenThresholdSlider: NSSlider!
    @IBOutlet weak var tightenThresholdLabel: NSTextField!
    
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
