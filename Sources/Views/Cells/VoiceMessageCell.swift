//
//  VoiceMessageCell.swift
//  Email
//
//  Created by cccc on 2018/5/24.
//  Copyright © 2018年 Easilydo. All rights reserved.
//

import UIKit
public protocol VoiceMessageCellDelegate: MessageLabelDelegate {
    func didTapTopAgainDownloadVoiceView(in cell: VoiceMessageCell)
}


open class VoiceMessageCell: MessageCollectionViewCell {
    open override class func reuseIdentifier() -> String { return "messagekit.cell.voicemessage" }
    
    // MARK: - Properties
    private var voiceImageViewRightConstraint = NSLayoutConstraint()
    private var voiceImageViewLeftConstraint = NSLayoutConstraint()
    private var voiceImageViewConstraints = [NSLayoutConstraint]()
    
    open weak var voiceMessageCellDelegate: VoiceMessageCellDelegate?
    
    var messageId = ""
    var isDownloadingData = false
    var giveUpRetry = false //if true, there is non-recoverable error, do not download data again
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var duration = 0
    var vociePlayed = false
    var downloadInfo = DownloadInfo(accountId: "", messageId: "")
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
//        BroadcastCenter.addObserver(self, selector: #selector(self.appWillEnterBackground(noti:)), notification: .AppPrepareEnterBackground)
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
    
    open var imageView = UIImageView()

    open var againDownloadVoiceView = UIView()
    // MARK: - Methods

    open func setupRightConstraints() {
        NSLayoutConstraint.deactivate(voiceImageViewConstraints)
        voiceImageViewRightConstraint = voiceImageView.rightAnchor.constraint(equalTo: imageView.rightAnchor, constant: -5)
        voiceImageViewConstraints = [
            voiceImageViewRightConstraint,
            voiceImageView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
            ]
        NSLayoutConstraint.activate(voiceImageViewConstraints)
        
    }
    open func setupLeftConstraints() {
        NSLayoutConstraint.deactivate(voiceImageViewConstraints)
        voiceImageViewLeftConstraint = voiceImageView.leftAnchor.constraint(equalTo: imageView.leftAnchor, constant: 5)
        voiceImageViewConstraints = [
            voiceImageViewLeftConstraint,
            voiceImageView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
            ]
        NSLayoutConstraint.activate(voiceImageViewConstraints)
    }

    open override func setupSubviews() {
        super.setupSubviews()
        
        messageContainerView.stackView.addArrangedSubview(imageView)
        imageView.addSubview(voiceImageView)
        
        voiceImageView.constraint(equalTo: CGSize(width: 35, height: 35))
        let alertVoiceImageView = UIImageView()
        alertVoiceImageView.image = EdoImageNoCache("alert-icon")
        alertVoiceImageView.translatesAutoresizingMaskIntoConstraints = false
        alertVoiceImageView.frame = againDownloadVoiceView.frame
        againDownloadVoiceView.isHidden = true
        contentView.addSubview(againDownloadVoiceView)
        againDownloadVoiceView.addSubview(alertVoiceImageView)
        againDownloadVoiceView.addConstraintsForSubviewWithSameSize(alertVoiceImageView)

    }
    open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        if let attributes = layoutAttributes as? MessagesCollectionViewLayoutAttributes {
            againDownloadVoiceView.frame = attributes.accessoryViewFrame
        }
    }
    func changeVoicePlayed(voicePlay : Bool) {
        if !voicePlay {
            self.voicePlayView.isHidden = false
        } else {
            self.voicePlayView.isHidden = true
        }
    }

    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        
        self.voiceMessageCellDelegate = messagesCollectionView.voiceMessageCellDelegate
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        switch message.data {
        case .audio(let data):
            vociePlayed = data.voicePlayed
           
            duration = data.duration
            super.voiceTimeView.text = "\(data.duration)s"
            super.voiceTimeView.textColor = UIColor.lightGray
           

            var isOwn = false
            if let bool = messagesCollectionView.messagesDataSource?.isFromCurrentSender(message: message) {
                isOwn = bool
            }
            if isOwn {
                voiceImageView.image = EdoImageNoCache("im_voice_right_full")
                voiceImageView.animationDuration = 1
                var images=[UIImage]()
                for i in 1...3{
                    if let img = EdoImageNoCache("voice_paly_right_\(i)") {
                         images.append(img)
                    }
                }
                voiceImageView.animationImages = images
                voiceImageView.animationRepeatCount=0
                self.voicePlayView.isHidden = true
                setupRightConstraints()
                self.layoutIfNeeded()
                self.layoutSubviews()
                
                self.againDownloadVoiceView.removeFromSuperview()
            } else {
                voiceImageView.image = EdoImageNoCache("im_voice_pressed")
                voiceImageView.animationDuration = 1
                var images=[UIImage]()
                for i in 1...3{
                    if let img = EdoImageNoCache("voice_paly_left_\(i)") {
                        images.append(img)
                    }
                }
                voiceImageView.animationImages = images
                voiceImageView.animationRepeatCount=0
                
                setupLeftConstraints()
                self.layoutIfNeeded()
                self.layoutSubviews()
                
                if !vociePlayed {
                    self.voicePlayView.isHidden = false
                } else {
                    self.voicePlayView.isHidden = true
                }
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapGestureRecognizer(_:)))
                self.againDownloadVoiceView.addGestureRecognizer(tapGestureRecognizer)
                self.contentView.addSubview(againDownloadVoiceView)
            }
            if let msg = message as? EdisonMessage {
                switch msg.downloadState {
                case XMPPConstants.ChatMsgVoiceDownloadState.downloading:
                     self.againDownloadVoiceView.isHidden = true
                    if let loading = loadingView() {
                        loading.startAnimating()
                    } else {
                        let loading = UIActivityIndicatorView(activityIndicatorStyle: .gray)
                        loading.frame = self.accessoryView.bounds
                        self.accessoryView.addSubview(loading)
                        loading.startAnimating()
                    }
                    
                    break
                case XMPPConstants.ChatMsgVoiceDownloadState.downloadSuccess:
                    self.againDownloadVoiceView.isHidden = true
                    break
                case XMPPConstants.ChatMsgVoiceDownloadState.downloadFailed:
                    if let loading = loadingView() {
                        loading.stopAnimating()
                    }
                    self.againDownloadVoiceView.isHidden = false
                    
                    break
                default: break
                    
                }
            }
            
            break
        default:
            break
        }
    }
    @objc func tapGestureRecognizer(_ tapGesture :UITapGestureRecognizer) {
        self.voiceMessageCellDelegate?.didTapTopAgainDownloadVoiceView(in: self)
    }
    // MARK: - Download data logic
