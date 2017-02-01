//
//  main.swift
//  relaunch
//
//  Created by CenoX on 2017. 1. 12..
//  Copyright © 2017년 Team Vanilla. All rights reserved.
//

import Foundation
import Cocoa
import AppKit

// KVO helper
class Observer: NSObject {
    
    let _callback: () -> Void
    
    init(callback: @escaping () -> Void) {
        _callback = callback
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        _callback()
    }
}

// main
autoreleasepool {
    
    // the application pid
    //    let parentPID = atoi(C_ARGV[1])
    var c = 0
    for arg in CommandLine.arguments {
        print("argument \(c) is: \(arg)")
        c += 1
    }
    let parentPID = Int32(CommandLine.arguments[1])
    print("parentPID: \(parentPID)")
    
    if parentPID == nil {
        fatalError("FUCKING PID IS NIL!!!!")
    }
    
    // get the application instance
    if let app = NSRunningApplication(processIdentifier: parentPID!) {
        
        // application URL
        let bundleURL = app.bundleURL!
        print("bundleURL: \(bundleURL)")
        
        // terminate() and wait terminated.
        let listener = Observer { CFRunLoopStop(CFRunLoopGetCurrent()) }
        app.addObserver(listener, forKeyPath: "isTerminated", options: .new, context: nil)
        print("Observer: terminating")
        
        app.terminate()
        CFRunLoopRun() // wait KVO notification
        app.removeObserver(listener, forKeyPath: "isTerminated", context: nil)
        print("Observer: terminated")
        
        // relaunch
        print("Relaunching")
        do {
            try NSWorkspace.shared().launchApplication(at: bundleURL, options: .newInstance, configuration: [:])
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
}
