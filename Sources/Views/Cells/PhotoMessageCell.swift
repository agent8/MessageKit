//
//  PhotoMessageCell.swift
//  Email
//
//  Created by Tan Wei on 3/21/18.
//  Copyright © 2018 Easilydo. All rights reserved.
//

import UIKit

class PhotoMessageCell: MediaMessageCell {
    
    open override class func reuseIdentifier() -> String { return "messagekit.cell.photomediamessage" }
    
    override func doDownloadData(for downloadInfo: DownloadInfo, finishedAndDoNotRetry:((Bool)->())? = nil) {
        XMPPAdapter.downloadData(accountId: downloadInfo.accountId,
                                 chatMsgId: downloadInfo.messageId,
                                 forThumb: downloadInfo.isThumbnail) { (messageId, filePath) in
                                    EDOMainthread {
                                        var hasNonRecoveraleError = false
                                        if messageId == self.messageId {
                                            if let path = filePath,
                                                let image = UIImage(contentsOfFile: path) {
                                                self.updateImage(img: image)
                                            } else {
                                                self.imageNotFound()
                                                if self.hasNonRecoverableError() {
                                                    //TODO: find out if there is a non-recoverable error
                                                    hasNonRecoveraleError = true
                                                }
                                            }
                                        } else {
                                            XMPPMgrLog("image is no longer needed")
                                        }
                                        
                                        finishedAndDoNotRetry?(hasNonRecoveraleError)
                                    }
                                    //Preload the full image, no callback needed
                                    XMPPAdapter.downloadData(accountId: downloadInfo.accountId, chatMsgId: downloadInfo.messageId)
        }
    }

    private func imageNotFound() {
        imageView.contentMode = .center
        imageView.image = EdoImageNoCache("image-not-found")
    }
    
    private func updateImage(img: UIImage?) {
        imageView.image = img
        if img != nil {
            imageView.fadeIn(0.5)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        imageView.contentMode = .scaleToFill
    }
}
