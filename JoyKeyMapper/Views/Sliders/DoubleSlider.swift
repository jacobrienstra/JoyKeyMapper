//
//  DoubleSlider.swift
//  JoyKeyMapper
//
//  Created by Viorel Porumbescu on 18/10/15.
//  Copyright (c) 2015 Viorel Porumbescu. All rights reserved.
//

import Cocoa

protocol DoubleSliderDelegate {
    func controller(_ controller: DoubleSlider , didChangeFirstValue: CGFloat, secondValue: CGFloat)
    // TODO: shold be an optional protocol.
    // func controller(_ controller: DoubleSlider, willBeginChangeValues first:CGFloat, second:CGFloat)
}

@IBDesignable
public class DoubleSlider: NSControl {

    @IBOutlet var DoubleSliderBaseView: DoubleSlider!
    
    @IBInspectable var backgroundLineColor: NSColor = NSColor(red:0.780, green:0.780, blue:0.780, alpha:1)
    @IBInspectable var selectionLineColor: NSColor  = NSColor(red:0.231, green:0.600, blue:0.988, alpha:1)
    @IBInspectable var textColor:NSColor = NSColor.gray {
        didSet {
            initViews()
        }
    }
    // TODO: Add option to hide info labels
    
    var minValue: CGFloat = 0
    var maxValue: CGFloat = 100
    
    var firstValue: CGFloat = 0 {
        didSet {
            if firstValue < minValue || firstValue  > secondValue {
                firstValue  = minValue
                
            }
            self.needsDisplay = true
        }
    }
    
    var secondValue: CGFloat = 100 {
        didSet {
            if secondValue < firstValue || secondValue > maxValue {
                secondValue = maxValue
            }
            self.needsDisplay = true
        }
    }
    
    var minimValue: CGFloat = 10
    
    var delegate: DoubleSliderDelegate?
    
