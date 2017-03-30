//
//  Utilities.swift
//  Bitrate Viewer
//
//  Created by Damiano Galassi on 02/06/16.
//  Copyright © 2016 Damiano Galassi. All rights reserved.
//

import Foundation
import CoreMedia

extension CMTime {
    var durationText:String {
        let totalSeconds = CMTimeGetSeconds(self)
        let hours:Int = Int(totalSeconds / 3600)
        let minutes:Int = Int(totalSeconds.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds:Int = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        let milliSeconds:Int = Int((totalSeconds * 1000).truncatingRemainder(dividingBy: 1000))

        if hours > 0 {
            return String(format: "%i:%02i:%02i:%03i", hours, minutes, seconds, milliSeconds)
        } else {
            return String(format: "%02i:%02i:%03i", minutes, seconds, milliSeconds)
        }
    }
}
