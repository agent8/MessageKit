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
        guard let message = EmailDAL.getChatMessage(msgId: downloadInfo.messageId) else {
            finishedAndDoNotRetry?(true) //do not download again
            return
        }
        guard let chatAcct = EmailDAL.getChatAccount(accountId: downloadInfo.accountId) else {
            finishedAndDoNotRetry?(true)
            return
        }
        let mailAcctId = chatAcct.mailAcctId
        
        XMPPAdapter.downloadData(accountId: downloadInfo.accountId,
                                 chatMsgId: downloadInfo.messageId) { (messageId, filePath, _) in
            guard let path = filePath else {
                return
            }

            EDOMainthread {
                if message.bodyType == XMPPConstants.BodyType.Email {
                    if let data = NSData(contentsOfFile: path) as Data? {
                        EDOBGthread {
                            EmailAdapter.convertEmailDataFromChatToEdoMessage(data: data, emailId: messageId, mailAcctId: mailAcctId)
                            BroadcastCenter.postNotification(.NewEmailFetched, information: [.MessageId: messageId])
                        }
                    }
                } else { // File
                    do {
                        let name = URL(fileURLWithPath: path).lastPathComponent
                        let localPath = edoGenerateChatMediaPath(chatAcctId: message.accountId, name: name)
                        if !localPath.isEmpty, !FileManager.default.fileExists(atPath: localPath) {
                            try FileManager.default.copyItem(atPath: message.mediaPath, toPath: localPath) //Copy file from 3rd party app sandbox to local
                        }
                    } catch let err as NSError {
                        ErrorLog("Unable to get information of selected document: \(err)")
                    }
                }
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
