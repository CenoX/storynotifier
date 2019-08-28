//
//  Lib.swift
//  StoryNotifier
//
//  Created by CenoX on 2016. 12. 29..
//  Copyright © 2016년 Team Vanilla. All rights reserved.
//

import Cocoa

class Lib: NSObject {
    
    static func makeFolderToApplicationSupport() {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let vanilla = appSupportURL.appendingPathComponent("StoryNotifier")
        if !FileManager.default.fileExists(atPath: vanilla.path) {
            print("Creating folder")
            do {
                try FileManager.default.createDirectory(at: vanilla, withIntermediateDirectories: false, attributes: nil)
                print("Done.")
            } catch let error as NSError {
                print("Error while creating folder.", error.localizedDescription)
            }
        }
    }
    
    static func getURLWith(FileName name: String) -> URL {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("StoryNotifier").appendingPathComponent(name)
        return url
    }
    
    static func getDate(from dateString: String) -> Date {
        let dateStr = dateString.replacingOccurrences(of: "T", with: " ").replacingOccurrences(of: "Z", with: "")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let date = dateFormatter.date(from: dateStr)
        return date!
    }
    
}
