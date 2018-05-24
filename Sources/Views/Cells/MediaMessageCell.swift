/*
 MIT License

 Copyright (c) 2017-2018 MessageKit

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import UIKit

open class MediaMessageCell: MessageCollectionViewCell {

    open override class func reuseIdentifier() -> String { return "messagekit.cell.mediamessage" }

    // MARK: - Properties
    
    var messageId = ""
    var isDownloadingData = false
    var giveUpRetry = false //if true, there is non-recoverable error, do not download data again
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
    
    open lazy var playButtonView: PlayButtonView = {
        let playButtonView = PlayButtonView()
        return playButtonView
    }()

    open var imageView = UIImageView()

    // MARK: - Methods

    open func setupConstraints() {
        playButtonView.centerInSuperview()
        playButtonView.constraint(equalTo: CGSize(width: 35, height: 35))
    }

    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.stackView.addArrangedSubview(imageView)
        imageView.addSubview(playButtonView)
        setupConstraints()
    }

    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        //czy：当收到长图片的时候，进行裁剪，以免图片显示被压缩
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        switch message.data {
        case .photo(let downloadInfo):
            if let message: ChatMessage = EmailDAL.getChatMessage(accountId: downloadInfo.accountId,
                                                                  msgId: downloadInfo.messageId),
                let image = UIImage(contentsOfFile: message.thumbPath) {
                imageView.image = image
            } else {
                // placeholder image
                imageView.image = UIImage().from(color: COLOR_TABLE_BACKGROUND, size: CGSize(width: 210, height: 150))
                downloadData(for: downloadInfo)
            }
            playButtonView.isHidden = true
        case .video(_, let image):
            imageView.image = image
            playButtonView.isHidden = false
        case .attachment(let data):
            playButtonView.isHidden = true
            if let attachmentCell = self as? DocumentMessageCell {
                let isOutgoing =
                    messagesCollectionView.messagesDataSource?.isFromCurrentSender(message: message)
                        ?? true
                
                attachmentCell.load(attachment: data, isOutgoing: isOutgoing)
                //Preload attachment data
                if let msg = message as? EdisonMessage {
                    downloadData(for: DownloadInfo(accountId: msg.accountId, messageId: msg.messageId))
                }
            }
//        case .audio(let data):
////            playButtonView.isHidden = true
////            if let attachmentCell = self as? DocumentMessageCell {
////                let isOutgoing =
////                    messagesCollectionView.messagesDataSource?.isFromCurrentSender(message: message)
////                        ?? true
////
////                attachmentCell.load(attachment: data, isOutgoing: isOutgoing)
////                //Preload attachment data
////                if let msg = message as? EdisonMessage {
////                    downloadData(for: DownloadInfo(accountId: msg.accountId, messageId: msg.messageId))
////                }
////            }
//           break
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
        finishedAndDoNotRetry?(true)
        //To be override by subclass
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
