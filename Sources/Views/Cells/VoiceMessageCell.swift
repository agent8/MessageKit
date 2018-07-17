//
//  VoiceMessageCell.swift
//  Email
//
//  Created by cccc on 2018/5/24.
//  Copyright © 2018年 Easilydo. All rights reserved.
//

import UIKit
public protocol VoiceMessageCellDelegate: MessageLabelDelegate {
    func didTapTopAgainDownloadVoiceView(in messageId: String)
}


open class VoiceMessageCell: MessageCollectionViewCell {
    open override class func reuseIdentifier() -> String { return "messagekit.cell.voicemessage" }
    
    // MARK: - Properties
    private var voiceImageViewRightConstraint = NSLayoutConstraint()
    private var voiceImageViewLeftConstraint = NSLayoutConstraint()
    private var voiceImageViewConstraints = [NSLayoutConstraint]()
    
    open weak var voiceMessageCellDelegate: VoiceMessageCellDelegate?
    
    var message : EdisonMessage?
    var isDownloadingData = false
    var giveUpRetry = false //if true, there is non-recoverable error, do not download data again
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var duration = 0
    var vociePlayed = false
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
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
            self.tag = message.messageId.hashValue
//            print("+++++++++self.tag:\(self.tag), messageID:\(message.messageId.hashValue)")

            duration = data.duration
            //may not cause. If duration = 0,should be code or server bug.
            if duration != 0 {
                super.voiceTimeView.text = "\(data.duration)″"
                super.voiceTimeView.textColor = UIColor.lightGray
            }

            var isOwn = false
            if let bool = messagesCollectionView.messagesDataSource?.isFromCurrentSender(message: message) {
                isOwn = bool
            }
            let isAnimation = ChatAudio.sharedInstance.messageId == message.messageId
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
                if isAnimation {
                    voiceImageView.startAnimating()
                }
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
                if isAnimation {
                    voiceImageView.startAnimating()
                }
                setupLeftConstraints()
                self.layoutIfNeeded()
                self.layoutSubviews()
                
                if !vociePlayed {
                    self.voicePlayView.isHidden = false
                } else {
                    self.voicePlayView.isHidden = true
                }
                
                if let msg = message as? EdisonMessage {
                    guard isEmpty(msg.mediaPath) else {
                        self.againDownloadVoiceView.isHidden = true
                        if msg.downloadState != XMPPConstants.ChatMsgVoiceDownloadState.downloadSuccess {
                            EmailDAL.updateAsync(dbType:.ChatDB, { (db) in
                                if let msg = EmailDAL.getChatMessage(accountId: msg.accountId, msgId: msg.messageId) {
                                    db.write {
                                        msg.downloadState  = XMPPConstants.ChatMsgVoiceDownloadState.downloadSuccess
                                    }
                                }
                            })
                        }
                        return
                    }
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
                        self.message = msg
                        self.againDownloadVoiceView.isHidden = false
                        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapGestureRecognizer(_:)))
                        self.againDownloadVoiceView.addGestureRecognizer(tapGestureRecognizer)
                        self.contentView.addSubview(againDownloadVoiceView)
                        break
                    default: break
                        
                    }
                }
            }
            
            break
        default:
            break
        }
    }
    @objc func tapGestureRecognizer(_ tapGesture :UITapGestureRecognizer) {
        if let messageId = self.message?.messageId {
            print("+++++++++self.tag:\(self.tag), messageID:\(String(describing: self.message?.messageId.hashValue)), isequle:\(self.tag == self.message?.messageId.hashValue)")
            self.voiceMessageCellDelegate?.didTapTopAgainDownloadVoiceView(in: messageId)
        }
    }
    
    //TODO: loadingView Animating
    @objc func loadingViewAnimating() {
        if let loading = loadingView() {
            loading.startAnimating()
        } else {
            let loading = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            loading.frame = self.accessoryView.bounds
            self.accessoryView.addSubview(loading)
            loading.startAnimating()
        }
    }

}
