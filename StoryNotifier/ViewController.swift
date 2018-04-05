//
//  ViewController.swift
//  StoryNotifier
//
//  Created by CenoX on 2016. 12. 29..
//  Copyright © 2016년 Team Vanilla. All rights reserved.
//

import Cocoa
import Sparkle

extension String {
    func convertFromHTML() -> String {
        guard let encodedData = self.data(using: .utf8) else {
            return self
        }
        let attributedOptions: [String : Any] = [
            NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
            NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue
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

class ViewController: NSViewController, NSUserNotificationCenterDelegate {
    
    let loginURL = URL(string: "https://accounts.kakao.com/weblogin/authenticate")!
    let notificationURL = URL(string: "https://story.kakao.com/a/notifications")!
    
    private var cookies = [HTTPCookie]()
    
    private var lastNotificationDate = Date()
    private var notifications = [KakaoNotification]()
    private var receivedNotification = [String]()
    
    private var alertTimer = Timer()
    
    private let encryptKey = "cenoxStoryNotifierProject"
    
    @IBOutlet weak private var idTextField: NSTextField!
    @IBOutlet weak private var passwordTextField: NSTextField!
    @IBOutlet weak private var loginButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if UserDefaults.standard.bool(forKey: "autoLogin") {
            do {
                let encryptedData = try Data(contentsOf: Lib.getURLWith(FileName: "autoLoginData"))
                let decrypted = Crypto.aes256Decrypt(withKey: self.encryptKey, data: encryptedData)
                print("START SESSION")
                self.processRequest(with: decrypted)
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    @IBAction private func login(sender: NSButton) {
        print(idTextField.stringValue, passwordTextField.stringValue)
        if idTextField.stringValue.isValidEmail() {
            let dataString = "email=\(idTextField.stringValue)&password=\(passwordTextField.stringValue)"
            let data = dataString.data(using: .utf8)
            let encryptedData = Crypto.aes256Encrypt(withKey: encryptKey, data: data)
            do {
                try encryptedData?.write(to: Lib.getURLWith(FileName: "autoLoginData"))
                print("ENCRYPED DATA WROTE.")
            } catch let error {
                print(error.localizedDescription)
            }
            self.processRequest(with: data)
        } else {
            let a = NSAlert()
            a.messageText = "올바른 이메일 형식으로 입력하세요."
            a.addButton(withTitle: "확인")
            a.alertStyle = NSAlertStyle.warning
            a.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) -> Void in
                if modalResponse == NSAlertFirstButtonReturn {
                    print("UserDefaults autoLogin -> false, Login Failed.")
                    UserDefaults.standard.set(false, forKey: "autoLogin")
                    UserDefaults.standard.synchronize()
                }
            })
        }
    }
    
    private func processRequest(with data: Data?) {
        var request = URLRequest(url: self.loginURL)
        request.httpMethod = "POST"
        request.httpBody = data
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("https://story.kakao.com/s/login", forHTTPHeaderField: "Referer")
        request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_3) AppleWebKit/604.5.6 (KHTML, like Gecko) Version/11.0.3 Safari/604.5.6", forHTTPHeaderField: "user-agent")
        request.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "")
        request.addValue("Accept-Language", forHTTPHeaderField: "ko-kr,ko;q=0.8,en-us;q=0.5,en;q=0.3")
        request.setValue("web:d;-;-", forHTTPHeaderField: "X-Kakao-DeviceInfo")
        request.addValue("accounts.kakao.com", forHTTPHeaderField: "Host")
        request.addValue("1", forHTTPHeaderField: "Upgrade-Insecure-Requests")
        
        let session = URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let _data = data {
                if let str = String(data: _data, encoding: .utf8) {
                    let bodyString = str.components(separatedBy: "<body>")[1].components(separatedBy: "</body>")[0].convertFromHTML()
                    print(bodyString)
                    if let jsonData = try? JSONSerialization.jsonObject(with: bodyString.data(using: .utf8)!, options: []) {
                        print(jsonData)
                        if let status = (jsonData as! NSDictionary).object(forKey: "status") as? Int {
                            if status == 0 {
                                print("LOGIN SUCCESS")
                                self.loginSuccess()
                            } else {
                                print("LOGIN FAILED")
                                self.loginFailed(dict: jsonData as! NSDictionary)
                            }
                        } else {
                            print("CANNOT LOGIN")
                        }
                    } else {
                        print("Unable to make JSON Object")
                    }
                }
            } else {
                print("Cannot wrap optinal data.")
            }
        }
        session.resume()
    }
    
    private func loginFailed(dict: NSDictionary) {
        DispatchQueue.main.async {
            let a = NSAlert()
            a.messageText = "로그인 실패"
            let status = dict.object(forKey: "status") as! Int
            let message = dict.object(forKey: "message") as! String
            a.informativeText = "오류코드: \(status), 메세지: \(message)\n"
            a.addButton(withTitle: "확인")
            a.alertStyle = NSAlertStyle.warning
            a.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) -> Void in
                if modalResponse == NSAlertFirstButtonReturn {
                    print("UserDefaults autoLogin -> false, Login Failed.")
                    UserDefaults.standard.set(false, forKey: "autoLogin")
                    UserDefaults.standard.synchronize()
                }
            })
        }
    }
    private func loginSuccess() {
        DispatchQueue.main.async {
            if UserDefaults.standard.bool(forKey: "autoLogin") {
                self.view.window?.close()
                let notification = NSUserNotification()
                notification.title = "Story Notifier"
                notification.subtitle = "자동 로그인 성공"
                notification.informativeText = "자동 로그인이 활성화되어 로그인되었습니다."
                notification.soundName = NSUserNotificationDefaultSoundName
                
                NSUserNotificationCenter.default.deliver(notification)
            } else {
                let a = NSAlert()
                a.messageText = "로그인 성공"
                a.informativeText = "자동 로그인을 활성화할까요?"
                a.addButton(withTitle: "활성화")
                a.addButton(withTitle: "하지 않음")
                a.alertStyle = NSAlertStyle.warning
                if a.runModal() == NSAlertFirstButtonReturn {
                    print("UserDefaults autoLogin -> true")
                    UserDefaults.standard.set(true, forKey: "autoLogin")
                    UserDefaults.standard.synchronize()
                    self.view.window?.close()
                } else {
                    print("UserDefaults autoLogin -> false")
                    UserDefaults.standard.set(false, forKey: "autoLogin")
                    UserDefaults.standard.synchronize()
                    self.view.window?.close()
                }
                /*a.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) -> Void in
                    if modalResponse == NSAlertFirstButtonReturn {
                        
                    } else {
                        
                    }
                })*/
            }
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
    
    func receiveAlert() {
        var request = URLRequest(url: URL(string: "https://story.kakao.com/a/notifications")!)
        request.httpMethod = "GET"
        request.setValue("story.kakao.com", forHTTPHeaderField: "Host")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_3) AppleWebKit/604.5.6 (KHTML, like Gecko) Version/11.0.3 Safari/604.5.6", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("ko", forHTTPHeaderField: "Accept-Language")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue("41", forHTTPHeaderField: "X-Kakao-ApiLevel")
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
        if let jsonData = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)  {
            if let notifications = jsonData as? NSArray {
                for notification in notifications {
                    if let data = notification as? NSDictionary {
                        let createdTime = data.object(forKey: "created_at") as! String
                        if  let message = data.object(forKey: "message") as? String,
                            let id = data.object(forKey: "id") as? String,
                            var scheme = data.object(forKey: "scheme") as? String {
                            
                            let commentID = data.object(forKey: "comment_id") as? String
                            let content = data.object(forKey: "content") as? String
                            
                            if scheme.contains("kakaostory://activities/") {
                                let str = scheme.components(separatedBy: "kakaostory://activities/")[1]
                                let nID = str.components(separatedBy: ".")[0]
                                let nValue = str.components(separatedBy: ".")[1]
                                scheme = "\(nID)/\(nValue)"
                            } else {
                                scheme = ""
                            }
                            
                            let notification = KakaoNotification(id: id, createdTime: Lib.getDate(from: createdTime), commentID: commentID, content: content, message: message, scheme: scheme)
                            
                            self.notifications.append(notification)
                        }
                    }
                }
                self.notifications.sort(by: {$0.createdTime < $1.createdTime})
                if self.notifications.last!.createdTime != self.lastNotificationDate {
                    self.lastNotificationDate = self.notifications.last!.createdTime
                    if !self.receivedNotification.contains(self.notifications.last!.id) {
                        self.makeNotification()
                    }
                }
            }
        }
    }
    
    private func makeNotification() {
        let kNotification = self.notifications.last!
        let notification = NSUserNotification()
        notification.title = "카카오스토리"
        let message = kNotification.message
        if let content = kNotification.content {
            notification.informativeText = content
        }
        notification.subtitle = message
        notification.userInfo = ["URLComponent":kNotification.scheme]
        notification.soundName = NSUserNotificationDefaultSoundName
        notification.setValue(true, forKey: "_showsButtons")
        notification.hasActionButton = true
        notification.actionButtonTitle = "보기"
        
        NSUserNotificationCenter.default.deliver(notification)
        NSUserNotificationCenter.default.delegate = self
        self.receivedNotification.append(kNotification.id)
    }
        
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        let component = notification.userInfo!["URLComponent"] as! String
        let storyURL = URL(string: "https://story.kakao.com/\(component)")
        print("NotiURL: \(storyURL)")
        if let url = storyURL, NSWorkspace.shared().open(url) {
            print("default browser was successfully opened")
        }
    }
    
}
