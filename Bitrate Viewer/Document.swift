//
//  Document.swift
//  Bitrate Viewer
//
//  Created by Damiano Galassi on 02/06/16.
//  Copyright © 2016 Damiano Galassi. All rights reserved.
//

import Cocoa
import CoreMedia

class Document: NSDocument, ChartViewDataSource, ChartViewDelegate, NSWindowDelegate {

    @IBOutlet weak var durationLabel: NSTextField!
    @IBOutlet weak var avgBitrateLabel: NSTextField!
    @IBOutlet weak var peakBitrate: NSTextField!
    @IBOutlet weak var minBitrate: NSTextField!
    @IBOutlet weak var framesLabel: NSTextField!

    @IBOutlet weak var cursorTimeLabel: NSTextField!
    @IBOutlet weak var cursorAvgLabel: NSTextField!

    @IBOutlet weak var chartView: ChartView!
    @IBOutlet weak var modePopUp: NSPopUpButton!

    private var analyzer: VideoAnalyzer = VideoAnalyzer()

    override init() {
        super.init()
    }

    override class func autosavesInPlace() -> Bool {
        return false
    }

    override var windowNibName: String? {
        return "Document"
    }

    func windowDidResize(_ notification: Notification) {
        chartView.reloadData()
    }

    override func windowControllerDidLoadNib(_ windowController: NSWindowController) {
        chartView.dataSource = self
        chartView.delegate = self

        durationLabel.stringValue = String(analyzer.duration.durationText)
        avgBitrateLabel.stringValue = String(analyzer.avgBitrate * 8 / 1000) + " kbps"
        peakBitrate.stringValue = String(analyzer.maxSize * 8 / 1000) + " kbps"
        minBitrate.stringValue = String(analyzer.minSize * 8 / 1000) + " kbps"
        framesLabel.stringValue = String(analyzer.numOfFrames)
    }

    override func read(from url: URL, ofType typeName: String) throws {
        analyzer = try VideoAnalyzer(url: url)
    }

    //MARK: - Analyzer mode

    @IBAction func handleModeMenu(_ sender: NSMenuItem) {
        let tag = sender.tag
        switchMode(tag)
    }

    @IBAction func handleMode(_ sender: NSPopUpButton) {
        if let tag = sender.selectedItem?.tag {
            switchMode(tag)
        }
    }

    func switchMode(_ tag: Int) {
        if tag == 0 {
            analyzer.analyze(.timeAverage(time: CMTime(seconds: 1, preferredTimescale: 1)))
        } else if tag == 1 {
            analyzer.analyze(.gop)
        }
        else {
            analyzer.analyze(.frame)
        }
        chartView.reloadData()
        modePopUp.selectItem(withTag: tag)
    }

    //MARK: - ChartView data source and delegate

    func chartView(_ chartView: ChartView, samplesForResolution: Int) -> [Sample] {
        return analyzer.rescaled(samplesForResolution)
    }

    func numberOfColumnsInChartView(_ chartView: ChartView) -> Int {
        return Int(analyzer.duration.value)
    }

    func numberOfRowsInChartView(_ chartView: ChartView) -> Int {
        return Int(analyzer.maxSize)
    }

    func selectionDidChange(_ chartView: ChartView) {
        let samples = analyzer.samples
        let count = samples.count

        let sampleIndex = Int(chartView.cursorPercent * CGFloat(count))

        if sampleIndex >= 0 && sampleIndex < count {
            let sample = samples[sampleIndex]
            cursorTimeLabel.stringValue = CMTime(value: sample.timeStamp, timescale: analyzer.timescale).durationText
            cursorAvgLabel.stringValue = String(sample.size * 8 / 1000) + " kbps"
        }
    }

}

