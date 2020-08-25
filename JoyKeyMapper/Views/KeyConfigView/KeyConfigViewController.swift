//
//  KeyConfigViewController.swift
//  JoyKeyMapper
//
//  Created by magicien on 2019/07/29.
//  Copyright © 2019 DarkHorse. All rights reserved.
//

import AppKit
import InputMethodKit

protocol KeyConfigSetDelegate {
    func setKeyConfig(controller: KeyConfigViewController)
}

public enum GyroAction: Int {
    case Toggle = 0
    case KeepOn = 1
    case KeepOff = 2
    case Center = 3
}

public func getGyroActionName(_ val: GyroAction?) -> String {
    switch(val) {
        case .Toggle:
            return "Toggle"
        case .KeepOn:
            return "Keep On"
        case .KeepOff:
            return "Keep Off"
        case .Center:
            return "Center"
        case .none:
            return ""
    }
}

class KeyConfigViewController: NSViewController, NSComboBoxDelegate, KeyConfigComboBoxDelegate {
    var delegate: KeyConfigSetDelegate?
    var keyMap: KeyMap?
    var keyCodes: [Int16]? = [-1]
    
    @IBOutlet weak var titleLabel: NSTextField!
    
    @IBOutlet weak var shiftKey: NSButton!
    @IBOutlet weak var optionKey: NSButton!
    @IBOutlet weak var controlKey: NSButton!
    @IBOutlet weak var commandKey: NSButton!

    @IBOutlet weak var keyRadioButton: NSButton!
    @IBOutlet weak var gyroRadioButton: NSButton!
    @IBOutlet weak var mouseRadioButton: NSButton!
    @IBOutlet weak var musicRadioButton: NSButton!
    
    @IBOutlet weak var keyAction: KeyConfigComboBox!
    @IBOutlet weak var mouseAction: NSPopUpButton!
    @IBOutlet weak var gyroAction: NSPopUpButton!
    @IBOutlet weak var musicAction: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let keyMap = self.keyMap else { return }

        let title = NSLocalizedString("%@ Button Key Config", comment: "%@ Button Key Config")
        let buttonName = NSLocalizedString((keyMap.button ?? ""), comment: "Button Name")
        self.titleLabel.stringValue = String.localizedStringWithFormat(title, buttonName)

        let modifiers = NSEvent.ModifierFlags(rawValue: UInt(keyMap.modifiers))
        self.shiftKey.state = modifiers.contains(.shift) ? .on : .off
        self.optionKey.state = modifiers.contains(.option) ? .on : .off
        self.controlKey.state = modifiers.contains(.control) ? .on : .off
        self.commandKey.state = modifiers.contains(.command) ? .on : .off
        
        if keyMap.keyCodes?[0] ?? -1 >= 0 {
            self.keyRadioButton.state = .on
            self.keyAction.stringValue = getKeyName(keyCode: UInt16(keyMap.keyCodes![0]))
        } else if keyMap.gyroAction >= 0 {
            self.gyroRadioButton.state = .on
            self.gyroAction.selectItem(withTag: Int(keyMap.gyroAction))
        } else if keyMap.mouseButton >= 0 {
            self.mouseRadioButton.state = .on
            self.mouseAction.selectItem(withTag: Int(keyMap.mouseButton))
        } else {
            self.musicRadioButton.state = .on
            self.musicAction.selectItem(withTag: Int(keyMap.musicAction))
        }
        self.keyCodes = keyMap.keyCodes
        self.keyAction.configDelegate = self
        self.keyAction.delegate = self
    }
    
    func updateKeyMap() {
        guard let keyMap = self.keyMap else { return }
        
        var flags = NSEvent.ModifierFlags(rawValue: 0)

        if self.shiftKey.state == .on {
            flags.formUnion(.shift)
        } else {
            flags.remove(.shift)
        }
        
        if self.optionKey.state == .on {
            flags.formUnion(.option)
        } else {
            flags.remove(.option)
        }
        
        if self.controlKey.state == .on {
            flags.formUnion(.control)
        } else {
            flags.remove(.control)
        }

        
        if self.commandKey.state == .on {
            flags.formUnion(.command)
        } else {
            flags.remove(.command)
        }
        
        keyMap.modifiers = Int32(flags.rawValue)

        if self.keyRadioButton.state == .on {
            keyMap.keyCodes = self.keyCodes
            keyMap.mouseButton = -1
            keyMap.gyroAction = -1
            keyMap.musicAction = -1
        } else if mouseRadioButton.state == .on {
            keyMap.keyCodes = [-1]
            keyMap.gyroAction = -1
            keyMap.mouseButton = Int16(self.mouseAction.selectedTag())
            keyMap.musicAction = -1
        } else if gyroRadioButton.state == .on {
            keyMap.gyroAction = Int16(self.gyroAction.selectedTag())
            keyMap.keyCodes = [-1]
            keyMap.mouseButton = -1
            keyMap.musicAction = -1
        } else {
            keyMap.musicAction = Int16(self.musicAction.selectedTag())
            keyMap.keyCodes = [-1]
            keyMap.gyroAction = -1
            keyMap.mouseButton = -1
        }
        
        keyMap.isEnabled = true
        
        self.delegate?.setKeyConfig(controller: self)
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        let index = self.keyAction.indexOfSelectedItem
        if index >= 0 {
            let keyCode = keyCodeList[index]
            self.setKeyCode(UInt16(keyCode))
        }
    }
    
    func setKeyCode(_ keyCode: UInt16) {
        self.keyCodes?[0] = Int16(keyCode)
        self.keyAction.stringValue = getKeyName(keyCode: keyCode)
        self.keyRadioButton.state = .on
    }
    
    @IBAction func didPushRadioButton(_ sender: NSButton) {}
    
    @IBAction func didPushOK(_ sender: NSButton) {
        guard let window = self.view.window else { return }
        self.updateKeyMap()
        window.sheetParent?.endSheet(window, returnCode: .OK)
    }
    
    @IBAction func didPushCancel(_ sender: NSButton) {
        guard let window = self.view.window else { return }
        window.sheetParent?.endSheet(window, returnCode: .cancel)
    }
}
