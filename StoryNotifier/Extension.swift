//
//  Extension.swift
//  StoryNotifier
//
//  Created by cenox on 2019/08/28.
//  Copyright © 2019 Team Vanilla. All rights reserved.
//

import Foundation
import Cocoa

extension String {
    func convertFromHTML() -> String {
        guard let encodedData = self.data(using: .utf8) else {
            return self
        }
        let attributedOptions: [NSAttributedString.DocumentReadingOptionKey : Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        do {
            let attributedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
            return attributedString.string
        } catch {
            print("Error: \(error)")
            return self
        }
    }
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }
}

extension NSApplication {
    func relaunch(_ sender: AnyObject?) {
        let task = Process()
        // helper tool path
        task.launchPath = Bundle.main.path(forResource: "relaunch", ofType: nil)!
        // self PID as a argument
        task.arguments = [String(ProcessInfo.processInfo.processIdentifier)]
        task.launch()
    }
}

extension FileManager {
    func createApplicationSupport() {
        let appSupportURL = self.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let vanilla = appSupportURL.appendingPathComponent("StoryNotifier")
        if !self.fileExists(atPath: vanilla.path) {
            print("Creating folder")
            do {
                try self.createDirectory(at: vanilla, withIntermediateDirectories: false, attributes: nil)
                print("Done.")
            } catch let error as NSError {
                print("Error while creating folder.", error.localizedDescription)
            }
        }
    }
}
