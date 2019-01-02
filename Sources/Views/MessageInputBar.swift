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

/// A powerful InputAccessoryView ideal for messaging applications
open class MessageInputBar: UIView {
    
    // MARK: - Properties
    
    /// A delegate to broadcast notifications from the MessageInputBar
    weak var delegate: MessageInputBarDelegate?
    
    //SZ: documents, images to be sent
    var attachments = [ChatAttachment]() {
        didSet {
            attachmentViewDidChange()
        }
    }
    
    /// The background UIView anchored to the bottom, left, and right of the MessageInputBar
    /// with a top anchor equal to the bottom of the top InputStackView
    lazy var backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .inputBarGray
        return view
    }()
    
    /// A content UIView that holds the left/right/bottom InputStackViews and InputTextView. Anchored to the bottom of the
    /// topStackView and inset by the padding UIEdgeInsets
    lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var borderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.layer.borderWidth = 0.5
        view.layer.cornerRadius = 19
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var attachmentsView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.register(InputBarAttachmentCell.self, forCellReuseIdentifier: "InputBarAttachmentCell")
        tableView.transform = CGAffineTransform.identity.rotated(by: -CGFloat(Double.pi / 2))
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.layer.masksToBounds = true
        tableView.layer.cornerRadius = 19
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    lazy var replyView: InputBarReplyView = {
        let view = InputBarReplyView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /**
     A UIVisualEffectView that adds a blur effect to make the view appear transparent.
     
     ## Important Notes ##
     1. The blurView is initially not added to the backgroundView to improve performance when not needed. When `isTranslucent` is set to TRUE for the first time the blurView is added and anchored to the `backgroundView`s edge anchors
     */
    lazy var blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .light)
        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// Determines if the MessageInputBar should have a translucent effect
    var isTranslucent: Bool = false {
        didSet {
            if isTranslucent && blurView.superview == nil {
                backgroundView.addSubview(blurView)
                blurView.fillSuperview()
            }
            blurView.isHidden = !isTranslucent
            let color: UIColor = backgroundView.backgroundColor ?? .inputBarGray
            backgroundView.backgroundColor = isTranslucent ? color.withAlphaComponent(0.75) : color.withAlphaComponent(1.0)
        }
    }
    
    /// A SeparatorLine that is anchored at the top of the MessageInputBar with a height of 1
    let separatorLine = SeparatorLine()
    
    /**
     The InputStackView at the InputStackView.top position
     
     ## Important Notes ##
     1. It's axis is initially set to .vertical
     2. It's alignment is initially set to .fill
     */
    let topStackView: InputStackView = {
        let stackView = InputStackView(axis: .vertical, spacing: 0)
        stackView.alignment = .fill
        return stackView
    }()
    
    /**
     The InputStackView at the InputStackView.left position
     
     ## Important Notes ##
     1. It's axis is initially set to .horizontal
     */
    let leftStackView = InputStackView(axis: .horizontal, spacing: 0)
    
    /**
     The InputStackView at the InputStackView.right position
     
     ## Important Notes ##
     1. It's axis is initially set to .horizontal
     */
    let rightStackView = InputStackView(axis: .horizontal, spacing: 0)
    
    /**
     The InputStackView at the InputStackView.bottom position
     
     ## Important Notes ##
     1. It's axis is initially set to .horizontal
     */
    let bottomStackView = InputStackView(axis: .horizontal, spacing: 0)
    
    /// The InputTextView a user can input a message in
    lazy var inputTextView: InputTextView = {
        let textView = InputTextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.messageInputBar = self
        return textView
    }()

    /// A InputBarButtonItem used as the send button and initially placed in the rightStackView
    lazy var sendButton: InputBarButtonItem = {
        return InputBarButtonItem()
            .onEnabled {
                $0.imageView?.tintColor = nil
            }.onDisabled {
                $0.imageView?.tintColor = COLOR_TINT_DARK_GRAY
            }.configure {
                $0.setSize(CGSize(width: 52, height: 28), animated: false)
                $0.setIsHidden(true, animated: false)
                $0.title = "Send"
                $0.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
            }.onTouchUpInside {
                $0.messageInputBar?.didSelectSendButton()
        }
    }()

    /// A boolean that determines whether the sendButton's `isEnabled` state should be managed automatically.
    var shouldManageSendButtonEnabledState = true
    
    /**
     The anchor constants that inset the contentView
     
     ````
     V:|...[InputStackView.top]-(padding.top)-[contentView]-(padding.bottom)-|
     
     H:|-(padding.left)-[contentView]-(padding.right)-|
     ````
     
     */
    var padding: UIEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12) {
        didSet {
            updatePadding()
        }
    }
    
    /**
     The anchor constants used by the top InputStackView
     
     ## Important Notes ##
     1. The topStackViewPadding.bottom property is not used. Use padding.top to add separation
     
     ````
     V:|-(topStackViewPadding.top)-[InputStackView.top]-(padding.top)-[InputTextView]-...|
     
     H:|-(topStackViewPadding.left)-[InputStackView.top]-(topStackViewPadding.right)-|
     ````
     
     */
    var topStackViewPadding: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) {
        didSet {
            updateTopStackViewPadding()
        }
    }
    
    /**
     The anchor constants used by the InputStackView
     
     ````
     V:|...-(padding.top)-(textViewPadding.top)-[InputTextView]-(textViewPadding.bottom)-[InputStackView.bottom]-...|
     
     H:|...-[InputStackView.left]-(textViewPadding.left)-[InputTextView]-(textViewPadding.right)-[InputStackView.right]-...|
     ````
     
     */
    var textViewPadding: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8) {
        didSet {
            updateTextViewPadding()
        }
    }
    
    /// Returns the most recent size calculated by `calculateIntrinsicContentSize()`
    override open var intrinsicContentSize: CGSize {
        return cachedIntrinsicContentSize
    }
    
    /// The intrinsicContentSize can change a lot so the delegate method
    /// `inputBar(self, didChangeIntrinsicContentTo: size)` only needs to be called
    /// when it's different
    public private(set) var previousIntrinsicContentSize: CGSize?
    
    /// The most recent calculation of the intrinsicContentSize
    private lazy var cachedIntrinsicContentSize: CGSize = calculateIntrinsicContentSize()
    
    /// A boolean that indicates if the maxTextViewHeight has been met. Keeping track of this
    /// improves the performance
    public private(set) var isOverMaxTextViewHeight = false
    
    /// A boolean that determines if the maxTextViewHeight should be auto updated on device rotation
    var shouldAutoUpdateMaxTextViewHeight = true
    
    /// The maximum height that the InputTextView can reach
    var maxTextViewHeight: CGFloat = 0 {
        didSet {
            textViewHeightAnchor?.constant = maxTextViewHeight
            invalidateIntrinsicContentSize()
        }
    }
    
    private(set) var attachmentViewHeight: CGFloat = 0
    
    /// The height that will fit the current text in the InputTextView based on its current bounds
    public var requiredInputTextViewHeight: CGFloat {
        let maxTextViewSize = CGSize(width: inputTextView.bounds.width, height: .greatestFiniteMagnitude)
        return inputTextView.sizeThatFits(maxTextViewSize).height.rounded(.down)
    }
    
    /// The fixed widthAnchor constant of the leftStackView
    public private(set) var leftStackViewWidthConstant: CGFloat = 0 {
        didSet {
            leftStackViewLayoutSet?.width?.constant = leftStackViewWidthConstant
        }
    }
    
    /// The fixed widthAnchor constant of the rightStackView
    public private(set) var rightStackViewWidthConstant: CGFloat = 52 {
        didSet {
            rightStackViewLayoutSet?.width?.constant = rightStackViewWidthConstant
        }
    }
    
    /// The InputBarItems held in the leftStackView
    public private(set) var leftStackViewItems: [InputBarButtonItem] = []
    
    /// The InputBarItems held in the rightStackView
    public private(set) var rightStackViewItems: [InputBarButtonItem] = []
    
    /// The InputBarItems held in the bottomStackView
    public private(set) var bottomStackViewItems: [InputBarButtonItem] = []
    
    /// The InputBarItems held in the topStackView
    public private(set) var topStackViewItems: [InputBarButtonItem] = []
    
    /// The InputBarItems held to make use of their hooks but they are not automatically added to a UIStackView
    var nonStackViewItems: [InputBarButtonItem] = []
    
    /// Returns a compactMap of all the items in each of the UIStackViews
    public var items: [InputBarButtonItem] {
        return [leftStackViewItems, rightStackViewItems, bottomStackViewItems, nonStackViewItems].flatMap { $0 }
    }
    
    // MARK: - Auto-Layout Management
    
    private var textViewLayoutSet: NSLayoutConstraintSet?
    private var textViewHeightAnchor: NSLayoutConstraint?
    private var topStackViewLayoutSet: NSLayoutConstraintSet?
    private var leftStackViewLayoutSet: NSLayoutConstraintSet?
    private var rightStackViewLayoutSet: NSLayoutConstraintSet?
    private var bottomStackViewLayoutSet: NSLayoutConstraintSet?
    private var contentViewLayoutSet: NSLayoutConstraintSet?
    private var borderViewLayoutSet: NSLayoutConstraintSet?
    private var attachmentViewLayoutSet: NSLayoutConstraintSet?
    private var windowAnchor: NSLayoutConstraint?
    private var backgroundViewBottomAnchor: NSLayoutConstraint?
    private var backgroundViewWidthAnchor: NSLayoutConstraint?

    // MARK: - Initialization
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        setupConstraints(to: window)
    }
    
    // MARK: - Setup
    
    /// Sets up the default properties
    func setup() {
        
        autoresizingMask = [.flexibleHeight]
        setupSubviews()
        setupConstraints()
        setupObservers()
    }
    
    /// Adds the required notification observers
    private func setupObservers() {
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MessageInputBar.textViewDidChange),
                                               name: .UITextViewTextDidChange, object: inputTextView)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MessageInputBar.textViewDidBeginEditing),
                                               name: .UITextViewTextDidBeginEditing, object: inputTextView)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MessageInputBar.textViewDidEndEditing),
                                               name: .UITextViewTextDidEndEditing, object: inputTextView)
    }
    
    /// Adds all of the subviews
    private func setupSubviews() {
        
        addSubview(backgroundView)
        addSubview(borderView)
        addSubview(topStackView)
        addSubview(contentView)
        contentView.addSubview(inputTextView)
        contentView.addSubview(leftStackView)
        contentView.addSubview(rightStackView)
        contentView.addSubview(bottomStackView)
        contentView.addSubview(attachmentsView)
        contentView.addSubview(separatorLine)
        separatorLine.isHidden = true
        setStackViewItems([sendButton], forStack: .right, animated: false)
    }
    
    /// Sets up the initial constraints of each subview
    private func setupConstraints() {
        
        // The constraints within the MessageInputBar
        separatorLine.addConstraints(inputTextView.topAnchor, left: inputTextView.leftAnchor, right: inputTextView.rightAnchor, heightConstant: 0.5)
        backgroundViewBottomAnchor = backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        backgroundViewBottomAnchor?.isActive = true
        backgroundView.addConstraints(topAnchor, right: rightAnchor)
        
        backgroundViewWidthAnchor = backgroundView.widthAnchor.constraint(equalTo: widthAnchor)
        backgroundViewWidthAnchor?.isActive = true
        
        topStackViewLayoutSet = NSLayoutConstraintSet(
            top:    topStackView.topAnchor.constraint(equalTo: topAnchor, constant: topStackViewPadding.top),
            bottom: topStackView.bottomAnchor.constraint(equalTo: contentView.topAnchor, constant: -padding.top),
            right:  topStackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -topStackViewPadding.right),
            width:  topStackView.widthAnchor.constraint(equalTo: widthAnchor, constant: -(topStackViewPadding.left + topStackViewPadding.right))
        )
        
        contentViewLayoutSet = NSLayoutConstraintSet(
            top:    contentView.topAnchor.constraint(equalTo: topStackView.bottomAnchor, constant: padding.top),
            bottom: contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding.bottom),
            right:  contentView.rightAnchor.constraint(equalTo: rightAnchor, constant: -padding.right),
            width:  contentView.widthAnchor.constraint(equalTo: widthAnchor, constant: -(padding.left + padding.right))
        )
        
        borderViewLayoutSet = NSLayoutConstraintSet(
            top:    borderView.topAnchor.constraint(equalTo: inputTextView.topAnchor, constant: -attachmentViewHeight - 1),
            bottom: borderView.bottomAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: 1),
            left:   borderView.leftAnchor.constraint(equalTo: inputTextView.leftAnchor, constant: -1.5),
            right:  borderView.rightAnchor.constraint(equalTo: inputTextView.rightAnchor, constant: 1.5)
        )
        
        if #available(iOS 11.0, *) {
            // Switch to safeAreaLayoutGuide
            contentViewLayoutSet?.bottom = contentView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -padding.bottom)
            contentViewLayoutSet?.width = contentView.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor, constant: -(padding.left + padding.right))
            contentViewLayoutSet?.right = contentView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -padding.right)
            
            topStackViewLayoutSet?.width = topStackView.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor, constant: -(topStackViewPadding.left + topStackViewPadding.right))
            topStackViewLayoutSet?.right = topStackView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -topStackViewPadding.right)
        }
        
        // Constraints Within the contentView
        attachmentViewLayoutSet = NSLayoutConstraintSet(
            centerX: attachmentsView.centerXAnchor.constraint(equalTo: inputTextView.centerXAnchor, constant: 0),
            centerY: attachmentsView.centerYAnchor.constraint(equalTo: inputTextView.topAnchor, constant: -textViewPadding.top - attachmentViewHeight / 2),
            width:   attachmentsView.widthAnchor.constraint(equalToConstant: attachmentViewHeight),
            height:  attachmentsView.heightAnchor.constraint(equalTo: inputTextView.widthAnchor)
        )
        
        textViewLayoutSet = NSLayoutConstraintSet(
            top:    inputTextView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: textViewPadding.top + attachmentViewHeight),
            bottom: inputTextView.bottomAnchor.constraint(equalTo: bottomStackView.topAnchor, constant: -textViewPadding.bottom),
            left:   inputTextView.leftAnchor.constraint(equalTo: leftStackView.rightAnchor, constant: textViewPadding.left),
            right:  inputTextView.rightAnchor.constraint(equalTo: rightStackView.leftAnchor, constant: -textViewPadding.right)
        )
        maxTextViewHeight = calculateMaxTextViewHeight()
        textViewHeightAnchor = inputTextView.heightAnchor.constraint(equalToConstant: maxTextViewHeight)
        
        leftStackViewLayoutSet = NSLayoutConstraintSet(
            top:    leftStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            bottom: leftStackView.bottomAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: 0),
            left:   leftStackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
            width:  leftStackView.widthAnchor.constraint(equalToConstant: leftStackViewWidthConstant)
        )

        rightStackViewLayoutSet = NSLayoutConstraintSet(
            top:    rightStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            bottom: rightStackView.bottomAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: 0),
            right:  rightStackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0),
            width:  rightStackView.widthAnchor.constraint(equalToConstant: rightStackViewWidthConstant)
        )
        
        bottomStackViewLayoutSet = NSLayoutConstraintSet(
            top:    bottomStackView.topAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: textViewPadding.bottom),
            bottom: bottomStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
            left:   bottomStackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
            right:  bottomStackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0)
        )
        activateConstraints()
    }
    
    /// Respect iPhone X safeAreaInsets
    /// Adds a constraint to anchor the bottomAnchor of the contentView to the window's safeAreaLayoutGuide.bottomAnchor
    ///
    /// - Parameter window: The window to anchor to
    private func setupConstraints(to window: UIWindow?) {
        if #available(iOS 11.0, *) {
            guard UIScreen.main.nativeBounds.height == 2436 else { return }
            if let window = window {
                windowAnchor?.isActive = false
                windowAnchor = contentView.bottomAnchor.constraintLessThanOrEqualToSystemSpacingBelow(window.safeAreaLayoutGuide.bottomAnchor, multiplier: 1)
                windowAnchor?.constant = -padding.bottom
                windowAnchor?.priority = UILayoutPriority(rawValue: 750)
                windowAnchor?.isActive = true
                backgroundViewBottomAnchor?.constant = 34
            }
        }
    }
    
    func setAttachmentViewHeight(_ h: CGFloat, completed: ((Bool) -> Void)? = nil) {
        attachmentViewHeight = h
        attachmentViewLayoutSet?.centerY?.constant = -textViewPadding.top - attachmentViewHeight / 2
        attachmentViewLayoutSet?.width?.constant = attachmentViewHeight
        textViewLayoutSet?.top?.constant = textViewPadding.top + attachmentViewHeight
        invalidateIntrinsicContentSize()
        self.layoutIfNeeded()
        //separatorLine.isHidden = h == 0 //Do not show separator, doesn't look great
        
        EdoAfterMainThread(0.01) {
            self.borderViewLayoutSet?.top?.constant = -h - 1
            UIView.animate(withDuration: 0.25, animations: {
                self.layoutIfNeeded()
            }, completion: completed)
        }
    }
    
    
    // MARK: - Constraint Layout Updates
    
    /// Updates the constraint constants that correspond to the padding UIEdgeInsets
    private func updatePadding() {
        topStackViewLayoutSet?.bottom?.constant = -padding.top
        contentViewLayoutSet?.top?.constant = padding.top
        contentViewLayoutSet?.left?.constant = padding.left
        contentViewLayoutSet?.right?.constant = -padding.right
        contentViewLayoutSet?.bottom?.constant = -padding.bottom
        windowAnchor?.constant = -padding.bottom
    }
    
    /// Updates the constraint constants that correspond to the textViewPadding UIEdgeInsets
    private func updateTextViewPadding() {
        textViewLayoutSet?.top?.constant = textViewPadding.top + attachmentViewHeight
        textViewLayoutSet?.left?.constant = textViewPadding.left
        textViewLayoutSet?.right?.constant = -textViewPadding.right
        textViewLayoutSet?.bottom?.constant = -textViewPadding.bottom
        bottomStackViewLayoutSet?.top?.constant = textViewPadding.bottom
    }
    
    /// Updates the constraint constants that correspond to the topStackViewPadding UIEdgeInsets
    private func updateTopStackViewPadding() {
        topStackViewLayoutSet?.top?.constant = topStackViewPadding.top
        topStackViewLayoutSet?.left?.constant = topStackViewPadding.left
        topStackViewLayoutSet?.right?.constant = -topStackViewPadding.right
    }
    
    /// Invalidates the view’s intrinsic content size
    override open func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        cachedIntrinsicContentSize = calculateIntrinsicContentSize()
        if previousIntrinsicContentSize != cachedIntrinsicContentSize {
            delegate?.messageInputBar(self, didChangeIntrinsicContentTo: cachedIntrinsicContentSize)
            previousIntrinsicContentSize = cachedIntrinsicContentSize
        }
    }
    
    // MARK: - Layout Helper Methods
    
    /// Calculates the correct intrinsicContentSize of the MessageInputBar. This takes into account the various padding edge
    /// insets, InputTextView's height and top/bottom InputStackView's heights.
    ///
    /// - Returns: The required intrinsicContentSize
    func calculateIntrinsicContentSize() -> CGSize {
        
        var inputTextViewHeight = requiredInputTextViewHeight
        if inputTextViewHeight >= maxTextViewHeight {
            if !isOverMaxTextViewHeight {
                textViewHeightAnchor?.isActive = true
                inputTextView.isScrollEnabled = true
                isOverMaxTextViewHeight = true
            }
            inputTextViewHeight = maxTextViewHeight
        } else {
            if isOverMaxTextViewHeight {
                textViewHeightAnchor?.isActive = false
                inputTextView.isScrollEnabled = false
                isOverMaxTextViewHeight = false
                inputTextView.invalidateIntrinsicContentSize()
            }
        }
        
        // Calculate the required height
        let totalPadding = padding.top + padding.bottom + topStackViewPadding.top + textViewPadding.top + textViewPadding.bottom
        let topStackViewHeight = topStackView.arrangedSubviews.count > 0 ? topStackView.bounds.height : 0
        let bottomStackViewHeight = bottomStackView.arrangedSubviews.count > 0 ? bottomStackView.bounds.height : 0
        let verticalStackViewHeight = topStackViewHeight + bottomStackViewHeight + attachmentViewHeight
        let requiredHeight = inputTextViewHeight + totalPadding + verticalStackViewHeight
        return CGSize(width: bounds.width, height: requiredHeight)
    }
    
    /// Returns the max height the InputTextView can grow to based on the UIScreen
    ///
    /// - Returns: Max Height
    func calculateMaxTextViewHeight() -> CGFloat {
        if traitCollection.verticalSizeClass == .regular {
            return (UIScreen.main.bounds.height / 3).rounded(.down)
        }
        return (UIScreen.main.bounds.height / 5).rounded(.down)
    }
    
    /// Layout the given InputStackView's
    ///
    /// - Parameter positions: The UIStackView's to layout
    public func layoutStackViews(_ positions: [InputStackView.Position] = [.left, .right, .bottom, .top]) {
        
        guard superview != nil else { return }
        
        for position in positions {
            switch position {
            case .left:
                leftStackView.setNeedsLayout()
                leftStackView.layoutIfNeeded()
            case .right:
                rightStackView.setNeedsLayout()
                rightStackView.layoutIfNeeded()
            case .bottom:
                bottomStackView.setNeedsLayout()
                bottomStackView.layoutIfNeeded()
            case .top:
                topStackView.setNeedsLayout()
                topStackView.layoutIfNeeded()
            }
        }
    }
    
    /// Performs layout changes over the main thread
    ///
    /// - Parameters:
    ///   - animated: If the layout should be animated
    ///   - animations: Code
    internal func performLayout(_ animated: Bool, _ animations: @escaping () -> Void) {
        deactivateConstraints()
        if animated {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3, animations: animations)
            }
        } else {
            UIView.performWithoutAnimation { animations() }
        }
        activateConstraints()
    }
    
    /// Activates the NSLayoutConstraintSet's
    private func activateConstraints() {
        contentViewLayoutSet?.activate()
        textViewLayoutSet?.activate()
        leftStackViewLayoutSet?.activate()
        rightStackViewLayoutSet?.activate()
        bottomStackViewLayoutSet?.activate()
        topStackViewLayoutSet?.activate()
        borderViewLayoutSet?.activate()
        attachmentViewLayoutSet?.activate()
        backgroundViewWidthAnchor?.isActive = true
    }
    
    /// Deactivates the NSLayoutConstraintSet's
    private func deactivateConstraints() {
        contentViewLayoutSet?.deactivate()
        textViewLayoutSet?.deactivate()
        leftStackViewLayoutSet?.deactivate()
        rightStackViewLayoutSet?.deactivate()
        bottomStackViewLayoutSet?.deactivate()
        topStackViewLayoutSet?.deactivate()
        borderViewLayoutSet?.deactivate()
        attachmentViewLayoutSet?.deactivate()
        backgroundViewWidthAnchor?.isActive = false
    }
    
    // MARK: - UIStackView InputBarItem Methods
    
    /// Removes all of the arranged subviews from the UIStackView and adds the given items. Sets the messageInputBar property of the InputBarButtonItem
    ///
    /// - Parameters:
    ///   - items: New UIStackView arranged views
    ///   - position: The targeted UIStackView
    ///   - animated: If the layout should be animated
    func setStackViewItems(_ items: [InputBarButtonItem], forStack position: InputStackView.Position, animated: Bool) {
        
        func setNewItems() {
            switch position {
            case .left:
                leftStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                leftStackViewItems = items
                leftStackViewItems.forEach {
                    $0.messageInputBar = self
                    $0.parentStackViewPosition = position
                    leftStackView.addArrangedSubview($0)
                }
                guard superview != nil else { return }
                leftStackView.layoutIfNeeded()
            case .right:
                rightStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                rightStackViewItems = items
                rightStackViewItems.forEach {
                    $0.messageInputBar = self
                    $0.parentStackViewPosition = position
                    rightStackView.addArrangedSubview($0)
                }
                guard superview != nil else { return }
                rightStackView.layoutIfNeeded()
            case .bottom:
                bottomStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                bottomStackViewItems = items
                bottomStackViewItems.forEach {
                    $0.messageInputBar = self
                    $0.parentStackViewPosition = position
                    bottomStackView.addArrangedSubview($0)
                }
                guard superview != nil else { return }
                bottomStackView.layoutIfNeeded()
            case .top:
                topStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                topStackViewItems = items
                topStackViewItems.forEach {
                    $0.messageInputBar = self
                    $0.parentStackViewPosition = position
                    topStackView.addArrangedSubview($0)
                }
                guard superview != nil else { return }
                topStackView.layoutIfNeeded()
            }
            invalidateIntrinsicContentSize()
        }
        
        performLayout(animated) {
            setNewItems()
        }
    }
    
    /// Sets the leftStackViewWidthConstant
    ///
    /// - Parameters:
    ///   - newValue: New widthAnchor constant
    ///   - animated: If the layout should be animated
    func setLeftStackViewWidthConstant(to newValue: CGFloat, animated: Bool) {
        performLayout(animated) {
            self.leftStackViewWidthConstant = newValue
            self.layoutStackViews([.left])
            guard self.superview != nil else { return }
            self.layoutIfNeeded()
        }
    }
    
    /// Sets the rightStackViewWidthConstant
    ///
    /// - Parameters:
    ///   - newValue: New widthAnchor constant
    ///   - animated: If the layout should be animated
    func setRightStackViewWidthConstant(to newValue: CGFloat, animated: Bool) {
        performLayout(animated) {
            self.rightStackViewWidthConstant = newValue
            self.layoutStackViews([.right])
            guard self.superview != nil else { return }
            self.layoutIfNeeded()
        }
    }
    
    // MARK: - Notifications/Hooks
    
    /// Invalidates the intrinsicContentSize
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass || traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            if shouldAutoUpdateMaxTextViewHeight {
                maxTextViewHeight = calculateMaxTextViewHeight()
            }
            invalidateIntrinsicContentSize()
        }
    }
    
    /// Enables/Disables the sendButton based on the InputTextView's text being empty
    /// Calls each items `textViewDidChangeAction` method
    /// Calls the delegates `textViewTextDidChangeTo` method
    /// Invalidates the intrinsicContentSize
    @objc
    func textViewDidChange() {
        
        sendableContentDidChange()
        
        inputTextView.placeholderLabel.isHidden = !inputTextView.text.isEmpty
        
        items.forEach { $0.textViewDidChangeAction(with: inputTextView) }
        
        delegate?.messageInputBar(self, textViewTextDidChangeTo: inputTextView.trimmedText)
        
        if requiredInputTextViewHeight != inputTextView.bounds.height {
            // Prevent un-needed content size invalidation
            invalidateIntrinsicContentSize()
        }
    }
    
    /// Calls each items `keyboardEditingBeginsAction` method
    /// Invalidates the intrinsicContentSize so that the keyboard does not overlap the view
    @objc
    func textViewDidBeginEditing() {
        items.forEach { $0.keyboardEditingBeginsAction() }
    }
    
    /// Calls each items `keyboardEditingEndsAction` method
    @objc
    func textViewDidEndEditing() {
        items.forEach { $0.keyboardEditingEndsAction() }
    }
    
    private func attachmentViewDidChange() {
        sendableContentDidChange()
    }
    
    
    private func sendableContentDidChange() {
        if shouldManageSendButtonEnabledState {
            let shouldHide = inputTextView.trimmedText.isEmpty && attachments.isEmpty
            sendButton.setIsHidden(shouldHide, animated: true)
        }
    }
    
    // MARK: - User Actions
    
    /// Calls the delegates `didPressSendButtonWith` method
    /// Assumes that the InputTextView's text has been set to empty and calls `inputTextViewDidChange()`
    /// Invalidates each of the inputManagers
    func didSelectSendButton() {
        delegate?.messageInputBar(self, didPressSendButtonWith: inputTextView.text)
    }
    
    func insertReplyView() {
        topStackView.addArrangedSubview(replyView)
    }
}

