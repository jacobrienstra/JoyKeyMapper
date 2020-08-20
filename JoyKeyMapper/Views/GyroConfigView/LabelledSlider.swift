//
//  LabelledSlider.swift
//  JoyKeyMapper
//
//  Created by Jacob Rienstra on 8/19/20.
//  Copyright © 2020 DarkHorse. All rights reserved.
//

import Cocoa

class LabelledSlider: NSControl {
    
    private var slider = NSSlider()
    private var label =  NSTextField(frame: NSMakeRect(0, -2, 30, 20))
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func didSliderChange(_ sender: NSSlider) {
        self.label.stringValue = "\(sender.floatValue)"
    }
    
    func commonInit() {
        self.wantsLayer = true
        self.canDrawSubviewsIntoLayer = true
        slider.target = self
        label.target = self
        addSubview(slider)
        addSubview(label)
    }
    
}
