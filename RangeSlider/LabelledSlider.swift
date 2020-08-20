//
//  LabelledSlider.swift
//  JoyKeyMapper
//
//  Created by Jacob Rienstra on 8/19/20.
//  Copyright © 2020 DarkHorse. All rights reserved.
//

import Cocoa

@IBDesignable public class LabelledSlider: NSControl {
    
    private var slider = NSSlider()
    private var label =  NSTextField(frame: NSMakeRect(0, 0, 30, 20))
    private let baseLayer = CALayer()
    
    @IBInspectable public var min: CGFloat = 0 {
        didSet {
            slider.minValue = Double(min)
            updateLayerFrames()
        }
    }
    @IBInspectable public var max: CGFloat = 100 {
        didSet {
            slider.maxValue = Double(max)
            updateLayerFrames()
        }
    }
    
    @IBInspectable public var value: CGFloat = 50 {
        didSet {
            self.label.stringValue = "\(steppedValue.clean)"
            slider.floatValue = Float(steppedValue)
            updateLayerFrames()
        }
    }
    
    public var steppedValue: CGFloat {
        get {
            getSteppedValue(self.value, rule: .toNearestOrAwayFromZero)
        }
    }

    @IBInspectable public var step: CGFloat = 1 {
        didSet {
            slider.altIncrementValue = Double(step)
            updateLayerFrames()
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    @objc func didSliderChange(_ sender: NSSlider) {
        self.value = CGFloat(sender.floatValue)
        self.sendAction(self.action, to: self.target)
    }
    
    func getSteppedValue(_ value: CGFloat, rule: FloatingPointRoundingRule) -> CGFloat {
        let val = (((value - min) / step).rounded(rule) * step) + min
        // small chance the max isn't an even # of steps from min and will round past when close
        return val > max ? max : val
    }
    
    func commonInit() {
        self.wantsLayer = true
        self.canDrawSubviewsIntoLayer = true
        self.layer = baseLayer
        self.isEnabled = true
        self.isContinuous = true
        label.isBordered = false
        label.isEditable = false
        label.isSelectable = false
        label.alignment = NSTextAlignment.center
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.backgroundColor = .none
        label.textColor = NSColor.textColor
        label.stringValue = "\(steppedValue.clean)"
        slider.target = self
        slider.action = #selector(self.didSliderChange(_:))
        slider.minValue = Double(min)
        slider.maxValue = Double(max)
        slider.floatValue = Float(steppedValue)
        label.target = self
        addSubview(slider)
        addSubview(label)
        updateLayerFrames()
    }
    
    private func updateLayerFrames() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        slider.frame = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: bounds.width - 30, height: bounds.height)
        label.setFrameOrigin(CGPoint(x: bounds.maxX - 30, y: bounds.midY - 10))
        baseLayer.setNeedsDisplay()
        CATransaction.commit()
    }
    
}