//    func downloadData(for downloadInfo: DownloadInfo) {
//        guard !isDownloadingData && !giveUpRetry else { return }
//        messageId = downloadInfo.messageId
//        self.isDownloadingData = true
//        if let loading = loadingView() {
//            loading.startAnimating()
//        } else {
//            let loading = UIActivityIndicatorView(activityIndicatorStyle: .gray)
//            loading.frame = self.accessoryView.bounds
//            self.accessoryView.addSubview(loading)
//            loading.startAnimating()
//        }
//        self.doDownloadData(for: downloadInfo) { doNotRetryDownload in
//            self.giveUpRetry = doNotRetryDownload
//            self.isDownloadingData = false
//            if self.backgroundTask != UIBackgroundTaskInvalid {
//                UIApplication.shared.endBackgroundTask(self.backgroundTask)
//                self.backgroundTask = UIBackgroundTaskInvalid
//            }
//        }
//    }

    //If download data process has a non-recoverable error, so that it won't retry
    //To be overriden by subclass
    func hasNonRecoverableError() -> Bool {
        return false
    }
    
    //finished(doNotRetryDownload: Bool), if doNotRetryDownload is true, there is non-recoverable error, do not download data again
//    func doDownloadData(for downloadInfo: DownloadInfo, finishedAndDoNotRetry: ((Bool)->())? = nil) {
//        guard let msg = EmailDAL.getChatMessage(msgId: downloadInfo.messageId) else {
//            finishedAndDoNotRetry?(true) //do not download again
//            return
//        }
//        guard let _ = EmailDAL.getChatAccount(accountId: downloadInfo.accountId) else {
//            finishedAndDoNotRetry?(true)
//            return
//        }
//        XMPPAdapter.downloadData(accountId: downloadInfo.accountId,
//                                 chatMsgId: downloadInfo.messageId) { (messageId, filePath, success) in
//                                    EDOMainthread {
////                                        var hasNonRecoverableError = false
//                                        if messageId == self.messageId {
//                                            self.loadingView()?.stopAnimating()
//                                            BroadcastCenter.postNotification(.MsgMessageVoiceUpdate, information: [.ConversationId: msg.conversationId])
//                                            if !success {
//
//                                                //TODO: add a download failure warning
//                                                self.againDownloadVoiceView.isHidden = false
//
//                                            }
//                                        } else {
//                                            XMPPMgrLog("voice is no longer needed")
//                                        }
//                                        finishedAndDoNotRetry?(true)
//                                    }
//        }
//    }

    //TODO: retry download
    @objc func retrydownload() {
//        self.giveUpRetry = false
//        downloadData(for: self.downloadInfo)
    }

//    @objc func appWillEnterBackground(noti:Notification) {
//        if isDownloadingData {
//            backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
//                UIApplication.shared.endBackgroundTask(self.backgroundTask)
//                NMLog("backgroundTask expired")
//                self.backgroundTask = UIBackgroundTaskInvalid
//            })
//        }
//    }

//    override open func prepareForReuse() {
//        super.prepareForReuse()
//        isDownloadingData = false
//        messageId = ""
//    }
}
