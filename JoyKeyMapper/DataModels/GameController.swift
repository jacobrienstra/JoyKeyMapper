//
//  GameController.swift
//  JoyKeyMapper
//
//  Created by magicien on 2019/07/14.
//  Copyright © 2019 DarkHorse. All rights reserved.
//

import JoyConSwift
import InputMethodKit
import SceneKit

extension JoyCon.BatteryStatus {
    static let stringMap: [JoyCon.BatteryStatus: String] = [
        .empty: "Empty",
        .critical: "Critical",
        .low: "Low",
        .medium: "Medium",
        .full: "Full",
        .unknown: "Unknown"
    ]
    
    var string: String {
        return JoyCon.BatteryStatus.stringMap[self] ?? "Unknown"
    }
    
    var localizedString: String {
        return NSLocalizedString(self.string, comment: "BatteryStatus localized string")
    }
}

let GYRO_ADJUSTMENT_FACTOR: CGFloat = 50
let MaxSmoothingSamples: Int = 64
var GyroSmoothingBuffer: [SCNVector3] = [SCNVector3](repeating: SCNVector3(0,0,0), count: MaxSmoothingSamples)
let GyroSmoothingIndex: Int = 0

class GameController {
    let data: ControllerData

    var type: JoyCon.ControllerType
    var bodyColor: NSColor
    var buttonColor: NSColor
    var leftGripColor: NSColor?
    var rightGripColor: NSColor?
    
    var controller: JoyConSwift.Controller? {
        didSet {
            self.setControllerHandler()
        }
    }
    var currentConfigData: KeyConfig {
        didSet { self.updateKeyMap() }
    }
    var currentConfig: [JoyCon.Button:KeyMap] = [:]
    var currentLStickMode: StickType = .None
    var currentLStickConfig: [JoyCon.StickDirection:KeyMap] = [:]
    var currentRStickMode: StickType = .None
    var currentRStickConfig: [JoyCon.StickDirection:KeyMap] = [:]
    var currentGyroConfig: GyroConfig?

    var isEnabled: Bool = true {
        didSet {
            self.updateControllerIcon()
        }
    }
    var isLeftDragging: Bool = false
    var isRightDragging: Bool = false
    var isCenterDragging: Bool = false
    
    var lastAccess: Date? = nil
    var timer: Timer? = nil
    var icon: NSImage? {
        if self._icon == nil {
            self.updateControllerIcon()
        }

        return self._icon
    }
    private var _icon: NSImage?
    
    var localizedBatteryString: String {
        return (self.controller?.battery ?? .unknown).localizedString
    }

    init(data: ControllerData) {
        self.data = data
        
        
        guard let defaultConfig = self.data.defaultConfig else {
            fatalError("Failed to get defaultConfig")
        }
        self.currentConfigData = defaultConfig
        self.currentGyroConfig = self.currentConfigData.gyroConfig

        let type = JoyCon.ControllerType(rawValue: data.type ?? "")
        self.type = type ?? JoyCon.ControllerType(rawValue: "unknown")!

        let defaultColor = NSColor(red: 55.0 / 255, green: 55.0 / 255, blue: 55.0 / 255, alpha: 55.0 / 255)

        self.bodyColor = defaultColor
        if let bodyColorData = data.bodyColor {
            if let bodyColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: bodyColorData) {
                self.bodyColor = bodyColor
            }
        }
        
