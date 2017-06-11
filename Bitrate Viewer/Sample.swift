//
//  Sample.swift
//  Bitrate Viewer
//
//  Created by Damiano Galassi on 03/06/16.
//  Copyright © 2016 Damiano Galassi. All rights reserved.
//

import CoreMedia
import AVFoundation

protocol DurationEquatable {
    var duration : CMTimeValue { get }
}

protocol SyncEquatable {
    var sync : Bool { get }
}

public struct Sample: DurationEquatable, SyncEquatable {
    public let duration: CMTimeValue
    public let timeStamp: CMTimeValue
    public let size: Int64
    public let sync: Bool
}

func + (left: Sample, right: Sample) -> Sample {
    let timestamp = min(left.timeStamp, right.timeStamp)
    return Sample(duration: left.duration + right.duration, timeStamp: timestamp, size: left.size + right.size, sync: false)
}

extension Sample {

    enum LoadError: Error {
        case unsupportedFile
        case emptyFile
    }

    static func loadData(_ URL: URL) throws -> ([Sample], CMTimeScale) {
        let asset = AVAsset(url: URL)

        var samples = [Sample]()
        var timescale: CMTimeScale = 0
        samples.reserveCapacity(10000)

        if let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first, videoTrack.canProvideSampleCursors {
            if let cursor = videoTrack.makeSampleCursor(presentationTimeStamp: kCMTimeZero) {

                var timeStamp = CMTimeMake(0, cursor.currentSampleDuration.timescale)
                timescale = cursor.currentSampleDuration.timescale

                repeat {
                    let size = cursor.currentSampleStorageRange.length
                    let duration = cursor.currentSampleDuration
                    let sync = cursor.currentSampleSyncInfo.sampleIsFullSync.boolValue

                    let sample = Sample(duration: duration.value, timeStamp: timeStamp.value, size: size, sync: sync)
                    samples.append(sample)

                    timeStamp = timeStamp + duration
                } while(cursor.stepInPresentationOrder(byCount: 1) > 0)
            }
        }

        if samples.count == 0 {
            throw LoadError.emptyFile
        }

        return (samples, timescale)
    }

}

extension Array {
    func eachSlice<S>(_ nInEach: Int, transform: (ArraySlice<Element>) -> S) -> [S] {
        var result: [S] = []
        for from in stride(from: 0, to: self.count, by: nInEach) {
            if let to = self.index(from, offsetBy: nInEach, limitedBy: self.count) {
                result.append(transform(self[from ..< to]))
            } else {
                result.append(transform(self[from ..< self.endIndex]))
            }
        }
        return result
    }
}

extension Array where Element: DurationEquatable {
    func eachSlice<S>(_ durationInEach: CMTime, transform: (ArraySlice<Element>) -> S) -> [S] {
        var result: [S] = []

        var sliceDuration: Int64 = 0
        var startIndex = 0

        for from in 0 ..< self.count  {
            sliceDuration += self[from].duration

            if sliceDuration > durationInEach.value && from > 0 {
                let trasformedValue = transform(self[startIndex ..< from])
                result.append(trasformedValue)
                sliceDuration = self[from].duration
                startIndex = from
            }
        }
        return result
    }
}

extension Array where Element: SyncEquatable {
    func eachSlice<S>(_ isSync: Bool, transform: (ArraySlice<Element>) -> S) -> [S] {
        var result: [S] = []

        var startIndex = 0

        for from in 0..<self.count {

            if self[from].sync && from > 0 {
                let trasformedValue = transform(self[startIndex ..< from])
                result.append(trasformedValue)
                startIndex = from
            }
        }
        return result
    }
}