// MARK: - Split View

extension MessageInputBar {
    func constraint(to frame: CGRect) {
        performLayout(false) {
            let newWidth = frame.size.width
            guard newWidth > 0 else {
                return
            }
            
            self.backgroundViewWidthAnchor = self.backgroundView.widthAnchor.constraint(equalToConstant: newWidth)
            
            var safePadding: UIEdgeInsets = .zero
            if #available(iOS 11.0, *) {
                safePadding = self.safeAreaInsets
            }
            
            // only care about right safe padding since this split VC is right pinned
            let topStackViewWidth = newWidth
                - self.topStackViewPadding.left
                - self.topStackViewPadding.right
                - safePadding.right
            
            let contentViewWidth = newWidth
                - self.padding.left
                - self.padding.right
                - safePadding.right
            
            self.topStackViewLayoutSet?.width = self.topStackView.widthAnchor.constraint(equalToConstant: topStackViewWidth)
            self.contentViewLayoutSet?.width = self.contentView.widthAnchor.constraint(equalToConstant: contentViewWidth)
            
            guard self.superview != nil else {
                return
            }
            
            self.layoutIfNeeded()
        }
    }
    
    override open func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isSplitViewCollapsed else {
            return super.hitTest(point, with: event)
        }
        
        return backgroundView.frame.contains(point) ? super.hitTest(point, with: event) : nil
    }
}
