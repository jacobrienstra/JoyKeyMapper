//
//  RangeSlider.swift
//  JoyKeyMapper
//
//  Created by Jacob Rienstra on 8/15/20.
//

import Cocoa

@IBDesignable public class CustomKnob: NSView {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    public var fillColor: NSColor = NSColor.white

    
    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let path = NSBezierPath(ovalIn: dirtyRect.insetBy(dx: 1.0, dy: 1.0))
        let borderColor = NSColor(red: 177/255, green: 177/255, blue: 177/255, alpha: 1)
        fillColor.setFill()
        path.fill()
        path.lineWidth = 0.25
        borderColor.setStroke()
        path.stroke()
        
    }
    
}

class RangeSliderTrackLayer: CALayer {
    weak var rangeSlider: RangeSlider?
    
    override func draw(in ctx: CGContext) {
        guard let slider = rangeSlider else { return }
        let path = NSBezierPath(rect: bounds)
        ctx.addPath(path.cgPath)
        ctx.setFillColor(slider.trackColor.cgColor)
        ctx.fillPath()
        self.cornerRadius = 2.0
        self.masksToBounds = true
        
        ctx.setFillColor(slider.selectedColor.cgColor)
        let lowerValuePosition = slider.positionForValue(slider.lowerValue)
        let upperValuePosition = slider.positionForValue(slider.upperValue)
        let rect = CGRect(x: lowerValuePosition, y: 0, width: upperValuePosition - lowerValuePosition, height: bounds.height)
        ctx.fill(rect)
    }
}

public protocol RangeSliderDelegate {
    func controller(_ controller: RangeSlider , didChangeFirstValue: CGFloat , secondValue: CGFloat)
    // TODO: shold be an optional protocol.
    // func controller(_ controller: RangeSlider, willBeginChangeValues first:CGFloat, second:CGFloat)
}

extension CGFloat {
    var clean: String {
       return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", Float(self)) : String(Float(self))
    }
}

@IBDesignable public class RangeSlider: NSControl, CALayerDelegate {
    
    @IBInspectable public var knobColor: NSColor = NSColor.white {
        didSet {
            updateLayerFrames()
        }
    }

    @IBInspectable public var trackColor: NSColor = NSColor.disabledControlTextColor {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }
    @IBInspectable public var selectedColor: NSColor  = NSColor.controlAccentColor {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }
    @IBInspectable public var textColor: NSColor = NSColor.textColor {
        didSet {
            updateLayerFrames()
        }
    }
    
    @IBInspectable public var size = CGSize(width: 16.5, height: 16.5) {
        didSet {
            updateLayerFrames()
        }
    }

    @IBInspectable public var min: CGFloat = 0 {
        didSet {
            updateLayerFrames()
        }
    }
    @IBInspectable public var max: CGFloat = 100 {
        didSet {
            updateLayerFrames()
        }
    }
        
    @IBInspectable public var lowerValue: CGFloat = 25 {
        didSet {
            updateLayerFrames()
        }
    }
    
    @IBInspectable public var upperValue: CGFloat = 75 {
        didSet {
            updateLayerFrames()
        }
    }
    
