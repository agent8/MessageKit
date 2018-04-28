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
                                        var hasNonRecoverableError = false
                                        if messageId == self.messageId {
                                            if let path = filePath,
                                                let image = UIImage(contentsOfFile: path) {
                                                self.updateImage(img: image)
                                            } else {
                                                self.imageNotFound()
                                                if self.hasNonRecoverableError() {
                                                    //TODO: find out if there is a non-recoverable error
                                                    hasNonRecoverableError = true
                                                }
                                            }
                                        } else {
                                            XMPPMgrLog("image is no longer needed")
                                        }
                                        
                                        finishedAndDoNotRetry?(hasNonRecoverableError)
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
            //czy：当收到长图片的时候，进行裁剪，以免图片显示被压缩
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        //czy：当收到长图片的时候，进行裁剪，以免图片显示被压缩
//        imageView.contentMode = .scaleToFill
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }
}
