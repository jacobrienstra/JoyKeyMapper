//
//  DoubleSlider.swift
//  JoyKeyMapper
//
//  Created by Viorel Porumbescu on 18/10/15.
//  Copyright (c) 2015 Viorel Porumbescu. All rights reserved.
//

import Cocoa

protocol MBDoubleSliderDelegate {
    func controller(_ controller: DoubleSlider , didChangeFirstValue: CGFloat , secondValue: CGFloat)
    // TODO: shold be an optional protocol.
    // func controller(_ controller: MBDoubleSlider, willBeginChangeValues first:CGFloat, second:CGFloat)
}

@IBDesignable public class DoubleSlider: NSControl {
    
    @IBInspectable public var backgroundLineColor: NSColor = NSColor(red:0.780, green:0.780, blue:0.780, alpha:1)
    @IBInspectable public var selectionLineColor: NSColor  = NSColor(red:0.231, green:0.600, blue:0.988, alpha:1)
    @IBInspectable public var textColor: NSColor = NSColor.controlTextColor
    
    private var previousLocation = CGPoint()
    var delegate: MBDoubleSliderDelegate?

    // TODO: Add option to hide info labels
    
    public var minValue: CGFloat = 0
    @IBInspectable public var min: CGFloat = 0 {
        didSet {
            self.minValue = min
        }
    }
    public var maxValue: CGFloat = 1
    @IBInspectable public var max: CGFloat = 1 {
        didSet {
            self.maxValue = max
        }
    }
        
    public var lower: CGFloat = 0.2
    @IBInspectable public var lowerValue: CGFloat = 0.2 {
        didSet {
            self.lower = lowerValue
        }
    }
    
    public var upper: CGFloat = 0.8
    @IBInspectable public var upperValue: CGFloat = 0.8 {
        didSet {
            self.upper = upperValue
        }
    }
    