    // Custom Private Vars
    fileprivate var firstKnob:CustomKnob = CustomKnob()
    fileprivate var secondKnob:CustomKnob = CustomKnob()
    fileprivate var firstLabel:NSTextField = NSTextField(frame: NSMakeRect(0, -2, 30, 20))
    fileprivate var secondLabel:NSTextField = NSTextField(frame: NSMakeRect(0, -2, 30, 20))
    fileprivate var yOrigin:CGFloat = 0
    fileprivate var lineMaxWidh: CGFloat = 0
    fileprivate var shouldMoveFirst:Bool = false
    fileprivate var shouldMoveLast: Bool = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }
    
    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        initViews()
    }
    
    var trackingArea:NSTrackingArea!
    public override func updateTrackingAreas() {
        if trackingArea != nil {
            self.removeTrackingArea(trackingArea)
        }
        trackingArea = NSTrackingArea(rect: self.bounds, options: [NSTrackingArea.Options.enabledDuringMouseDrag , NSTrackingArea.Options.mouseMoved, NSTrackingArea.Options.activeAlways, .cursorUpdate], owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    /// Mouse down event : We test if current mouse location is inside of first or second knob. If yes, then we
    // tell that selected knob that it can be moved
    public override func mouseDown(with theEvent: NSEvent) {
        let loc = self.convert(theEvent.locationInWindow, from: self.window?.contentView)
        
        if NSPointInRect(loc, firstKnob.frame) {
            shouldMoveFirst = true
        }
        if NSPointInRect(loc, secondKnob.frame) {
            shouldMoveLast = true
        }
    }
    
    // Mouse dragged Event : if is any selected knob we will move to new position, and we calculate
    // new the new slider values
    public override func mouseDragged(with theEvent: NSEvent) {
        let loc = self.convert(theEvent.locationInWindow, from: self.window?.contentView)
        
        let _ = self.convert(theEvent.locationInWindow, to: self)
        
        if shouldMoveFirst {
            let minim = CGFloat(0)
            let maxim   = secondKnob.frame.origin.x - firstKnob.frame.width - ((lineMaxWidh /  maxValue)  * minimValue )
            if loc.x > minim && loc.x < maxim {
                firstValue = (loc.x * maxValue) / lineMaxWidh
                if loc.x < minim {
                    firstValue = (minim * maxValue) / lineMaxWidh
                }
                if loc.x > maxim {
                    firstValue = (maxim * maxValue) / lineMaxWidh
                }
            }else if loc.x < minim {
                firstValue = (minim * maxValue) / lineMaxWidh
            }
            self.needsDisplay = true
            create()
        }
        if shouldMoveLast {
            let minim = firstKnob.frame.origin.x + secondKnob.frame.width + ((lineMaxWidh /  maxValue)  * minimValue )
            let maxim   = lineMaxWidh
            if loc.x > minim && loc.x < maxim {
                secondValue = (loc.x * maxValue) / lineMaxWidh
                if loc.x < minim {
                    secondValue = (minim * maxValue) / lineMaxWidh
                }
                if loc.x > maxim {
                    secondValue = (maxim * maxValue) / lineMaxWidh
                }
            } else if loc.x > maxim  {
                secondValue = (maxim * maxValue) / lineMaxWidh
            }
            self.needsDisplay = true
            create()
        }
    }
    
    //Mouse up event : We "deselect" both knobs.
    public override func mouseUp(with theEvent: NSEvent) {
        shouldMoveLast  = false
        shouldMoveFirst = false
    }
    
    func initViews() {
        let textOrigin: CGFloat = 0
        let knobSize = self.frame.height * 0.4
        lineMaxWidh = self.frame.width - knobSize
        yOrigin = self.frame.height * 0.6
        let firstX = (firstValue * lineMaxWidh) /  maxValue
        let secondX = (secondValue * lineMaxWidh) / maxValue
        firstKnob.setFrameSize(NSMakeSize(knobSize, knobSize))
        secondKnob.setFrameSize(NSMakeSize(knobSize, knobSize))
        firstKnob.setFrameOrigin(NSMakePoint(firstX, yOrigin))
        secondKnob.setFrameOrigin(NSMakePoint(secondX, yOrigin))
        firstLabel.setFrameOrigin(NSMakePoint(firstX, textOrigin))
        secondLabel.setFrameOrigin(NSMakePoint(secondX, textOrigin))
        
        firstLabel.textColor = textColor
        secondLabel.textColor = textColor
        
        // Center text Label if is posible
        if firstX > 8 {
            firstLabel.setFrameOrigin(NSMakePoint(firstX - 8, textOrigin))
        }
        if secondX < lineMaxWidh - 8 {
            secondLabel.setFrameOrigin(NSMakePoint(secondX - 8, textOrigin))
        }
        
        if secondX > lineMaxWidh - 8 {
            secondLabel.setFrameOrigin(NSMakePoint(lineMaxWidh - 16, textOrigin))
        }
        if (firstLabel.frame.origin.x + NSWidth(firstLabel.frame) ) > secondLabel.frame.origin.x {
            let size  = (secondLabel.frame.origin.x  - (firstLabel.frame.origin.x + NSWidth(firstLabel.frame) )) / 2
            var state = true
            if firstX < 8 {
                state = false
                secondLabel.setFrameOrigin(NSMakePoint(secondLabel.frame.origin.x - size - size, textOrigin))
            }
            if secondX > lineMaxWidh - 8 {
                state = false
                firstLabel.setFrameOrigin(NSMakePoint(firstLabel.frame.origin.x + size + size, textOrigin))
            }
            if state {
                firstLabel.setFrameOrigin(NSMakePoint(firstLabel.frame.origin.x + size, textOrigin))
                secondLabel.setFrameOrigin(NSMakePoint(secondLabel.frame.origin.x - size, textOrigin))
            }
        }
        firstLabel.stringValue  = secondsToMinute(firstValue)
        secondLabel.stringValue = secondsToMinute(secondValue)
        // Draw  background line
        let backgroundLine = NSBezierPath()
        backgroundLine.move(to: NSMakePoint(knobSize * 0.5,  self.frame.height * 0.8))
        backgroundLine.line(to: NSMakePoint(lineMaxWidh + knobSize * 0.5 ,  self.frame.height * 0.8))
        backgroundLine.lineCapStyle = NSBezierPath.LineCapStyle.round
        backgroundLine.lineWidth = 3
        backgroundLineColor.set()
        backgroundLine.stroke()
        ///Draw selection  line (the line between knobs)
        let selectionLine = NSBezierPath()
        selectionLine.move(to: NSMakePoint(firstX + knobSize / 2 , self.frame.height * 0.8))
        selectionLine.line(to: NSMakePoint(secondX + knobSize / 2 , self.frame.height * 0.8))
        selectionLine.lineCapStyle = NSBezierPath.LineCapStyle.round
        selectionLine.lineWidth = 3
        selectionLineColor.setStroke()
        selectionLine.stroke()
        
//        Swift.print(self.subviews.count)
        self.addSubview(firstKnob)
        self.addSubview(secondKnob)
        self.addSubview(firstLabel)
        self.addSubview(secondLabel)
    }
    
    
    func setUp() {
        let myName = type(of: self).className().components(separatedBy: ".").last!
        let newNib = NSNib(nibNamed: myName, bundle: Bundle(for: type(of: self)))
        newNib?.instantiate(withOwner: self, topLevelObjects: nil)
        
        var newConstraints: [NSLayoutConstraint] = []
        for oldConstraint in DoubleSliderBaseView.constraints {
            let firstItem = oldConstraint.firstItem === DoubleSliderBaseView ? self : oldConstraint.firstItem!
            let secondItem = oldConstraint.secondItem === DoubleSliderBaseView ? self : oldConstraint.secondItem
            newConstraints.append(NSLayoutConstraint(item: firstItem, attribute: oldConstraint.firstAttribute, relatedBy: oldConstraint.relation, toItem: secondItem, attribute: oldConstraint.secondAttribute, multiplier: oldConstraint.multiplier, constant: oldConstraint.constant))
        }
        
        for newView in DoubleSliderBaseView.subviews {
            self.addSubview(newView)
        }
        
        self.addConstraints(newConstraints)
        
        firstLabel.isBordered       = false
        firstLabel.identifier       = NSUserInterfaceItemIdentifier(rawValue: "10")
        firstLabel.isEditable       = false
        firstLabel.isSelectable     = false
        firstLabel.stringValue      = "00:00"
        firstLabel.backgroundColor  = NSColor.white.withAlphaComponent(0)
        firstLabel.font             = NSFont(name: "HelveticaNeue", size: 10)
        firstLabel.textColor        = NSColor.gray
        firstLabel.alignment        = NSTextAlignment.left
        
        secondLabel.isBordered      = false
        secondLabel.identifier      = NSUserInterfaceItemIdentifier(rawValue: "10")
        secondLabel.isEditable      = false
        secondLabel.isSelectable    = false
        secondLabel.stringValue     = "00:00"
        secondLabel.backgroundColor = NSColor.white.withAlphaComponent(0)
        secondLabel.font            = NSFont(name: "HelveticaNeue", size: 10)
        secondLabel.textColor       = NSColor.gray
        secondLabel.alignment       = NSTextAlignment.left
        
    }
    
    /// If has a delegate we will send changed notification, and new values for slider.
    /// Also we trigger action if this control has one.
    func create() {
        if self.action != nil {
            NSApp.sendAction(self.action!, to: self.target, from: self)
        }
        
        if let delegate = self.delegate {
            delegate.controller(self, didChangeFirstValue: firstValue, secondValue: secondValue)
        }
    }
    
    /// Convert seconds to 00:00 format
    fileprivate func secondsToMinute(_ sec:CGFloat) -> String{
        let intSec = Int(sec)
        let min =  intSec / 60
        let remainS = intSec % 60
        let str = NSString(format: "%02d:%02d", min, remainS)
        return String(str)
    }
    
}

