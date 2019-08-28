//
//  StatusViewController.swift
//  StoryNotifier
//
//  Created by CenoX on 2017. 1. 12..
//  Copyright © 2017년 Team Vanilla. All rights reserved.
//

import Cocoa

class StatusViewController: NSViewController {
    
    private var updateTag = Int()
    
    @IBOutlet weak private var freq: NSButton!
    @IBOutlet weak private var norm: NSButton!
    @IBOutlet weak private var long: NSButton!
    @IBOutlet weak private var saveButton: NSButton!
    @IBOutlet weak private var logoutButton: NSButton!
    @IBOutlet weak private var versionLabel: NSTextField!
    
    @IBAction private func updateValue(_ sender: NSButton) {
        updateTag = sender.tag
    }
    
    @IBAction private func saveData(_ sender: NSButton) {
        UserDefaults.standard.set(updateTag, forKey: "frequency")
        UserDefaults.standard.synchronize()
        let a = NSAlert()
        a.messageText = "설정을 적용하였습니다"
        a.informativeText = "설정은 다음 실행 때부터 반영됩니다."
        a.addButton(withTitle: "확인")
        a.alertStyle = NSAlert.Style.warning
        
        a.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
    
    @IBAction private func quitApp(_ sender: AnyObject) {
        NSApplication.shared.terminate(sender)
    }
    
    @IBAction private func logout(_sender: NSButton) {
        let a = NSAlert()
        a.messageText = "로그아웃 하시겠습니까?"
        a.informativeText = "모든 어플리케이션의 설정이 지워지며, 다시 로그인하셔야합니다"
        a.addButton(withTitle: "로그아웃")
        a.addButton(withTitle: "취소")
        a.alertStyle = NSAlert.Style.warning
        
        a.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) -> Void in
            if modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn {
                if let bundle = Bundle.main.bundleIdentifier {
                    UserDefaults.standard.removePersistentDomain(forName: bundle)
                    UserDefaults.standard.synchronize()
                }
                self.logoutRequest()
            }
        })
    }
    
    private func logoutRequest() {
        var request = URLRequest(url: URL(string: "https://story.kakao.com/s/logout")!)
        request.httpMethod = "GET"
        request.setValue("https://story.kakao.com", forHTTPHeaderField: "Referer")
        request.setValue("keep-alive", forHTTPHeaderField: "Connetion")
        request.setValue("ko-KR,ko;q=0.8,en-US;q=0.5,en;q=0.3", forHTTPHeaderField: "Accept-Language")
        let session = URLSession.shared.dataTask(with: request) { data, response, error in
            print(String(data: data!, encoding: .utf8) ?? "NO DATA")
            print(response ?? "NO RESPONSE")
            if let reponse = response {
                if reponse.url == URL(string: "https://story.kakao.com/s/login") {
                    let notification = NSUserNotification()
                    notification.title = "로그아웃 완료"
                    notification.subtitle = "이용해 주셔서 감사합니다"
                    notification.soundName = NSUserNotificationDefaultSoundName
                    
                    NSUserNotificationCenter.default.deliver(notification)
                    
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        session.resume()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.versionLabel.stringValue = version
        }
        
        let tag = UserDefaults.standard.integer(forKey: "frequency")
        switch tag {
        case 0:
            self.freq.state = NSControl.StateValue(rawValue: 1)
        case 1:
            self.norm.state = NSControl.StateValue(rawValue: 1)
        case 2:
            self.long.state = NSControl.StateValue(rawValue: 1)
        default:
            break
        }
    }
}