    private let baseLayer = CALayer()
    private let trackLayer = CALayer()
    private let lowerKnob = CustomKnob()
    private let upperKnob = CustomKnob()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()

    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        self.wantsLayer = true
        self.canDrawSubviewsIntoLayer = true
        trackLayer.backgroundColor = NSColor.blue.cgColor
        baseLayer.addSublayer(trackLayer)
        self.layer = baseLayer
        self.isEnabled = true
        self.isContinuous = true
        addSubview(lowerKnob)
        addSubview(upperKnob)
        updateLayerFrames()
        
    }
    
    override public var frame: CGRect {
      didSet {
        updateLayerFrames()
      }
    }
    
    // 1
    private func updateLayerFrames() {
        trackLayer.frame = CGRect(x: bounds.origin.x, y: bounds.midY - 1.5, width: bounds.width, height: 3.0)
        trackLayer.cornerRadius = 2.0
        baseLayer.setNeedsDisplay()
        lowerKnob.frame = CGRect(origin: thumbOriginForValue(lower), size: size)
        upperKnob.frame = CGRect(origin: thumbOriginForValue(upper), size: size)
    }
    
    let size = CGSize(width: 15.0, height: 15.0)
    // 2
    func positionForValue(_ value: CGFloat) -> CGFloat {
        return bounds.width * value
    }
    
    // 3
    private func thumbOriginForValue(_ value: CGFloat) -> CGPoint {
        let x = positionForValue(value) - size.width / 2.0
        return CGPoint(x: x, y: (bounds.height - size.height) / 2.0)
    }
    
    var trackingArea: NSTrackingArea!
    public override func updateTrackingAreas() {
        if trackingArea != nil {
            self.removeTrackingArea(trackingArea)
        }
        trackingArea = NSTrackingArea(rect: self.bounds, options: [NSTrackingArea.Options.enabledDuringMouseDrag , NSTrackingArea.Options.mouseMoved, NSTrackingArea.Options.activeAlways, .cursorUpdate], owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
//    
    var shouldMoveFirst: Bool = false
    var shouldMoveLast: Bool = false

    
    /// Mouse down event : We test if current mouse location is inside of first or second knob. If yes, then we
    public override func mouseDown(with theEvent: NSEvent) {
        let loc = self.convert(theEvent.locationInWindow, from: self.window?.contentView)
        previousLocation = loc
        if NSPointInRect(loc, lowerKnob.frame) {
            shouldMoveFirst = true
        }
        if NSPointInRect(loc, upperKnob.frame) {
            shouldMoveLast = true
        }
    }

    // Mouse dragged Event : if is any selected knob we will move to new position, and we calculate
    // new the new slider values
    public override func mouseDragged(with theEvent: NSEvent) {
        let loc = self.convert(theEvent.locationInWindow, from: self.window?.contentView)
        // 1
        let deltaLocation = loc.x - previousLocation.x
        let deltaValue = (max - min) * deltaLocation / bounds.width
        previousLocation = loc

        if shouldMoveFirst {
            lower += deltaValue
            lower = boundValue(lower, toLowerValue: min, upperValue: upper)
        }
        if shouldMoveLast {
            upper += deltaValue
            upper = boundValue(upper, toLowerValue: lower,
                                       upperValue: max)
        }
        // 3
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        updateLayerFrames()
        CATransaction.commit()
        self.needsDisplay = true
        sendAction(self.action!, to: self.target)
    }
    
    // 4
    private func boundValue(_ value: CGFloat, toLowerValue lowerValue: CGFloat, upperValue: CGFloat) -> CGFloat {
        return Swift.min(Swift.max(value, lowerValue), upperValue)
    }
    
    // Mouse up event : We "deselect" both knobs.
    public override func mouseUp(with theEvent: NSEvent) {
        shouldMoveLast  = false
        shouldMoveFirst = false
    }
    
    /// If has a delegate we will send changed notification, and new values for slider.
    /// Also we trigger action if this control has one.
//    func create() {
//        if self.action != nil {
//            NSApp.sendAction(self.action!, to: self.target, from: self)
//        }
//
//        if let delegate = self.delegate {
//            delegate.controller(self, didChangeFirstValue: lower, secondValue: upper)
//        }
//    }
    
    
//    var minimValue: CGFloat = 10
//    var delegate: DoubleSliderDelegate?
//
//    var firstKnob: CustomKnob = CustomKnob()
//    var secondKnob: CustomKnob = CustomKnob()
//    var firstLabel: NSTextField = NSTextField(frame: NSMakeRect(0, -2, 30, 20))
//    var secondLabel: NSTextField = NSTextField(frame: NSMakeRect(0, -2, 30, 20))
//    var yOrigin: CGFloat = 0
//    var lineMaxWidth: CGFloat = 0

//
//    override init(frame frameRect: NSRect) {
//        super.init(frame: frameRect)
//        commonInit()
//    }
//
//
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        commonInit()
//    }
//
//    func commonInit() {
//        self.wantsLayer = true
//        self.addSubview(firstKnob)
//        self.addSubview(secondKnob)
//        self.addSubview(firstLabel)
//        self.addSubview(secondLabel)
//        setUpLabels()
//        initViews()
//
//    }
//
//    override func draw(_ dirtyRect: NSRect) {
//        super.draw(dirtyRect)
//        setUpLabels()
//        initViews()
//    }
//
//    func initViews() {
//        let textOrigin: CGFloat = 0
//        let knobSize = self.frame.height * 0.4
//        lineMaxWidth = self.frame.width - knobSize
//        yOrigin = self.frame.height * 0.6
//        let firstX = (firstValue * lineMaxWidth) /  maxValue
//        let secondX = (secondValue * lineMaxWidth) / maxValue
//        firstKnob.setFrameSize(NSMakeSize(knobSize, knobSize))
//        secondKnob.setFrameSize(NSMakeSize(knobSize, knobSize))
//        firstKnob.setFrameOrigin(NSMakePoint(firstX, yOrigin))
//        secondKnob.setFrameOrigin(NSMakePoint(secondX, yOrigin))
//        firstLabel.setFrameOrigin(NSMakePoint(firstX, textOrigin))
//        secondLabel.setFrameOrigin(NSMakePoint(secondX, textOrigin))
//
//        firstLabel.textColor = textColor
//        secondLabel.textColor = textColor
//
//        // Center text Label if is posible
//        if firstX > 8 {
//            firstLabel.setFrameOrigin(NSMakePoint(firstX - 8, textOrigin))
//        }
//        if secondX < lineMaxWidth - 8 {
//            secondLabel.setFrameOrigin(NSMakePoint(secondX - 8, textOrigin))
//        }
//
//        if secondX > lineMaxWidth - 8 {
//            secondLabel.setFrameOrigin(NSMakePoint(lineMaxWidth - 16, textOrigin))
//        }
//        if (firstLabel.frame.origin.x + NSWidth(firstLabel.frame) ) > secondLabel.frame.origin.x {
//            let size  = (secondLabel.frame.origin.x  - (firstLabel.frame.origin.x + NSWidth(firstLabel.frame) )) / 2
//            var state = true
//            if firstX < 8 {
//                state = false
//                secondLabel.setFrameOrigin(NSMakePoint(secondLabel.frame.origin.x - size - size, textOrigin))
//            }
//            if secondX > lineMaxWidth - 8 {
//                state = false
//                firstLabel.setFrameOrigin(NSMakePoint(firstLabel.frame.origin.x + size + size, textOrigin))
//            }
//            if state {
//                firstLabel.setFrameOrigin(NSMakePoint(firstLabel.frame.origin.x + size, textOrigin))
//                secondLabel.setFrameOrigin(NSMakePoint(secondLabel.frame.origin.x - size, textOrigin))
//            }
//        }
//        firstLabel.stringValue  = "\(firstValue)"
//        secondLabel.stringValue = "\(secondValue)"
//        // Draw  background line
//        let backgroundLine = NSBezierPath()
//        backgroundLine.move(to: NSMakePoint(knobSize * 0.5,  self.frame.height * 0.8))
//        backgroundLine.line(to: NSMakePoint(lineMaxWidth + knobSize * 0.5 ,  self.frame.height * 0.8))
//        backgroundLine.lineCapStyle = NSBezierPath.LineCapStyle.round
//        backgroundLine.lineWidth = 3
//        backgroundLineColor.set()
//        backgroundLine.stroke()
//        // Draw selection  line (the line between knobs)
//        let selectionLine = NSBezierPath()
//        selectionLine.move(to: NSMakePoint(firstX + knobSize / 2 , self.frame.height * 0.8))
//        selectionLine.line(to: NSMakePoint(secondX + knobSize / 2 , self.frame.height * 0.8))
//        selectionLine.lineCapStyle = NSBezierPath.LineCapStyle.round
//        selectionLine.lineWidth = 3
//        selectionLineColor.setStroke()
//        selectionLine.stroke()
//
//    }
//
//
//    func setUpLabels() {
//        firstLabel.isBordered       = false
//        firstLabel.identifier       = NSUserInterfaceItemIdentifier(rawValue: "10")
//        firstLabel.isEditable       = false
//        firstLabel.isSelectable     = false
//        firstLabel.stringValue      = "0"
//        firstLabel.backgroundColor  = NSColor.white.withAlphaComponent(0)
//        firstLabel.font             = NSFont(name: "HelveticaNeue", size: 10)
//        firstLabel.textColor        = NSColor.gray
//        firstLabel.alignment        = NSTextAlignment.left
//
//        secondLabel.isBordered      = false
//        secondLabel.identifier      = NSUserInterfaceItemIdentifier(rawValue: "10")
//        secondLabel.isEditable      = false
//        secondLabel.isSelectable    = false
//        secondLabel.stringValue     = "0"
//        secondLabel.backgroundColor = NSColor.white.withAlphaComponent(0)
//        secondLabel.font            = NSFont(name: "HelveticaNeue", size: 10)
//        secondLabel.textColor       = NSColor.gray
//        secondLabel.alignment       = NSTextAlignment.left
//
//    }
    

    
}

