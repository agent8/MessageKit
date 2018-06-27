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
        
        XMPPAdapter.downloadGifThumb(accountId: downloadInfo.accountId,
                                      chatMsgId: downloadInfo.messageId) { [weak self] (msgId, filePath) in
            EDOMainthread {
                guard
                    self?.messageId == msgId,
                    self?.imageView.animatedImage == nil else {
                        finishedAndDoNotRetry?(false)
                        return
                }
                
                if let path = filePath,
                    let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                    let gif = FLAnimatedImage(animatedGIFData: data) {
                    self?.imageView.animatedImage = gif
                }
            }
        }
        
        XMPPAdapter.downloadData(accountId: downloadInfo.accountId,
                                 chatMsgId: downloadInfo.messageId) { [weak self] (msgId, filePath, _) in
            EDOMainthread {
                defer {
                    finishedAndDoNotRetry?(false)
                }
                
                guard self?.messageId == msgId else {
                        return
                }
                
                if let path = filePath,
                    let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                    let gif = FLAnimatedImage(animatedGIFData: data) {
                        self?.imageView.animatedImage = gif
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        EDOMainthread {
            self.imageView.animatedImage = nil
        }
    }
}