        self.buttonColor = defaultColor
        if let buttonColorData = data.buttonColor {
            if let buttonColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: buttonColorData) {
                self.buttonColor = buttonColor
            }
        }

        self.leftGripColor = nil
        if let leftGripColorData = data.leftGripColor {
            if let leftGripColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: leftGripColorData) {
                self.leftGripColor = leftGripColor
            }
        }
        
        self.rightGripColor = nil
        if let rightGripColorData = data.rightGripColor {
            if let rightGripColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: rightGripColorData) {
                self.rightGripColor = rightGripColor
            }
        }
    }
    
    // MARK: - Controller event handlers
    
    func setControllerHandler() {
        guard let controller = self.controller else { return }
        
        controller.setPlayerLights(l1: .on, l2: .off, l3: .off, l4: .off)
        controller.enableIMU(enable: true)
        controller.setInputMode(mode: .standardFull)
        controller.buttonPressHandler = { [weak self] button in
            self?.buttonPressHandler(button: button)
        }
        controller.buttonReleaseHandler = { [weak self] button in
            if !(self?.isEnabled ?? false) { return }
            self?.buttonReleaseHandler(button: button)
        }
        controller.leftStickHandler = { [weak self] (newDir, oldDir) in
            if !(self?.isEnabled ?? false) { return }
            self?.leftStickHandler(newDirection: newDir, oldDirection: oldDir)
        }
        controller.rightStickHandler = { [weak self] (newDir, oldDir) in
            if !(self?.isEnabled ?? false) { return }
            self?.rightStickHandler(newDirection: newDir, oldDirection: oldDir)
        }
        controller.leftStickPosHandler = { [weak self] pos in
            if !(self?.isEnabled ?? false) { return }
            self?.leftStickPosHandler(pos: pos)
        }
        controller.rightStickPosHandler = { [weak self] pos in
            if !(self?.isEnabled ?? false) { return }
            self?.rightStickPosHandler(pos: pos)
        }
        controller.sensorHandler = { [weak self] (accData, gyroData) in
            if !(self?.isEnabled ?? false) { return }
            self?.sensorHandler(accData: accData, gyroData: gyroData)
            
        }
        controller.batteryChangeHandler = { [weak self] newState, oldState in
            self?.batteryChangeHandler(newState: newState, oldState: oldState)
        }
        controller.isChargingChangeHandler = { [weak self] isCharging in
            self?.isChargingChangeHandler(isCharging: isCharging)
        }
        
        // Update Controller data
        
        self.data.type = controller.type.rawValue
        self.type = controller.type

        let bodyColor = NSColor(cgColor: controller.bodyColor)!
        self.data.bodyColor = try! NSKeyedArchiver.archivedData(withRootObject: bodyColor, requiringSecureCoding: false)
        self.bodyColor = bodyColor
        
        let buttonColor = NSColor(cgColor: controller.buttonColor)!
        self.data.buttonColor = try! NSKeyedArchiver.archivedData(withRootObject: buttonColor, requiringSecureCoding: false)
        self.buttonColor = buttonColor
        
        self.data.leftGripColor = nil
        if let leftGripColor = controller.leftGripColor {
            if let nsLeftGripColor = NSColor(cgColor: leftGripColor) {
                self.data.leftGripColor = try? NSKeyedArchiver.archivedData(withRootObject: nsLeftGripColor, requiringSecureCoding: false)
                self.leftGripColor = nsLeftGripColor
            }
        }
        
        self.data.rightGripColor = nil
        if let rightGripColor = controller.rightGripColor {
            if let nsRightGripColor = NSColor(cgColor: rightGripColor) {
                self.data.rightGripColor = try? NSKeyedArchiver.archivedData(withRootObject: nsRightGripColor, requiringSecureCoding: false)
                self.rightGripColor = nsRightGripColor
            }
        }
        
        self.updateControllerIcon()
    }
    
    func buttonPressHandler(button: JoyCon.Button) {
        guard let config = self.currentConfig[button] else { return }
        self.buttonPressHandler(config: config)
    }
    
    func buttonPressHandler(config: KeyMap) {
        DispatchQueue.main.async {
            print(config.keyCode, "pressed")
            let source = CGEventSource(stateID: .hidSystemState)

            if config.keyCode >= 0 {
                metaKeyEvent(config: config, keyDown: true)
                
                if let systemKey = systemDefinedKey[Int(config.keyCode)] {
                    let mousePos = NSEvent.mouseLocation
                    let flags = NSEvent.ModifierFlags(rawValue: 0x0a00)
                    let data1 = Int((systemKey << 16) | 0x0a00)
                    
                    let ev = NSEvent.otherEvent(
                        with: .systemDefined,
                        location: mousePos,
                        modifierFlags: flags,
                        timestamp: ProcessInfo().systemUptime,
                        windowNumber: 0,
                        context: nil,
                        subtype: Int16(NX_SUBTYPE_AUX_CONTROL_BUTTONS),
                        data1: data1,
                        data2: -1)
                    ev?.cgEvent?.post(tap: .cghidEventTap)
                } else {
                    let event = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(config.keyCode), keyDown: true)
                    event?.flags = CGEventFlags(rawValue: CGEventFlags.RawValue(config.modifiers))
                    event?.post(tap: .cghidEventTap)
                }
            }
        
            if config.mouseButton >= 0 {
                let mousePos = NSEvent.mouseLocation
                let cursorPos = CGPoint(x: mousePos.x, y: NSScreen.main!.frame.maxY - mousePos.y)

                metaKeyEvent(config: config, keyDown: true)

                var event: CGEvent?
                if config.mouseButton == 0 {
                    event = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: cursorPos, mouseButton: .left)
                    self.isLeftDragging = true
                } else if config.mouseButton == 1 {
                    event = CGEvent(mouseEventSource: source, mouseType: .rightMouseDown, mouseCursorPosition: cursorPos, mouseButton: .right)
                    self.isRightDragging = true
                } else if config.mouseButton == 2 {
                    event = CGEvent(mouseEventSource: source, mouseType: .otherMouseDown, mouseCursorPosition: cursorPos, mouseButton: .center)
                    self.isCenterDragging = true
                }
                event?.flags = CGEventFlags(rawValue: CGEventFlags.RawValue(config.modifiers))
                event?.post(tap: .cghidEventTap)
            }
        }
    }
    
    func buttonReleaseHandler(button: JoyCon.Button) {
        guard let config = self.currentConfig[button] else { return }
        self.buttonReleaseHandler(config: config)
    }
    
    func buttonReleaseHandler(config: KeyMap) {
        DispatchQueue.main.async {
            let source = CGEventSource(stateID: .hidSystemState)
            print(config.keyCode, "release")
            
            if config.keyCode >= 0 {
                if let systemKey = systemDefinedKey[Int(config.keyCode)] {
                    let mousePos = NSEvent.mouseLocation
                    let flags = NSEvent.ModifierFlags(rawValue: 0x0b00)
                    let data1 = Int((systemKey << 16) | 0x0b00)
                    
                    let ev = NSEvent.otherEvent(
                        with: .systemDefined,
                        location: mousePos,
                        modifierFlags: flags,
                        timestamp: ProcessInfo().systemUptime,
                        windowNumber: 0,
                        context: nil,
                        subtype: Int16(NX_SUBTYPE_AUX_CONTROL_BUTTONS),
                        data1: data1,
                        data2: -1)
                    ev?.cgEvent?.post(tap: .cghidEventTap)
                } else {
                    let event = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(config.keyCode), keyDown: false)
                    event?.flags = CGEventFlags(rawValue: CGEventFlags.RawValue(config.modifiers))
                    event?.post(tap: .cghidEventTap)
                }
                    
                metaKeyEvent(config: config, keyDown: false)
            }

            if config.mouseButton >= 0 {
                let mousePos = NSEvent.mouseLocation
                let cursorPos = CGPoint(x: mousePos.x, y: NSScreen.main!.frame.maxY - mousePos.y)
                
                var event: CGEvent?
                if config.mouseButton == 0 {
                    event = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: cursorPos, mouseButton: .left)
                    self.isLeftDragging = false
                } else if config.mouseButton == 1 {
                    event = CGEvent(mouseEventSource: source, mouseType: .rightMouseUp, mouseCursorPosition: cursorPos, mouseButton: .right)
                    self.isRightDragging = false
                } else if config.mouseButton == 2 {
                    event = CGEvent(mouseEventSource: source, mouseType: .otherMouseUp, mouseCursorPosition: cursorPos, mouseButton: .center)
                    self.isCenterDragging = false
                }
                event?.post(tap: .cghidEventTap)
            }
        }
    }
    
    func stickMouseHandler(pos: CGPoint, speed: CGFloat) {
        DispatchQueue.main.async {
            if abs(pos.x) == 0 && abs(pos.y) == 0 {
                return
            }
            let mousePos = NSEvent.mouseLocation
            let newX = mousePos.x + pos.x * speed
            let newY = NSScreen.main!.frame.maxY - mousePos.y - pos.y * speed
            
            let newPos = CGPoint(x: newX, y: newY)
            
            let source = CGEventSource(stateID: .hidSystemState)
            if self.isLeftDragging {
                let event = CGEvent(mouseEventSource: source, mouseType: .leftMouseDragged, mouseCursorPosition: newPos, mouseButton: .left)
                event?.post(tap: .cghidEventTap)
            } else if self.isRightDragging {
                let event = CGEvent(mouseEventSource: source, mouseType: .rightMouseDragged, mouseCursorPosition: newPos, mouseButton: .right)
                event?.post(tap: .cghidEventTap)
            } else if self.isCenterDragging {
                let event = CGEvent(mouseEventSource: source, mouseType: .otherMouseDragged, mouseCursorPosition: newPos, mouseButton: .center)
                event?.post(tap: .cghidEventTap)
            } else {
                CGDisplayMoveCursorToPoint(CGMainDisplayID(), newPos)
            }
        }
    }
    
    func stickMouseWheelHandler(pos: CGPoint, speed: CGFloat) {
        DispatchQueue.main.async {
            if pos.x == 0 && pos.y == 0 {
                return
            }
            let wheelX = Int32(pos.x * speed)
            let wheelY = Int32(pos.y * speed)
            
            let source = CGEventSource(stateID: .hidSystemState)
            let event = CGEvent(scrollWheelEvent2Source: source, units: .pixel, wheelCount: 2, wheel1: wheelY, wheel2: wheelX, wheel3: 0)
            event?.post(tap: .cghidEventTap)
        }
        
    }
    
    func leftStickHandler(newDirection: JoyCon.StickDirection, oldDirection: JoyCon.StickDirection) {
        if self.currentLStickMode == .Key {
            if let config = self.currentLStickConfig[oldDirection] {
                self.buttonReleaseHandler(config: config)
            }
            if let config = self.currentLStickConfig[newDirection] {
                self.buttonPressHandler(config: config)
            }
        }
    }

    func rightStickHandler(newDirection: JoyCon.StickDirection, oldDirection: JoyCon.StickDirection) {
        if self.currentRStickMode == .Key {
            if let config = self.currentRStickConfig[oldDirection] {
                self.buttonReleaseHandler(config: config)
            }
            if let config = self.currentRStickConfig[newDirection] {
                self.buttonPressHandler(config: config)
            }
        }
    }

    func leftStickPosHandler(pos: CGPoint) {
            let speed = CGFloat(self.currentConfigData.leftStick?.speed ?? 0)
            if self.currentLStickMode == .Mouse {
                self.stickMouseHandler(pos: pos, speed: speed)
            } else if self.currentLStickMode == .MouseWheel {
                self.stickMouseWheelHandler(pos: pos, speed: speed)
            }
    }
    
    func rightStickPosHandler(pos: CGPoint) {
            let speed = CGFloat(self.currentConfigData.rightStick?.speed ?? 0)
            if self.currentRStickMode == .Mouse {
                self.stickMouseHandler(pos: pos, speed: speed)
            } else if self.currentRStickMode == .MouseWheel {
                self.stickMouseWheelHandler(pos: pos, speed: speed)
            }
    }
    
    func sensorHandler(accData: SCNVector3, gyroData: SCNVector3) {
        if self.currentGyroConfig?.enabled == true {
            DispatchQueue.main.async {
                guard let gyroConfig = self.currentGyroConfig else { return }
                var gyro = gyroData
                var dt: CGFloat = 15
                if let calibration = gyroConfig.calibration {
                    if (calibration.isCalibrating) {
                        calibration.pushSensorSamples(x: gyro.x, y: gyro.y, z: gyro.z)
                    }
                    
                    let offset = gyroConfig.calibration!.getAverage()
                    dt = CGFloat(Double(gyroConfig.calibration!.dt) / 1000.0)

                    if offset != nil {
                        gyro.x -= offset?.x ?? 0
                        gyro.y -= offset?.y ?? 0
                        gyro.z -= offset?.z ?? 0
                        print(String(format: "%.2f, %.2f", offset?.z ?? 0, offset?.y ?? 0))
                    }
                }
                
                let GetSmoothedInput: (SCNVector3) -> SCNVector3 = { input in
                    let CurrentIndex: Int = (GyroSmoothingIndex + 1) % MaxSmoothingSamples
                    GyroSmoothingBuffer[CurrentIndex] = input
                 
                    var average: SCNVector3 = SCNVector3(0,0,0)
                    for sample in GyroSmoothingBuffer {
                        average += sample
                    }
                    average = average / CGFloat(GyroSmoothingBuffer.count)

                    return average
                }
                
                let GetTieredSmoothedInput: (SCNVector3) -> SCNVector3 = { input in
                    let magnitude: CGFloat = sqrt(input.z * input.z + input.y * input.y)
                    var directWeight = (magnitude - CGFloat(gyroConfig.smoothThreshold / 2)) / (CGFloat(gyroConfig.smoothThreshold) - CGFloat(gyroConfig.smoothThreshold / 2))
                    directWeight = clamp(value: directWeight, lower: 0.0, upper: 1.0)

                    return input * (directWeight) + GetSmoothedInput(input * (1.0 - directWeight))
                }
                
                let GetTightenedInput: (SCNVector3) -> SCNVector3 = { input in
                    let magnitude: CGFloat = sqrt(input.z * input.z + input.y * input.y)
                    if magnitude < CGFloat(gyroConfig.tightenThreshold) {
                        let inputScale = magnitude / CGFloat(gyroConfig.tightenThreshold)
                        return input * inputScale
                    }
                    return input
                }
                
                if (gyroConfig.useSmoothing) {
                    gyro = GetTieredSmoothedInput(gyro)
                }
                
                if (gyroConfig.useTightening) {
                    gyro = GetTightenedInput(gyro)
                }
                
                var pos: CGPoint = CGPoint(x: gyro.z * dt, y: gyro.y * dt)
                
                if (gyroConfig.useAcceleration) { // acceleration enabled
                    let speed: CGFloat = sqrt(gyro.z * gyro.z + gyro.y * gyro.y)

                    var slowFastFactor: CGFloat = (speed - CGFloat(gyroConfig.slowAccThreshold)) / (CGFloat(gyroConfig.fastAccThreshold) - CGFloat(gyroConfig.slowAccThreshold))
                    slowFastFactor = clamp(value: slowFastFactor, lower: 0.0, upper: 1.0)
                    let newSensitivity: CGFloat = CGFloat(gyroConfig.slowAccSensitivity) * (1 - slowFastFactor) + CGFloat(gyroConfig.fastAccSensitivity) * slowFastFactor
                    
                    pos.x = gyro.z * newSensitivity * dt
                    pos.y = gyro.y * newSensitivity * dt
                }

                self.stickMouseHandler(pos: pos, speed: GYRO_ADJUSTMENT_FACTOR * CGFloat(gyroConfig.defaultSensitivity))
            }
        }
    }
    
    func batteryChangeHandler(newState: JoyCon.BatteryStatus, oldState: JoyCon.BatteryStatus) {
        self.updateControllerIcon()
        
        if newState == .full && oldState != .unknown {
            AppNotifications.notifyBatteryFullCharge(self)
        }
        if newState == .empty {
            AppNotifications.notifyBatteryLevel(self)
        }
        if newState == .critical && oldState != .empty {
            AppNotifications.notifyBatteryLevel(self)
        }
        if newState == .low && oldState != .critical && oldState != .empty {
            AppNotifications.notifyBatteryLevel(self)
        }

        DispatchQueue.main.async {
            guard let delegate = NSApplication.shared.delegate as? AppDelegate else { return }
            delegate.updateControllersMenu()
        }
    }
    
    func isChargingChangeHandler(isCharging: Bool) {
        self.updateControllerIcon()
        
        if isCharging {
            AppNotifications.notifyStartCharge(self)
        } else {
            AppNotifications.notifyStopCharge(self)
        }

        DispatchQueue.main.async {
            guard let delegate = NSApplication.shared.delegate as? AppDelegate else { return }
            delegate.updateControllersMenu()
        }
    }
    
    // MARK: - Controller Icon
    
    func updateControllerIcon() {
        self._icon = GameControllerIcon(for: self)
        NotificationCenter.default.post(name: .controllerIconChanged, object: self)
        
        DispatchQueue.main.async {
            guard let delegate = NSApplication.shared.delegate as? AppDelegate else { return }
            delegate.updateControllersMenu()
        }
    }
    
    // MARK: -
    
    func switchApp(bundleID: String) {
        let appConfig = self.data.appConfigs?.first(where: {
            guard let appConfig = $0 as? AppConfig else { return false }
            return appConfig.app?.bundleID == bundleID
        }) as? AppConfig
        
        if let keyConfig = appConfig?.config {
            self.currentConfigData = keyConfig
            return
        }
        
        guard let defaultConfig = self.data.defaultConfig else {
            fatalError("Failed to get defaultConfig")
        }
        self.currentConfigData = defaultConfig
    }
    
    func updateKeyMap() {
        var newKeyMap: [JoyCon.Button:KeyMap] = [:]
        self.currentConfigData.keyMaps?.enumerateObjects { (map, _) in
            guard let keyMap = map as? KeyMap else { return }
            guard let buttonStr = keyMap.button else { return }
            let buttonName = buttonNames.first { (_, name) in
                return name == buttonStr
            }
            guard let button = buttonName?.key else { return }
            
            newKeyMap[button] = keyMap
        }
        self.currentConfig = newKeyMap
        
        self.currentLStickMode = .None
        if let stickTypeStr = self.currentConfigData.leftStick?.type,
            let stickType = StickType(rawValue: stickTypeStr) {
            self.currentLStickMode = stickType
        }

        var newLeftStickMap: [JoyCon.StickDirection:KeyMap] = [:]
        self.currentConfigData.leftStick?.keyMaps?.enumerateObjects { (map, _) in
            guard let keyMap = map as? KeyMap else { return }
            guard let buttonStr = keyMap.button else { return }
            let directionName = directionNames.first { (_, name) in
                return name == buttonStr
            }
            guard let direction = directionName?.key else { return }
            
            newLeftStickMap[direction] = keyMap
        }
        self.currentLStickConfig = newLeftStickMap
        
        self.currentRStickMode = .None
        if let stickTypeStr = self.currentConfigData.rightStick?.type,
            let stickType = StickType(rawValue: stickTypeStr) {
            self.currentRStickMode = stickType
        }
        
        var newRightStickMap: [JoyCon.StickDirection:KeyMap] = [:]
        self.currentConfigData.rightStick?.keyMaps?.enumerateObjects { (map, _) in
            guard let keyMap = map as? KeyMap else { return }
            guard let buttonStr = keyMap.button else { return }
            let directionName = directionNames.first { (_, name) in
                return name == buttonStr
            }
            guard let direction = directionName?.key else { return }
            
            newRightStickMap[direction] = keyMap
        }
        self.currentRStickConfig = newRightStickMap
    }
    
    func addApp(url: URL) {
        guard let delegate = NSApplication.shared.delegate as? AppDelegate else { return }
        guard let manager = delegate.dataManager else { return }
        guard let bundle = Bundle(url: url) else { return }
        guard let info = bundle.infoDictionary else { return }

        let bundleID = info["CFBundleIdentifier"] as? String ?? ""
        let appIndex = self.data.appConfigs?.index(ofObjectPassingTest: { (obj, index, stop) in
            guard let appConfig = obj as? AppConfig else { return false }
            return appConfig.app?.bundleID == bundleID
        })
        if appIndex != nil && appIndex != NSNotFound {
            // The selected app has been already added.
            return
        }
        
        let appConfig = manager.createAppConfig(type: self.type)

        let displayName = FileManager.default.displayName(atPath: url.absoluteString)
        let iconFile = info["CFBundleIconFile"] as? String ?? ""
        if let iconURL = bundle.url(forResource: iconFile, withExtension: nil) {
            do {
                let iconData = try Data(contentsOf: iconURL)
                appConfig.app?.icon = iconData
            } catch {}
        } else if let iconURL = bundle.url(forResource: "\(iconFile).icns", withExtension: nil) {
            do {
                let iconData = try Data(contentsOf: iconURL)
                appConfig.app?.icon = iconData
            } catch {}
        }
        
        appConfig.app?.bundleID = bundleID
        appConfig.app?.displayName = displayName
        
        self.data.addToAppConfigs(appConfig)
    }
    
    func removeApp(_ app: AppConfig) {
        self.data.removeFromAppConfigs(app)
    }
    
    @objc func toggleEnableKeyMappings() {
        self.isEnabled = !self.isEnabled
    }
    
    @objc func disconnect() {
        self.stopTimer()
        self.controller?.setHCIState(state: .disconnect)
    }
    
    // MARK: - Timer

    func updateAccessTime() {
        self.lastAccess = Date(timeIntervalSinceNow: 0)
    }
    
    func startTimer() {
        self.stopTimer()
        
        let checkInterval: TimeInterval = 1 * 60 // 1 min
        self.timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            if AppSettings.disconnectTime <= 0 { return }
            guard let lastAccess = self?.lastAccess else { return }
            let disconnectTime = TimeInterval(AppSettings.disconnectTime * 60)
            
            let now = Date(timeIntervalSinceNow: 0)
            if now.timeIntervalSince(lastAccess) > disconnectTime {
                self?.disconnect()
            }
        }
        self.updateAccessTime()
    }
    
    func stopTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }
}
