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
    var messageId = ""
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        BroadcastCenter.addObserver(self, selector: #selector(self.appWillEnterBackground(noti:)), notification: .AppPrepareEnterBackground)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        BroadcastCenter.removeObserver(self)
    }
    
    override func downloadData(for downloadInfo: DownloadInfo) {
        guard !isLoadingThumb else { return }
        messageId = downloadInfo.messageId
        XMPPAdapter.downloadData(accountId: downloadInfo.accountId,
                                 chatMsgId: downloadInfo.messageId,
                                 forThumb: downloadInfo.isThumbnail) { (messageId, filePath) in
            EDOMainthread {
                guard messageId == self.messageId else {
                    XMPPMgrLog("image is no longer needed")
                    return
                }
                
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
    
    @objc func appWillEnterBackground(noti:Notification) {
        if isLoadingThumb {
            backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                UIApplication.shared.endBackgroundTask(self.backgroundTask)
                NMLog("backgroundTask expired")
                self.backgroundTask = UIBackgroundTaskInvalid
            })
        }
    }
    
    private func imageNotFound() {
        imageView.contentMode = .center
        imageView.image = EdoImageNoCache("image-not-found")
    }
    
    private func updateImage(img: UIImage?) {
        imageView.image = img
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        messageId = ""
        imageView.image = nil
        imageView.contentMode = .scaleToFill
        isLoadingThumb = false
    }
}
