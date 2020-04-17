//
//  AppDelegate.swift
//  BatteryNotifier
//
//  Created by Ludvig Ellevold on 16/01/2019.
//  Copyright © 2019 Ludvig Ellevold. All rights reserved.
//

import Cocoa
import Foundation
import IOKit.ps
import ServiceManagement

extension Notification.Name {
    static let killLauncher = Notification.Name("killLauncher")
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
    
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    var timer = Timer()
    var capacity = -1
    
    func launchAtStartup() {
        let launcherAppId = "luelProd.Launcher"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppId }.isEmpty
        
        SMLoginItemSetEnabled(launcherAppId as CFString, true)
        
        if isRunning {
            DistributedNotificationCenter.default().post(name: .killLauncher, object: Bundle.main.bundleIdentifier!)
        }
    }


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        launchAtStartup()
        // Insert code here to initialize your application
        
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
        }
        NSUserNotificationCenter.default.delegate = self
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(AppDelegate.startJob(_:)), userInfo: nil, repeats: true)

        constructMenu()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        timer.invalidate()
        
    }
    
    func constructMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit Battery Notifier", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    @objc func startJob(_ sender: Any?) {
        
        if capacity != 100 {
            capacity = getBatteryState()
            print(capacity)
            if capacity == 100 {
                print("Notification")
                let notification = NSUserNotification()
                notification.title = "Battery Notifier"
                notification.subtitle = "Battery is now fully charged"
                notification.informativeText = "Unplug mac from charger to preserve battery life"
                notification.soundName = NSUserNotificationDefaultSoundName
                NSUserNotificationCenter.default.deliver(notification)
            }
        } else {
            capacity = getBatteryState()
            print("Er 100")
        }
    }
    
    func getBatteryState() -> Int{
        var capacity = -1
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        
        for ps in sources {
            let info = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as! [String: AnyObject]
            if let percentage = info[kIOPSCurrentCapacityKey] as? Int{
                capacity = percentage
            }
        }
        return capacity
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
}

