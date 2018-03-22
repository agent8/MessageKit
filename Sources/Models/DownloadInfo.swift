//
//  DownloadInfo.swift
//  Email
//
//  Created by Tan Wei on 3/21/18.
//  Copyright © 2018 Easilydo. All rights reserved.
//

import Foundation

/// An object used to group the information to be used by `MediaMessageCell` and its subclasses.
public struct DownloadInfo {
    
    // MARK: - Properties
    
    public let accountId: String
    public let messageId: String
    public let isThumbnail: Bool
    
    // MARK: - Initializer
    
    public init(accountId: String, messageId: String, isThumbnail: Bool = false) {
        self.accountId = accountId
        self.messageId = messageId
        self.isThumbnail = isThumbnail
    }
}
