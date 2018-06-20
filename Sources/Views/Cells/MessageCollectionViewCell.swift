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

open class MessageCollectionViewCell: UICollectionViewCell, CollectionViewReusable {

    open class func reuseIdentifier() -> String {
        return "messagekit.cell.base-cell"
    }

    open var avatarView: EdisonProfileView = {
        let view = EdisonProfileView()
        view.showOnlineStatusBadge = false
        view.circular = true
        return view
    }()
    
    // Should only add customized subviews, but not change this view itself
    open var accessoryView = UIView()

    open var messageContainerView: MessageContainerView = {
        let containerView = MessageContainerView(frame: .zero)
        containerView.clipsToBounds = true
        containerView.layer.masksToBounds = true
        return containerView
    }()
    
    
    open var voiceTimeView = UILabel()

    
    open lazy var voicePlayView: UIView = {
        let voicePlayView = UIView()
        voicePlayView.layer.cornerRadius = 2
        voicePlayView.backgroundColor = UIColor.red
        voicePlayView.isHidden = true
        voicePlayView.translatesAutoresizingMaskIntoConstraints = false
        return voicePlayView
    }()
    open var cellTopLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    open var cellBottomLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    open var replyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = COLOR_TEXT_LIGHT_GRAY
        label.font = .staticMedium()
        label.text = "Reply"
        label.isHidden = true
        return label
    }()
    
    lazy var replyView: ReplyView = {
        let view = ReplyView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    open weak var delegate: MessageCellDelegate?

    open var isOwnToReply = false
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        setupSubviews()
        setupCustomMenuItems()
        setupReplyLabelConstraint()
        setupVoicePlayViewonstraint()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func setupSubviews() {
        contentView.addSubview(messageContainerView)
        voiceTimeView.textAlignment = .center
        contentView.addSubview(voiceTimeView)
        contentView.addSubview(voicePlayView)
        contentView.addSubview(avatarView)
        contentView.addSubview(accessoryView)
        contentView.addSubview(cellTopLabel)
        contentView.addSubview(cellBottomLabel)
        addSubview(replyLabel)
    }
    
    open func insertReplyView(isOutgoing: Bool) {
        messageContainerView.stackView.insertArrangedSubview(replyView, at: 0)
        replyView.backgroundColor = UIColor.red
        replyView.layoutMargins.left = isOutgoing ? 15 : 20
    }
    
    open func setupCustomMenuItems() {
        let reply = UIMenuItem(title: "Reply", action: #selector(reply(_:)))
        UIMenuController.shared.menuItems = [reply]
    }
    
    open func setupReplyLabelConstraint() {
        NSLayoutConstraint.activate([
            replyLabel.leftAnchor.constraint(equalTo: messageContainerView.rightAnchor, constant: 15),
            replyLabel.centerYAnchor.constraint(equalTo: messageContainerView.centerYAnchor)
        ])
    }
    
    open func setupVoicePlayViewonstraint() {
        
        NSLayoutConstraint.activate([
            voicePlayView.rightAnchor.constraint(equalTo: voiceTimeView.rightAnchor),
            voicePlayView.topAnchor.constraint(equalTo: messageContainerView.topAnchor, constant: 5),
            voicePlayView.widthAnchor.constraint(equalToConstant: 4),
            voicePlayView.heightAnchor.constraint(equalToConstant: 4),
            ])
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        cellTopLabel.text = nil
        cellTopLabel.attributedText = nil
        cellBottomLabel.text = nil
        cellBottomLabel.attributedText = nil
        replyView.removeFromSuperview()
        accessoryView.subviews.forEach( { $0.removeFromSuperview() })
        avatarView.prepareForReuse()
    }

    open func loadingView() -> UIActivityIndicatorView? {
        for view in accessoryView.subviews {
            if let loadingIndicator = view as? UIActivityIndicatorView {
                return loadingIndicator
            }
        }
        return nil
    }
    
    // MARK: - Configuration

    open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        if let attributes = layoutAttributes as? MessagesCollectionViewLayoutAttributes {
            avatarView.frame = attributes.avatarFrame
            cellTopLabel.frame = attributes.topLabelFrame
            cellBottomLabel.frame = attributes.bottomLabelFrame
            messageContainerView.frame = attributes.messageContainerFrame
            voiceTimeView.frame = attributes.voiceTimeViewframe
            accessoryView.frame = attributes.accessoryViewFrame
//            replyLabel.frame = attributes.accessoryViewFrame
        }
    }

    open func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        guard let dataSource = messagesCollectionView.messagesDataSource else {
            fatalError(MessageKitError.nilMessagesDataSource)
        }
        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            fatalError(MessageKitError.nilMessagesDisplayDelegate)
        }

        delegate = messagesCollectionView.messageCellDelegate

        let messageColor = displayDelegate.backgroundColor(for: message, at: indexPath, in: messagesCollectionView)
        let messageStyle = displayDelegate.messageStyle(for: message, at: indexPath, in: messagesCollectionView)
        
        displayDelegate.configureAvatarView(avatarView, for: message, at: indexPath, in: messagesCollectionView)

        messageContainerView.backgroundColor = messageColor
        messageContainerView.style = messageStyle

        let topText = dataSource.cellTopLabelAttributedText(for: message, at: indexPath)
        let bottomText = dataSource.cellBottomLabelAttributedText(for: message, at: indexPath)

        cellTopLabel.attributedText = topText
        cellBottomLabel.attributedText = bottomText
        
        setupSwipeReplyGesture(delegate: messagesCollectionView)
        

        if let bool = messagesCollectionView.messagesDataSource?.isFromCurrentSender(message: message) {
            isOwnToReply = bool
        }
    }

    /// Handle tap gesture on contentView and its subviews like messageContainerView, cellTopLabel, cellBottomLabel, avatarView ....
    open func handleTapGesture(_ gesture: UIGestureRecognizer) {
        let touchLocation = gesture.location(in: self)

        switch true {
        case messageContainerView.frame.contains(touchLocation) && !cellContentView(canHandle: convert(touchLocation, to: messageContainerView)):
            delegate?.didTapMessage(in: self, touchLocation: touchLocation)
        case avatarView.frame.contains(touchLocation):
            delegate?.didTapAvatar(in: self)
        case cellTopLabel.frame.contains(touchLocation):
            delegate?.didTapTopLabel(in: self)
        case cellBottomLabel.frame.contains(touchLocation):
            delegate?.didTapBottomLabel(in: self)
        default:
            break
        }
    }
    
    /// Handle long press gesture, return true when gestureRecognizer's touch point in `messageContainerView`'s frame
    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let touchPoint = gestureRecognizer.location(in: self)
        guard gestureRecognizer.isKind(of: UILongPressGestureRecognizer.self) else { return false }
        return messageContainerView.frame.contains(touchPoint)
    }

    /// Handle `ContentView`'s tap gesture, return false when `ContentView` doesn't needs to handle gesture
    open func cellContentView(canHandle touchPoint: CGPoint) -> Bool {
        return false
    }
    
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard let delegate = self.delegate else {
            return false
        }
        return delegate.canPerformAction(for: self, action: action, withSender: sender)
    }
    
    override open func copy(_ sender: Any?) {
        delegate?.didTapCopyMenuItem(from: self)
    }
    
    override open func delete(_ sender: Any?) {
        delegate?.didTapDeleteMenuItem(from: self)
    }
    
    @objc
    open func reply(_ sender: Any?) {
        delegate?.didTapReplyMenuItem(from: self)
    }
    
    open func setupSwipeReplyGesture(delegate: UIGestureRecognizerDelegate) {
        let swipeReply = SwipeReplyPanGestureRecognizer(target: self, action: #selector(onSwipeReply))
        contentView.addGestureRecognizer(swipeReply)
        swipeReply.delegate = delegate
    }
    
    @objc func onSwipeReply(gestureRecognizer: SwipeReplyPanGestureRecognizer) {
        delegate?.didSwipeReply(from: self, gestureRecognizer: gestureRecognizer)
    }
}

open class SwipeReplyPanGestureRecognizer: UIPanGestureRecognizer {
    var beganCenterPoint: CGPoint?
    var swipedIndexPath: IndexPath?
}