    @IBInspectable public var step: CGFloat = 1.0 {
        didSet {
            updateLayerFrames()
        }
    }
    private var previousLocation = CGPoint()
    var delegate: RangeSliderDelegate?
    var shouldMoveFirst: Bool = false
    var shouldMoveLast: Bool = false
    private let baseLayer = CALayer()
    private let trackLayer = RangeSliderTrackLayer()
    private let lowerKnob = CustomKnob()
    private let upperKnob = CustomKnob()
    var firstLabel: NSTextField = NSTextField(frame: NSMakeRect(0, 0, 45, 20))
    var secondLabel: NSTextField = NSTextField(frame: NSMakeRect(0, 0, 45, 20))
    var textYOrigin: CGFloat = 0
    var trackYOrigin: CGFloat = 0
    var maxLineWidth: CGFloat {
        get {
            return self.bounds.width - size.width
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
    
    func commonInit() {
        self.wantsLayer = true
        self.canDrawSubviewsIntoLayer = true
        trackLayer.rangeSlider = self
        trackLayer.delegate = self
        trackLayer.needsDisplayOnBoundsChange = true
        trackLayer.cornerRadius = 2.0
        baseLayer.addSublayer(trackLayer)
        self.layer = baseLayer
        self.isEnabled = true
        self.isContinuous = true
        setUpLabels()
        addSubview(lowerKnob)
        addSubview(upperKnob)
        addSubview(firstLabel)
        addSubview(secondLabel)
        updateLayerFrames()
        
    }

    func setUpLabels() {
        firstLabel.isBordered = false
        firstLabel.isEditable = false
        firstLabel.isSelectable = false
        firstLabel.alignment = NSTextAlignment.center
        firstLabel.setContentHuggingPriority(.required, for: .horizontal)
        firstLabel.backgroundColor = .none
        firstLabel.textColor = textColor

        secondLabel.isBordered = false
        secondLabel.isEditable = false
        secondLabel.isSelectable = false
        secondLabel.alignment = NSTextAlignment.center
        secondLabel.setContentHuggingPriority(.required, for: .horizontal)
        secondLabel.backgroundColor = .none
        secondLabel.textColor = textColor
    }
    
    override public var frame: CGRect {
      didSet {
        updateLayerFrames()
      }
    }
    
    // 1
    private func updateLayerFrames() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        trackYOrigin = bounds.minY + size.height / 2 + 3.0 / 2 + 24
        trackLayer.frame = CGRect(x: bounds.origin.x, y: trackYOrigin, width: bounds.width, height: 3.0)
        baseLayer.setNeedsDisplay()
        trackLayer.setNeedsDisplay()
        lowerKnob.frame = CGRect(origin: thumbOriginForValue(lowerValue), size: size)
        upperKnob.frame = CGRect(origin: thumbOriginForValue(upperValue), size: size)
        upperKnob.fillColor = knobColor
        lowerKnob.fillColor = knobColor
        firstLabel.stringValue  = "\(lowerValue.clean)"
        secondLabel.stringValue = "\(upperValue.clean)"
        firstLabel.setFrameOrigin(NSMakePoint(lowerKnob.frame.midX - firstLabel.frame.width / 2, textYOrigin))
        secondLabel.setFrameOrigin(NSMakePoint(upperKnob.frame.midX - secondLabel.frame.width / 2, textYOrigin))

        CATransaction.commit()
    }
    
    // 2
    func positionForValue(_ value: CGFloat) -> CGFloat {
        return (((value - min) / (max - min)) * (maxLineWidth)) + (size.width / 2)
    }
    
    func valueForPosition(_ pos: CGFloat) -> CGFloat {
        return ((pos - (size.width / 2)) / maxLineWidth) * (max - min) + min
    }
    
    func getSteppedValue(_ value: CGFloat, rule: FloatingPointRoundingRule) -> CGFloat {
        return (((value - min) / step).rounded(rule) * step) + min
    }

    
    // 3
    private func thumbOriginForValue(_ value: CGFloat) -> CGPoint {
        let x = positionForValue(value) - size.width / 2.0
        return CGPoint(x: x, y: trackYOrigin + 3.0 / 2 - size.height / 2)
    }
    
    var trackingArea: NSTrackingArea!
    public override func updateTrackingAreas() {
        if trackingArea != nil {
            self.removeTrackingArea(trackingArea)
        }
        trackingArea = NSTrackingArea(rect: self.bounds, options: [NSTrackingArea.Options.enabledDuringMouseDrag , NSTrackingArea.Options.mouseMoved, NSTrackingArea.Options.activeAlways, .cursorUpdate], owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    
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
        previousLocation = loc

        if shouldMoveFirst {
//            let realMaxVal = valueForPosition(upperKnob.frame.minX - size.width / 2)
            lowerValue = boundValueStepped(valueForPosition(loc.x), toLowerValue: min, upperValue: upperValue)
        }
        if shouldMoveLast {
//            let realMinVal = valueForPosition(lowerKnob.frame.maxX + (size.width / 2))
            upperValue = boundValueStepped(valueForPosition(loc.x), toLowerValue: lowerValue, upperValue: max)
        }
        // 3
        sendAction(self.action ?? nil, to: self.target)
    }
    
    private func boundValue(_ value: CGFloat, toLowerValue lowerValue: CGFloat, upperValue: CGFloat) -> CGFloat {
        return Swift.min(Swift.max(value, lowerValue), upperValue)
    }
    
    // 4
    private func boundValueStepped(_ value: CGFloat, toLowerValue lowerValue: CGFloat, upperValue: CGFloat) -> CGFloat {
        var steppedValue = getSteppedValue(value, rule: .toNearestOrAwayFromZero)
        if (steppedValue < lowerValue) {
            steppedValue = getSteppedValue(lowerValue, rule: .up)
        }
        if (steppedValue > upperValue) {
            steppedValue = getSteppedValue(upperValue, rule: .down)
        }
        return steppedValue
    }
    
    // Mouse up event : We "deselect" both knobs.
    public override func mouseUp(with theEvent: NSEvent) {
        shouldMoveLast = false
        shouldMoveFirst = false
    }

}

