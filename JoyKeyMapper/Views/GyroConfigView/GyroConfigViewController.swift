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
    
    var gyroConfig: GyroConfig?
    var dataManager: DataManager?
    
    @IBOutlet weak var CalibrateLabel: NSTextField!
    @IBOutlet weak var calibrateButton: NSButton!
    @IBOutlet weak var calibrateProgressIcon: NSProgressIndicator!
    
    @IBOutlet weak var DefaultSensitivitySlider: LabelledSlider!
    
    @IBOutlet weak var EnableAccelerationButton: NSButton!
    @IBOutlet weak var AccelerationSensitivitiesSlider: RangeSlider!
    @IBOutlet weak var AccelerationThresholdsSlider: RangeSlider!
    
    @IBOutlet weak var EnableSmoothingButton: NSButton!
    @IBOutlet weak var SmoothingThresholdSlider: LabelledSlider!
    
    @IBOutlet weak var EnableTighteningButton: NSButton!
    @IBOutlet weak var TighteningThresholdSlider: LabelledSlider!
    
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard self.gyroConfig != nil else { return }
        guard self.dataManager != nil else { return }
        setValues()
    }
    
    func setValues() {
        guard self.gyroConfig != nil else { return }
        DefaultSensitivitySlider.value = CGFloat(gyroConfig!.defaultSensitivity)
        EnableAccelerationButton.state = gyroConfig!.useAcceleration ? .on : .off
        AccelerationSensitivitiesSlider.lowerValue = CGFloat(gyroConfig!.slowAccSensitivity)
        AccelerationSensitivitiesSlider.upperValue = CGFloat(gyroConfig!.fastAccSensitivity)
        
        AccelerationThresholdsSlider.lowerValue = CGFloat(gyroConfig!.slowAccThreshold)
        AccelerationThresholdsSlider.upperValue = CGFloat(gyroConfig!.fastAccThreshold)
        
        EnableSmoothingButton.state = gyroConfig!.useSmoothing ? .on : .off
        SmoothingThresholdSlider.value = CGFloat(gyroConfig!.smoothThreshold)
        
        EnableTighteningButton.state = gyroConfig!.useTightening ? .on : .off
        TighteningThresholdSlider.value = CGFloat(gyroConfig!.tightenThreshold)
    }
    
    func saveValues() {
        guard self.gyroConfig != nil else { return }
        gyroConfig!.defaultSensitivity = Float(DefaultSensitivitySlider.value)
        gyroConfig!.useAcceleration = EnableAccelerationButton.state == .on
        gyroConfig!.slowAccSensitivity = Float(AccelerationSensitivitiesSlider.lowerValue)
        gyroConfig!.fastAccSensitivity = Float(AccelerationSensitivitiesSlider.upperValue)
        gyroConfig!.slowAccThreshold = Float(AccelerationThresholdsSlider.lowerValue)
        gyroConfig!.fastAccThreshold = Float(AccelerationThresholdsSlider.upperValue)
        gyroConfig!.useSmoothing = EnableSmoothingButton.state == .on
        gyroConfig!.smoothThreshold = Float(SmoothingThresholdSlider.value)
        gyroConfig!.useTightening = EnableTighteningButton.state == .on
        gyroConfig!.tightenThreshold = Float(TighteningThresholdSlider.value)
    }
    
    
    @IBAction func calibrateButtonPressed(_ sender: NSButton) {
    }

    @IBAction func resetToDefaultButtonPress(_ sender: NSButton) {
        for key in gyroConfig!.entity.attributesByName.keys {
            gyroConfig?.setValue(gyroConfig!.entity.attributesByName[key]?.defaultValue, forKey: key)
        }
        setValues()
    }
    
    @IBAction func okButtonPress(_ sender: NSButton) {
        saveValues()
        guard let window = self.view.window else { return }
        window.sheetParent?.endSheet(window, returnCode: .OK)
    }
    
}
