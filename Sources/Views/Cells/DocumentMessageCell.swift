//
//  DocumentMessageCell.swift
//  Email
//
//  Created by Shuhao Zhang on 3/26/18.
//  Copyright © 2018 Easilydo. All rights reserved.
//

import Foundation

class DocumentMessageCell: MediaMessageCell {
    open override class func reuseIdentifier() -> String { return "messagekit.cell.attachmentmessage" }
    private var attachmentView: ChatDocumentView?
    
    override func doDownloadData(for downloadInfo: DownloadInfo, finishedAndDoNotRetry: ((Bool)->())? = nil) {
        guard let _ = EmailDAL.getChatMessage(msgId: downloadInfo.messageId) else {
            finishedAndDoNotRetry?(true) //do not download again
            return
        }
        guard let chatAcct = EmailDAL.getChatAccount(accountId: downloadInfo.accountId) else {
            finishedAndDoNotRetry?(true)
            return
        }
        let mailAcctId = chatAcct.mailAcctId
        
        XMPPAdapter.downloadData(accountId: downloadInfo.accountId,
                                 chatMsgId: downloadInfo.messageId) { (messageId, filePath) in
            if let path = filePath,
                let data = NSData(contentsOfFile: path) as Data? {
                EmailAdapter.convertEmailDataFromChatToEdoMessage(data: data, emailId: messageId, mailAcctId: mailAcctId)
                BroadcastCenter.postNotification(.NewEmailFetched, information: [.MessageId: messageId])
            }
            
            EDOMainthread {
                finishedAndDoNotRetry?(false)
            }
        }
    }
    
    open func load(attachment: ChatAttachment, isOutgoing: Bool) {
        let documentView = ChatDocumentView(attachment: attachment)
        documentView.translatesAutoresizingMaskIntoConstraints = false
        messageContainerView.addSubview(documentView)
        
        NSLayoutConstraint.activate([
            // padding to account for the gap between start of message bubble PNG to actual bubble background
            documentView.widthAnchor.constraint(equalTo: messageContainerView.widthAnchor, constant: -5.5),
            documentView.heightAnchor.constraint(equalTo: messageContainerView.heightAnchor),
            documentView.topAnchor.constraint(equalTo: messageContainerView.topAnchor)
        ])
        
        if isOutgoing {
            documentView.leftAnchor.constraint(equalTo: messageContainerView.leftAnchor).isActive = true
        } else {
            documentView.rightAnchor.constraint(equalTo: messageContainerView.rightAnchor).isActive = true
        }
        
        attachmentView = documentView
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        attachmentView?.removeFromSuperview()
        attachmentView = nil
    }
}
