//
//  VideoAnalyzer.swift
//  Bitrate Viewer
//
//  Created by Damiano Galassi on 02/06/16.
//  Copyright © 2016 Damiano Galassi. All rights reserved.
//

import Foundation
import CoreMedia

public class VideoAnalyzer {

    private var fileUrl : URL?

    private var originalSamples = [Sample]()

    private(set) var samples = [Sample]()
    private(set) var timescale:CMTimeScale = 0

    private(set) var size: Int64 = 0
    private(set) var duration: CMTime = CMTime()
    private(set) var numOfFrames: Int = 0

    private(set) var maxSize: Int64 = 0
    private(set) var minSize: Int64 = 0

    private(set) var avgBitrate: Int64 = 0
    private(set) var minBitrate: Int64 = 0
    private(set) var peakBitrate: Int64 = 0

    public init() {
    }

    public init(url: URL) throws {
        self.fileUrl = url

        (originalSamples, timescale) = try Sample.loadData(url)

        size = originalSamples.reduce(0) {$0 + $1.size}
        duration = CMTime(value: originalSamples.reduce(0) {$0 + $1.duration}, timescale: timescale)
        numOfFrames = originalSamples.count
        avgBitrate = Int64(Double(size) / (Double(duration.value) / Double(duration.timescale)))

        let oneSecond = CMTime(seconds: 1, preferredTimescale: 1)
        analyze(.timeAverage(time: oneSecond))
    }

    public enum AverageMode {
        case timeAverage(time: CMTime)
        case gop
        case frame
    }

    public func analyze(_ mode: AverageMode) {
        switch mode {
        case let .timeAverage(time):
            samples = groupBy(time)

        case .gop:
            samples = groupByGOP()

        case .frame:
            samples = originalSamples
        }

        clearCache()
        updateStats()
    }

    private func updateStats() {
        if let maxSizeSample = samples.max(by: {$0.size < $1.size})  {
            self.maxSize = maxSizeSample.size
        }

        if let minSizeSample = samples.min(by: {$0.size < $1.size})  {
            self.minSize = minSizeSample.size
        }
    }

    private func groupBy(_ sampleTime: CMTime) -> [Sample] {
        let convertedTime = sampleTime.convertScale(duration.timescale, method: .roundHalfAwayFromZero)

        return originalSamples.eachSlice(convertedTime) {
            if let firstSample = $0.first {
                return $0.reduce(Sample(duration: 0, timeStamp: firstSample.timeStamp, size: 0, sync: false)) { $0 + $1 }
            } else {
                fatalError()
            }
        }
    }

    private func groupByGOP() -> [Sample] {
        return originalSamples.eachSlice(true) {
            if let firstSample = $0.first {
                return $0.reduce(Sample(duration: 0, timeStamp: firstSample.timeStamp, size: 0, sync: false)) { $0 + $1 }
            } else {
                fatalError()
            }
        }
    }

    public func rescaled(_ resolution: Int) -> [Sample] {
        let sliceSize = samples.count / resolution

        if cacheResolution == resolution {
            return rescaledCache
        }
        else if sliceSize > 1 {
            let scaledSamples: [Sample] = samples.eachSlice(sliceSize) {
                let reducedSample = $0.reduce(Sample(duration: 0, timeStamp: $0.first!.timeStamp, size: 0, sync: false)) { $0 + $1 }
                let maxSize = $0.max(by: {$0.size < $1.size})!.size
                let rescaledSample = Sample(duration: reducedSample.duration, timeStamp: $0.first!.timeStamp, size: maxSize, sync: false)
                return rescaledSample
            }

            rescaledCache = scaledSamples
            cacheResolution = resolution
            return scaledSamples
        } else {
            return samples
        }
    }

    private var rescaledCache = [Sample]()
    private var cacheResolution = 0

    private func clearCache() {
        rescaledCache = []
        cacheResolution = 0
    }
}
