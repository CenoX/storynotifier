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
    
    func getDate() -> Date {
        let dateStr = self.replacingOccurrences(of: "T", with: " ").replacingOccurrences(of: "Z", with: "")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let date = dateFormatter.date(from: dateStr)
        return date!
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
    
    func getURLWith(FileName name: String) -> URL {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("StoryNotifier").appendingPathComponent(name)
        return url
    }
    
}
