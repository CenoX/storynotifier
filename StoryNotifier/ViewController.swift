//
//  ViewController.swift
//  StoryNotifier
//
//  Created by CenoX on 2016. 12. 29..
//  Copyright © 2016년 Team Vanilla. All rights reserved.
//

import Cocoa
import Sparkle
import WebKit

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

class ViewController: NSViewController, NSUserNotificationCenterDelegate, WebFrameLoadDelegate, WebPolicyDelegate {
    
    let loginURL = URL(string: "https://accounts.kakao.com/weblogin/authenticate")!
    let webViewURL = URL(string: "https://accounts.kakao.com/weblogin/main_captcha?continue=https%3A%2F%2Fstory.kakao.com")!
    let notificationURL = URL(string: "https://story.kakao.com/a/notifications")!
    
    private var cookies = [HTTPCookie]()
    
    private var lastNotificationDate = Date()
    private var _notifications = [KakaoNotification]()
    private var _receivedNotification = [String]()
    
    private var notifications = [KakaoStoryNotification]()
    private var lastNotification: KakaoStoryNotification?
    
    private var alertTimer = Timer()
    
    private let encryptKey = "cenoxStoryNotifierProject"
    
    @IBOutlet var webView: WebView!
    @IBOutlet weak private var loginButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        webView.frameLoadDelegate = self
        webView.policyDelegate = self
        DispatchQueue.main.async {
            self.webView.mainFrame.load(URLRequest(url: self.webViewURL))
        }
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    @IBAction private func login(sender: NSButton) {
        print(webView.mainFrameURL)
    }
    
    func webView(_ sender: WebView!, didStartProvisionalLoadFor frame: WebFrame!) {
        print(webView.mainFrameURL)
    }
    
    func webView(_ sender: WebView!, didFinishLoadFor frame: WebFrame!) {
        if webView.mainFrameURL == "https://story.kakao.com/" {
            print(webView.mainFrameURL)
            self.view.window?.close()
            self.startReceiveAlert()
        }
    }
    
    private func startReceiveAlert() {
        let timeInterval: Double
        if !UserDefaults.standard.bool(forKey: "frequencySet") {
            print("No frequency set. Adjusting to default frequency. Frequency: 5s")
            UserDefaults.standard.set(true, forKey: "frequencySet")
            UserDefaults.standard.set(1, forKey: "frequency")
            UserDefaults.standard.synchronize()
            timeInterval = 5.0
        } else {
            let tag = UserDefaults.standard.integer(forKey: "frequency")
            switch tag {
            case 0:
                print("Frequency: 3s")
                timeInterval = 3.0
            case 1:
                print("Frequency: 5s")
                timeInterval = 5.0
            case 2:
                print("Frequency: 7s")
                timeInterval = 7.0
            default:
                print("Unknown tag value. Value: \(tag)")
                print("Set to default frequency. Frequency: 5s")
                timeInterval = 5.0
            }
        }
        print("Hiding dock icon.")
        NSApp.setActivationPolicy(.prohibited)
        self.alertTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(ViewController.receiveAlert), userInfo: nil, repeats: true)
    }
    
    @objc func receiveAlert() {
        var request = URLRequest(url: URL(string: "https://story.kakao.com/a/notifications")!)
        request.httpMethod = "GET"
        request.setValue("story.kakao.com", forHTTPHeaderField: "Host")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_3) AppleWebKit/602.4.8 (KHTML, like Gecko) Version/10.0.3 Safari/602.4.8", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("ko", forHTTPHeaderField: "Accept-Language")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue("34", forHTTPHeaderField: "X-Kakao-ApiLevel")
        request.setValue("web:d;-;-", forHTTPHeaderField: "X-Kakao-DeviceInfo")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue("https://story.kakao.com", forHTTPHeaderField: "Referer")
        self.notifications.removeAll()
        let session = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                self.processAlert(with: data)
            }
        }
        session.resume()
    }
    
    private func processAlert(with data: Data) {
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let storyNotifications = try decoder.decode([KakaoStoryNotification].self, from: data)
            if let lastValue = storyNotifications.first {
                print(lastValue)
                if lastNotification == nil {
                    makeNotification(with: lastValue)
                } else if lastValue.id != lastNotification?.id {
                    makeNotification(with: lastValue)
                }
            }
        } catch let error {
            print(error)
        }
        
        
//        if let jsonData = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)  {
//            print(jsonData)
//            if let notifications = jsonData as? NSArray {
//                for notification in notifications {
//                    if let data = notification as? NSDictionary {
//                        let createdTime = data.object(forKey: "created_at") as! String
//                        if  let message = data.object(forKey: "message") as? String,
//                            let id = data.object(forKey: "id") as? String,
//                            var scheme = data.object(forKey: "scheme") as? String {
//
//                            let commentID = data.object(forKey: "comment_id") as? String
//                            let content = data.object(forKey: "content") as? String
//
//                            if scheme.contains("kakaostory://activities/") {
//                                let str = scheme.components(separatedBy: "kakaostory://activities/")[1]
//                                let nID = str.components(separatedBy: ".")[0]
//                                let nValue = str.components(separatedBy: ".")[1]
//                                scheme = "\(nID)/\(nValue)"
//                            } else {
//                                scheme = ""
//                            }
//
//                            let notification = KakaoNotification(id: id, createdTime: Lib.getDate(from: createdTime), commentID: commentID, content: content, message: message, scheme: scheme)
//
//                            self.notifications.append(notification)
//                        }
//                    }
//                }
//                self.notifications.sort(by: {$0.createdTime < $1.createdTime})
//                if self.notifications.last!.createdTime != self.lastNotificationDate {
//                    self.lastNotificationDate = self.notifications.last!.createdTime
//                    if !self.receivedNotification.contains(self.notifications.last!.id) {
//                        self.makeNotification()
//                    }
//                }
//            }
//        }
    }
    
    private func makeNotification(with storyNoti: KakaoStoryNotification) {
        let notification = NSUserNotification()
        notification.title = "카카오스토리"
        let message = storyNoti.message
        notification.informativeText = storyNoti.content
        notification.subtitle = message
        notification.userInfo = ["URLComponent":storyNoti.schemeEdit()]
        notification.soundName = NSUserNotificationDefaultSoundName
        notification.setValue(true, forKey: "_showsButtons")
        notification.hasActionButton = true
        notification.actionButtonTitle = "보기"
        
        NSUserNotificationCenter.default.deliver(notification)
        NSUserNotificationCenter.default.delegate = self
        
        lastNotification = storyNoti
    }
        
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        let component = notification.userInfo!["URLComponent"] as! String
        let storyURL = URL(string: "https://story.kakao.com/\(component)")
        if let url = storyURL, NSWorkspace.shared.open(url) {
            print("default browser was successfully opened")
        }
    }
    
}
