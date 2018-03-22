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
    
    var isLoadingThumb = false
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    override func downloadData(for downloadInfo: DownloadInfo) {
        guard !isLoadingThumb else { return }
        XMPPAdapter.downloadData(accountId: downloadInfo.accountId,
                                 chatMsgId: downloadInfo.messageId,
                                 forThumb: downloadInfo.isThumbnail) { (messageId, filePath) in
            EDOMainthread {
                guard
                    let path = filePath,
                    let image = UIImage(contentsOfFile: path) else {
                        self.imageNotFound()
                        return
                }
                
                self.isLoadingThumb = true
                self.updateImage(img: image)
            }
            
            if self.backgroundTask != UIBackgroundTaskInvalid {
                UIApplication.shared.endBackgroundTask(self.backgroundTask)
                self.backgroundTask = UIBackgroundTaskInvalid
            }
        }
    }
    
    private func imageNotFound() {
        self.imageView.contentMode = .center
        self.imageView.image = EdoImageNoCache("image-not-found")
    }
    
    private func updateImage(img: UIImage?) {
        self.imageView.image = img
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.isLoadingThumb = false
        self.imageView.image = nil
    }
}
