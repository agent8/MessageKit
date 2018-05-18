//
//  GifMessageCell.swift
//  Email
//
//  Created by Tan Wei on 4/18/18.
//  Copyright © 2018 Easilydo. All rights reserved.
//

import Foundation

class GifMessageCell: MediaMessageCell {
    
    open override class func reuseIdentifier() -> String { return "messagekit.cell.gifmediamessage" }
    
    override func doDownloadData(for downloadInfo: DownloadInfo, finishedAndDoNotRetry: ((Bool)->())? = nil) {
        guard let _ = EmailDAL.getChatMessage(msgId: downloadInfo.messageId) else {
            finishedAndDoNotRetry?(true) //do not download again
            return
        }
        
        XMPPAdapter.downloadData(accountId: downloadInfo.accountId,
                                 chatMsgId: downloadInfo.messageId) { [weak self] (messageId, filePath) in
                                    EDOMainthread {
                                        if let path = filePath {
                                            let data = try? Data(contentsOf: URL(fileURLWithPath: path))
                                            self?.imageView.animatedImage = FLAnimatedImage(animatedGIFData: data)
                                        }
                                        
                                        finishedAndDoNotRetry?(false)
                                    }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.animatedImage = nil
    }
}
