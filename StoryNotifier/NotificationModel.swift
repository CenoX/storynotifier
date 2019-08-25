//
//  NotificationModel.swift
//  StoryNotifier
//
//  Created by cenox on 2019/08/26.
//  Copyright © 2019 Team Vanilla. All rights reserved.
//

import Foundation

struct KakaoStoryNotification: Decodable, Equatable {
    
    var id: String
    var createdTime: Date
    var commentID: String?
    var content: String?
    var message: String
    var scheme: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case createdTime = "created_at"
        case commentID = "comment_id"
        case content
        case message
        case scheme
    }
    
    func schemeEdit() -> String {
        if scheme.contains("kakaostory://activities/") {
            let str = scheme.components(separatedBy: "kakaostory://activities/")[1]
            let nID = str.components(separatedBy: ".")[0]
            let nValue = str.components(separatedBy: ".")[1]
            return "\(nID)/\(nValue)"
        } else {
            return ""
        }
    }
    
    static func == (lhs: KakaoStoryNotification, rhs: KakaoStoryNotification) -> Bool {
        return lhs.createdTime == rhs.createdTime
    }
    
}
