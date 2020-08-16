//
//  GyroConfigViewController.swift
//  JoyKeyMapper
//
//  Created by Jacob Rienstra on 8/16/20.
//  Copyright © 2020 DarkHorse. All rights reserved.
//

import Cocoa

class GyroConfigViewController: NSViewController {

    
    @IBOutlet weak var calibrateButton: NSButton!
    @IBOutlet weak var calibrateProgressIcon: NSProgressIndicator!
    @IBOutlet weak var defaultSensitivityLabel: NSTextField!
    @IBOutlet weak var slowAccThresholdLabel: NSTextField!
    @IBOutlet weak var fastAccThresholdLabel: NSTextField!
    @IBOutlet weak var slowAccSensitivityLabel: NSTextField!
    @IBOutlet weak var fastAccSensitivityLabel: NSTextField!
    @IBOutlet weak var smoothThresholdLabel: NSTextField!
    @IBOutlet weak var tightenThresholdLabel: NSTextField!
    
    
    
    
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
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Do view setup here.
    }
    
}
