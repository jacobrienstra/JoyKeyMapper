//
//  GyroCalibration+CoreDataClass.swift
//  JoyKeyMapper
//
//  Created by Jacob Rienstra on 8/22/20.
//  Copyright © 2020 DarkHorse. All rights reserved.
//
//

import Foundation
import CoreData
import SceneKit

// http://gyrowiki.jibbsmart.com/
@objc(GyroCalibration)
public class GyroCalibration: NSManagedObject {
    var frontIndex: Int = 0
    var windows: [GyroAveragingWindow] = []
    public var isCalibrating: Bool = false

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.windows = [GyroAveragingWindow](repeating: GyroAveragingWindow(), count: Int(numWindows))
        self.isCalibrating = false
    }
    
    public override func awakeFromFetch() {
        super.awakeFromFetch()
        self.windows = [GyroAveragingWindow](repeating: GyroAveragingWindow(), count: Int(numWindows))
        self.isCalibrating = false
    }

    struct GyroAveragingWindow {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var z: CGFloat = 0
        var numSamples: Int = 0
    }

    public func resetContCalibration() {
        for i in 0..<self.numWindows {
            self.windows[Int(i)] = GyroAveragingWindow()
        }
    }

    func getNumTotalSamples() -> Int { // dt in ms
        return Int(round(CGFloat(self.windowLength) / CGFloat(self.dt)))
    }

    func getNumSingleSamples() -> Int {
        return Int(self.getNumTotalSamples() / (Int(self.numWindows) - 2))
    }

    public func pushSensorSamples(x: CGFloat, y: CGFloat, z: CGFloat) {
            if self.windows[self.frontIndex].numSamples >= self.getNumSingleSamples() {
                // next
                self.frontIndex = Int((Int32(self.frontIndex + 1) + self.numWindows) % self.numWindows)
                self.windows[self.frontIndex] = GyroAveragingWindow()
            }
            self.windows[self.frontIndex].numSamples += 1
            self.windows[self.frontIndex].x += x
            self.windows[self.frontIndex].y += y
            self.windows[self.frontIndex].z += z
    }

    public func getAverage() -> SCNVector3? {
        var weight: CGFloat = 0.0
        var totalX: CGFloat = 0.0
        var totalY: CGFloat = 0.0
        var totalZ: CGFloat = 0.0
        var samplesWanted: Int = self.getNumTotalSamples()
        let samplesPerWindow: CGFloat = CGFloat(self.getNumSingleSamples())

        // get the average of each window
        // and a weighted average of all those averages, weighted by the number of samples it has compared to how many samples a full window will have.
        // this isn't a perfect rolling average. the last window, which has more samples than we need, will have its contribution weighted according to how many samples it would ideally have for the current span of time.
        for i in 0..<self.numWindows {
            if (samplesWanted == 0) { break }
            let cycledIndex: Int = Int((i + Int32(self.frontIndex)) % self.numWindows)
            let window = self.windows[cycledIndex]
            if window.numSamples == 0 {
                continue;
            }
            var thisWeight: CGFloat = 1.0
            if (samplesWanted < window.numSamples) {
                thisWeight = CGFloat(samplesWanted) / CGFloat(window.numSamples)
                samplesWanted = 0
            } else {
                thisWeight = CGFloat(window.numSamples) / samplesPerWindow
                samplesWanted -= window.numSamples
            }

            totalX += window.x / CGFloat(window.numSamples) * thisWeight
            totalY += window.y / CGFloat(window.numSamples) * thisWeight
            totalZ += window.z / CGFloat(window.numSamples) * thisWeight
            weight += thisWeight
        }
        if weight > 0.0 {
            let x = totalX / weight
            let y = totalY / weight
            let z = totalZ / weight
            return SCNVector3(x: x, y: y, z: z)
        }
        return nil
    }
}


