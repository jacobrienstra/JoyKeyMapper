//
//  GyroConfigViewController.swift
//  JoyKeyMapper
//
//  Created by Jacob Rienstra on 8/16/20.
//  Copyright © 2020 DarkHorse. All rights reserved.
//

import Cocoa
import RangeSlider
import SceneKit

enum CalibrationState: String {
    case Ready = "Ready"
    case Calibrating = "Calibrating"
    case Done = "Done"
}

class GyroConfigViewController: NSViewController {
    
    var gyroConfig: GyroConfig?
    var dataManager: DataManager?
    var calibrationState: CalibrationState = .Done {
        didSet {
            switch(calibrationState) {
                case .Ready:
                    gyroConfig?.calibration?.isCalibrating = false
                    CalibrateLabel.stringValue = "Place your Joy Con on a flat surface, and then press the calibrate button again to begin calibrating"
                    calibrateButton.title = "Begin Calibration"
                    calibrateProgressIcon.stopAnimation(self)
                    break
                case .Calibrating:
                    gyroConfig?.calibration?.isCalibrating = true
                    CalibrateLabel.stringValue = "Calibrating..."
                    calibrateButton.title = "Calibrating..."
                    calibrateProgressIcon.startAnimation(self)
                    calibrate()
                    break
                case .Done:
                    gyroConfig?.calibration?.isCalibrating = false
                    calibrateButton.title = "Calibrate"
                    CalibrateLabel.stringValue = "Done calibrating!"
                    calibrateProgressIcon.stopAnimation(self)
                    break
            }
        }
    }
    
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
        self.gyroConfig?.calibration?.isCalibrating = false
        calibrateButton.stringValue = ""
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
    
    func calibrate() {
        var avgValues = [SCNVector3](repeating: SCNVector3(0,0,0), count: 10)
        
        let totalDifferenceIsUnder: ([SCNVector3], CGFloat) -> Bool = { values, minDiff in
            if (values.first?.x != 0 && values.first?.y != 0 && values.first?.z != 0) {
                var minVals = values.first ?? SCNVector3(0,0,0)
                var maxVals = values.first ?? SCNVector3(0,0,0)
                for value in values.dropFirst() {
                    minVals.x = min(minVals.x, value.x)
                    minVals.y = min(minVals.y, value.y)
                    minVals.z = min(minVals.z, value.z)
                    maxVals.x = max(maxVals.x, value.x)
                    maxVals.y = max(maxVals.y, value.y)
                    maxVals.z = max(maxVals.z, value.z)
                }
                let diffs = SCNVector3(maxVals.x - minVals.x, maxVals.y - minVals.y, maxVals.z - minVals.z)
                print("DIFF: (\(diffs.x), \(diffs.y), \(diffs.z))")
                return abs(diffs.x) < minDiff && abs(diffs.y) < minDiff && abs(diffs.z) < minDiff
            }
            return false
        }
        
        var i = 0
        
        DispatchQueue.init(label: "calibration", qos: .background, attributes: [.concurrent], autoreleaseFrequency: .inherit, target: nil).async {
            repeat {
                let newVal = self.gyroConfig?.calibration?.getAverage()
                avgValues[i] = newVal ?? SCNVector3(0,0,0)
                usleep(500000)
                i = (i + 1) % 10
            } while (!totalDifferenceIsUnder(avgValues, 0.001))
            DispatchQueue.main.async {
                self.calibrationState = .Done
            }
        }
    }
    
    
    @IBAction func calibrateButtonPressed(_ sender: NSButton) {
        if calibrationState == .Done {
            calibrationState = .Ready
        } else if calibrationState == .Ready {
            calibrationState = .Calibrating
        } else if calibrationState == .Calibrating {
            calibrationState = .Done
        }
    }

    @IBAction func ResetCalibrationButtonPressed(_ sender: NSButton) {
        gyroConfig?.calibration?.resetContCalibration()
    }
    
    @IBAction func resetToDefaultButtonPress(_ sender: NSButton) {
        for key in gyroConfig!.entity.attributesByName.keys {
            if key != "calibration" && key != "enabled" {
                gyroConfig?.setValue(gyroConfig!.entity.attributesByName[key]?.defaultValue, forKey: key)
            }
        }
        setValues()
    }
    
    @IBAction func okButtonPress(_ sender: NSButton) {
        saveValues()
        guard let window = self.view.window else { return }
        window.sheetParent?.endSheet(window, returnCode: .OK)
    }
    
}
