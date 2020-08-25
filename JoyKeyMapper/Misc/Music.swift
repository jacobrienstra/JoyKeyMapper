//
//  Music.swift
//  JoyKeyMapper
//
//  Created by Jacob Rienstra on 8/25/20.
//  Copyright © 2020 DarkHorse. All rights reserved.
//

import Foundation
import JoyConSwift

public enum MusicPiece: Int {
    case HarryPotter1 = 0
    case HarryPotter2 = 1
}

public func getMusicPieceName(_ val: MusicPiece?) -> String {
    switch(val) {
        case .HarryPotter1:
            return "Harry Potter Melody"
        case .HarryPotter2:
            return "Harry Potter Alto"
        case .none:
            return ""
    }
}

class NoteOp: Operation {
    
    let function: () -> Void
    
    init(function: @escaping () -> Void) {
        self.function = function
    }
    
    override func main() {
        self.function()
    }
}


func playSong(controller: JoyConSwift.Controller?, queue: OperationQueue, notes: [Note], _ tempo: UInt32 = 132) {
    
    controller?.enableVibration(enable: true)
    let noteFn: (Note) -> Void = { note in
        controller?.type == .JoyConL ? controller?.playNote(note: note, left: true) : controller?.playNote(note: note, left: false) }
    
    controller?.bpm = tempo
    for n in notes {
        queue.addOperation(NoteOp(function: { noteFn(n) }))
    }
}

let harryPotter1: [Note] = [
    Note(.B3, 1),
    Note(.E4, 1.5),
    Note(.G4, 0.5),
    Note(.Fs4, 1),
    Note(.E4, 2),
    Note(.B4, 1),
    Note(.A4, 3),
    Note(.Fs4, 3),
    Note(.E4, 1.5),
    Note(.G4, 0.5),
    Note(.Fs4, 1),
    Note(.Ds4, 2),
    Note(.F4, 1),
    Note(.B3, 5),
    Note(.B3, 1),
    Note(.E4, 1.5),
    Note(.G4, 0.5),
    Note(.Fs4, 1),
    Note(.E4, 2),
    Note(.B4, 1),
    Note(.D5, 2),
    Note(.Cs5, 1),
    Note(.C5, 2),
    Note(.Gs4, 1),
    Note(.C5, 1.5),
    Note(.B4, 0.5),
    Note(.As4, 1),
    Note(.As3, 2),
    Note(.G4, 1),
    Note(.E4, 5),
    Note(.G4, 1),
    Note(.B4, 2),
    Note(.G4, 1),
    Note(.B4, 2),
    Note(.G4, 1),
    Note(.C5, 2),
    Note(.B4, 1),
    Note(.As4, 2),
    Note(.Fs4, 1),
    Note(.G4, 1.5),
    Note(.B4, 0.5),
    Note(.As4, 1),
    Note(.As3, 2),
    Note(.B3, 1),
    Note(.B4, 5),
    Note(.G4, 1),
    Note(.B4, 2),
    Note(.G4, 1),
    Note(.B4, 2),
    Note(.G4, 1),
    Note(.D5, 2),
    Note(.Cs5, 1),
    Note(.C5, 2),
    Note(.Gs4, 1),
    Note(.C5, 1.5),
    Note(.B4, 0.5),
    Note(.As4, 1),
    Note(.As3, 2),
    Note(.G4, 1),
    Note(.E4, 7),
]

let harryPotter2: [Note] = [
    Note(.N, 1),
    Note(.E3, 3),
    Note(.E3, 3),
    Note(.E3, 3),
    Note(.E3, 3),
    Note(.E3, 3),
    Note(.As3, 2),
    Note(.B2, 1),
    Note(.E3, 2),
    Note(.G3, 1),
    Note(.B3, 2),
    Note(.B2, 1),
    Note(.E3, 3),
    Note(.E3, 3),
    Note(.As3, 3),
    Note(.Gs3, 3),
    Note(.A3, 3),
    Note(.Fs3, 3),
    Note(.E3, 2),
    Note(.G3, 1),
    Note(.B3, 2),
    Note(.B2, 1),
    Note(.E3, 2),
    Note(.G3, 1),
    Note(.B3, 2),
    Note(.B2, 1),
    Note(.E3, 2),
    Note(.G3, 1),
    Note(.C4, 2),
    Note(.B2, 1),
    Note(.E3, 2),
    Note(.G3, 1),
    Note(.C3, 2),
    Note(.G3, 1),
    Note(.E3, 2),
    Note(.G3, 1),
    Note(.B3, 2),
    Note(.B2, 1),
    Note(.E3, 2),
    Note(.G3, 1),
    Note(.B3, 2),
    Note(.G3, 1),
    Note(.As3, 3),
    Note(.Gs3, 3),
    Note(.G3, 3),
    Note(.Fs3, 3),
    Note(.E3, 2),
    Note(.G3, 1),
    Note(.B3, 2),
    Note(.B2, 1),
    Note(.E3, 1)
]
