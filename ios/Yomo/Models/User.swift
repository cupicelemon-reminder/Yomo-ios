//
//  User.swift
//  Yomo
//
//  User profile model
//

import Foundation
import FirebaseFirestore

struct UserProfile: Codable, Identifiable {
    @DocumentID var id: String?
    let displayName: String
    let email: String
    let photoURL: String?
    let createdAt: Timestamp

    enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case email
        case photoURL
        case createdAt
    }
}

struct UserSubscription: Codable {
    let isPro: Bool
    let plan: SubscriptionPlan?
    let expiresAt: Timestamp?

    enum SubscriptionPlan: String, Codable {
        case monthly
        case annual
    }
}

struct Device: Codable, Identifiable {
    @DocumentID var id: String?
    let fcmToken: String
    let platform: DevicePlatform
    let deviceName: String
    let lastActiveAt: Timestamp

    enum DevicePlatform: String, Codable {
        case ios
        case android
    }

    enum CodingKeys: String, CodingKey {
        case id
        case fcmToken
        case platform
        case deviceName
        case lastActiveAt
    }
}
