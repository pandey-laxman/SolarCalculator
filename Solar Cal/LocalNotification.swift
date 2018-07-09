//
//  LocalNotification.swift
//  Solar Cal
//
//  Created by Laxman Pandey on 09/07/18.
//  Copyright © 2018 Laxman Pandey. All rights reserved.
//

import Foundation
import UserNotifications
class LocationNotification: NSObject {
    static let shared = LocationNotification()
    var isPermissionGranted: Bool = false
    private override init() {
    }
    
    func registerNotification(at date: Date, data: LocationData, timezone: TimeZone, completion: @escaping(Bool)->()) {
        guard isPermissionGranted, let title = data.title, let subTitle = data.subtitle else {
            completion(false)
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "Golden Hour Starts"
        content.body = "@\(title),\(subTitle)"
        content.sound = UNNotificationSound.default()
        
        let calendar = Calendar.current
    
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minutes
        dateComponents.second = seconds
        
        
        print(dateComponents)
       let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
       
        let request = UNNotificationRequest(identifier:UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error) in
            if let err = error {
                print(err)
                completion(false)
            }
            completion(true)
            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (notifications) in
                print("num of pending notifications \(notifications.count)")
                
            })
        }
        
    }
     func requestNotifPermission(){
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {[weak self] (granted, error) in
            print("granted: (\(granted)")
            self?.isPermissionGranted = granted
        }
    }
    
}
