//
//  VoiceMessageCell.swift
//  Email
//
//  Created by cccc on 2018/5/24.
//  Copyright © 2018年 Easilydo. All rights reserved.
//

import UIKit

open class VoiceMessageCell: MessageCollectionViewCell {
    open override class func reuseIdentifier() -> String { return "messagekit.cell.voicemessage" }
    
    // MARK: - Properties
    
    var messageId = ""
    var isDownloadingData = false
    var giveUpRetry = false //if true, there is non-recoverable error, do not download data again
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var duration = 0
    var vociePlayed = false
    
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
    

    open lazy var voiceImageView: UIImageView = {
        let voiceImageView = UIImageView()
        voiceImageView.translatesAutoresizingMaskIntoConstraints = false
        return voiceImageView
    }()
    
//    open lazy var voiceTimeView: UILabel = {
//        let voiceTimeView = UILabel()
////        voiceTimeView.text = "0s"
//        voiceTimeView.translatesAutoresizingMaskIntoConstraints = false
//        return voiceTimeView
//    }()

    open var imageView = UIImageView()


    // MARK: - Methods

    open func setupConstraints() {
        voiceImageView.rightInSuperview(-5)
        voiceImageView.constraint(equalTo: CGSize(width: 35, height: 35))
        
//        voiceTimeView.leftInSuperview(5)
//        voiceTimeView.constraint(equalTo: CGSize(width: 35, height: 35))
        
    }

    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.stackView.addArrangedSubview(imageView)
        imageView.addSubview(voiceImageView)
//        imageView.addSubview(voiceTimeView)
        setupConstraints()
    }

    func changeVoicePlayed(voicePlay : Bool) {
        if !voicePlay {
            self.voicePlayView.isHidden = false
        } else {
            self.voicePlayView.isHidden = true
        }
    }

    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        switch message.data {
        case .audio(let data):
            vociePlayed = data.voicePlayed
            if !vociePlayed {
                self.voicePlayView.isHidden = false
            } else {
                self.voicePlayView.isHidden = true
            }
            duration = data.duration
            super.voiceTimeView.text = "\(data.duration)s"
            super.voiceTimeView.textColor = UIColor.lightGray
            if let msg = message as? EdisonMessage {
                if isEmpty(msg.mediaPath) {
                    if let loading = loadingView() {
                        loading.startAnimating()
                    } else {
                        let loading = UIActivityIndicatorView(activityIndicatorStyle: .gray)
                        loading.frame = self.accessoryView.bounds
                        self.accessoryView.addSubview(loading)
                        loading.startAnimating()
                    }
                    downloadData(for: DownloadInfo(accountId: msg.accountId, messageId: msg.messageId))
                }
            }

            var isOwn = false
            if let bool = messagesCollectionView.messagesDataSource?.isFromCurrentSender(message: message) {
                isOwn = bool
            }
            if isOwn {
                voiceImageView.image = EdoImageNoCache("im_voice_right_full")
                voiceImageView.animationDuration = 1
                var images=[UIImage]()
                for i in 1...3{
                    if let img = UIImage(named: "voice_paly_right_\(i)") {
                         images.append(img)
                    }
                }
                voiceImageView.animationImages = images
                voiceImageView.animationRepeatCount=0
                
            } else {
                voiceImageView.image = EdoImageNoCache("im_voice_pressed")
                voiceImageView.animationDuration = 1
                var images=[UIImage]()
                for i in 1...3{
                    if let img = UIImage(named: "voice_paly_left_\(i)") {
                        images.append(img)
                    }
                }
                voiceImageView.animationImages = images
                voiceImageView.animationRepeatCount=0
            }
            break
        default:
            break
        }
    }
    
    // MARK: - Download data logic
    func downloadData(for downloadInfo: DownloadInfo) {
        guard !isDownloadingData && !giveUpRetry else { return }
        messageId = downloadInfo.messageId
        self.isDownloadingData = true
        self.doDownloadData(for: downloadInfo) { doNotRetryDownload in
            self.giveUpRetry = doNotRetryDownload
            self.isDownloadingData = false
            if self.backgroundTask != UIBackgroundTaskInvalid {
                UIApplication.shared.endBackgroundTask(self.backgroundTask)
                self.backgroundTask = UIBackgroundTaskInvalid
            }
        }
    }
    
    //If download data process has a non-recoverable error, so that it won't retry
    //To be overriden by subclass
    func hasNonRecoverableError() -> Bool {
        return false
    }
    
    //finished(doNotRetryDownload: Bool), if doNotRetryDownload is true, there is non-recoverable error, do not download data again
    func doDownloadData(for downloadInfo: DownloadInfo, finishedAndDoNotRetry: ((Bool)->())? = nil) {
        guard let msg = EmailDAL.getChatMessage(msgId: downloadInfo.messageId) else {
            finishedAndDoNotRetry?(true) //do not download again
            return
        }
        guard let _ = EmailDAL.getChatAccount(accountId: downloadInfo.accountId) else {
            finishedAndDoNotRetry?(true)
            return
        }
        XMPPAdapter.downloadData(accountId: downloadInfo.accountId,
                                 chatMsgId: downloadInfo.messageId) { (messageId, filePath) in
                                    EDOMainthread {
//                                        var hasNonRecoverableError = false
                                        if messageId == self.messageId {
                                            self.loadingView()?.stopAnimating()
                                            BroadcastCenter.postNotification(.MsgMessageVoiceUpdate, information: [.ConversationId: msg.conversationId])
                                        } else {
                                            XMPPMgrLog("voice is no longer needed")
                                        }
                                        finishedAndDoNotRetry?(true)
                                    }
        }
    }
    
    @objc func appWillEnterBackground(noti:Notification) {
        if isDownloadingData {
            backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                UIApplication.shared.endBackgroundTask(self.backgroundTask)
                NMLog("backgroundTask expired")
                self.backgroundTask = UIBackgroundTaskInvalid
            })
        }
    }
    
    override open func prepareForReuse() {
        super.prepareForReuse()
        isDownloadingData = false
        messageId = ""
    }
}
