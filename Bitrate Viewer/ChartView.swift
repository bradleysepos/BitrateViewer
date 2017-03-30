//
//  ChartView.swift
//  Bitrate Viewer
//
//  Created by Damiano Galassi on 02/06/16.
//  Copyright © 2016 Damiano Galassi. All rights reserved.
//

import Cocoa

public protocol ChartViewDataSource: class {
    func chartView(_ chartView: ChartView, samplesForResolution: Int) -> [Sample]
    func numberOfColumnsInChartView(_ chartView: ChartView) -> Int
    func numberOfRowsInChartView(_ chartView: ChartView) -> Int
}

public protocol ChartViewDelegate: class {
    func selectionDidChange(_ chartView: ChartView)
}

public class ChartView: NSView {

    private var duration: CGFloat = 0
    private var maxSize: CGFloat = 0
    private var samples = [Sample]()

    private let cursor = CALayer()
    private let info = CALayer()

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonSetup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonSetup()
    }

    public override var acceptsFirstResponder: Bool {
        get {
            return true
        }
    }

    private func commonSetup() {
        wantsLayer = true

        let trackingArea = NSTrackingArea(rect: bounds,
                                          options: [NSTrackingAreaOptions.activeInKeyWindow, NSTrackingAreaOptions.inVisibleRect, NSTrackingAreaOptions.mouseMoved],
                                          owner: self, userInfo: nil)
        addTrackingArea(trackingArea)

        cursor.anchorPoint = CGPoint(x: 0.5, y: 0)
        cursor.bounds = CGRect(x: 0, y: 0, width: 2, height: bounds.height)
        cursor.backgroundColor = cursorColor.cgColor
        cursor.opacity = 0.7
        cursor.actions = ["position": NSNull(),
                          "bounds": NSNull()]

        layer?.addSublayer(cursor)
    }

    // MARK: - Delegate

    public weak var delegate: ChartViewDelegate?

    // MARK: - Data source

    public weak var dataSource: ChartViewDataSource? {
        didSet {
            reloadData()
        }
    }

    public func reloadData() {
        if let dataSource = dataSource {
            samples = dataSource.chartView(self, samplesForResolution: Int(bounds.width))
            duration = CGFloat(dataSource.numberOfColumnsInChartView(self))
            maxSize = CGFloat(dataSource.numberOfRowsInChartView(self))
        }
        if let delegate = delegate {
            delegate.selectionDidChange(self)
        }
        needsDisplay = true
    }

    // MARK: - Cursor

    public var cursorPercent: CGFloat {
        get {
            return cursorPosition / bounds.size.width
        }
    }

    private var cursorPosition: CGFloat = 0 {
        didSet {
            cursor.position = CGPoint(x: cursorPosition, y: 0)

            if let delegate = delegate {
                delegate.selectionDidChange(self)
            }
        }
    }

    public override func mouseMoved(with theEvent: NSEvent) {
        let point = theEvent.locationInWindow
        let convertedPoint = convert(point, from: self.window?.contentView)

        cursorPosition = convertedPoint.x
    }

    public override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)

        let size = CGSize(width: cursor.bounds.width, height: newSize.height)
        cursor.bounds = CGRect(origin: cursor.position, size: size)
    }

    // MARK: - Draw

    private let chartColor = NSColor(calibratedRed: 0.458824, green:0.372549, blue:1.0, alpha:1.0)
    private let cursorColor = NSColor(calibratedRed:0.980392, green:0.741176, blue:0.364706, alpha:1.0)

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.white.set()
        NSBezierPath(rect: dirtyRect).fill()

        drawHistogram(dirtyRect)
        drawGrid(dirtyRect)
    }

    private func drawHistogram(_ dirtyRect: NSRect) {
        guard self.maxSize > 0 else {
            return
        }
        NSGraphicsContext.saveGraphicsState()

        let height = bounds.height
        let width = bounds.width

        chartColor.set()

        var currentX = CGFloat(0)

        for sample in samples {
            let sampleHeight = CGFloat(sample.size) / maxSize * height
            let sampleWidth = CGFloat(sample.duration) / duration * width

            let rect = NSRect(x: floor(currentX), y: 0, width: ceil(sampleWidth), height: sampleHeight)
            NSBezierPath(rect: rect).fill()

            currentX += sampleWidth
        }

        NSGraphicsContext.restoreGraphicsState()
    }

    /// Draw a line each kb
    private func drawGrid(_ dirtyRect: NSRect) {
        guard self.maxSize > 0 else {
            return
        }
        NSGraphicsContext.saveGraphicsState()

        let height = bounds.height
        let width = bounds.width

        let step = { () -> Int in
            let step = Int(1000 * 1000 / 8 / self.maxSize * height)
            return step < 1 ? 1 : step
        }()

        NSColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 0.5).set()

        let path = NSBezierPath()
        let pattern: [CGFloat] = [4.0, 4.0]
        path.setLineDash(pattern, count: 2, phase: 0.0)
        path.lineWidth = 1

        for index in stride(from: step, to: Int(height), by: step) {
            path.move(to: NSPoint(x: 0, y: CGFloat(index) + 0.5))
            path.line(to: NSPoint(x: width, y: CGFloat(index) + 0.5))
            path.stroke()
        }

        NSGraphicsContext.restoreGraphicsState()
    }
}
