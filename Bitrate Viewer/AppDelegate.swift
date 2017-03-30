//
//  AppDelegate.swift
//  Bitrate Viewer
//
//  Created by Damiano Galassi on 02/06/16.
//  Copyright © 2016 Damiano Galassi. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}
