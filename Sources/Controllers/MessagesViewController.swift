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

open class MessagesViewController: UIViewController {
    
    // MARK: - Properties [Public]

    /// The `MessagesCollectionView` managed by the messages view controller object.
    open var messagesCollectionView = MessagesCollectionView()

    /// The `MessageInputBar` used as the `inputAccessoryView` in the view controller.
    open var messageInputBar = MessageInputBar()

    /// A Boolean value that determines whether the `MessagesCollectionView` scrolls to the
    /// bottom whenever the `InputTextView` begins editing.
    ///
    /// The default value of this property is `false`.
    open var scrollsToBottomOnKeybordBeginsEditing: Bool = false
    
    /// A Boolean value that determines whether the `MessagesCollectionView`
    /// maintains it's current position when the height of the `MessageInputBar` changes.
    ///
    /// The default value of this property is `false`.
    open var maintainPositionOnKeyboardFrameChanged: Bool = false

    open override var canBecomeFirstResponder: Bool {
        return true
    }

    open override var inputAccessoryView: UIView? {
        return messageInputBar
    }

    open override var shouldAutorotate: Bool {
        return false
    }

    /// A Boolean value used to determine if `viewDidLayoutSubviews()` has been called.
    private var isFirstLayout: Bool = true
    
    /// Indicated selected indexPath when handle menu action
    var selectedIndexPathForMenu: IndexPath?

    var messageCollectionViewBottomInset: CGFloat = 0 {
        didSet {
            messagesCollectionView.contentInset.bottom =
                messageCollectionViewBottomInset + messagesCollectionView.minimumBottomContentInset
            messagesCollectionView.scrollIndicatorInsets.bottom = messageCollectionViewBottomInset
        
            updateScrollToBottomButtonBottomConstraint(
                oldBottomInset: oldValue,
                newBottomInset: messageCollectionViewBottomInset)
            updateScrollToBottomButton()
        }
    }

    /// The bottom constraint of the scroll to bottom button that is tied to the
    /// content inset of the collection view.
    private var scrollToBottomButtonBottomConstraint: NSLayoutConstraint?
    
    /// A button that when tapped, scrolls the collection view to the bottom.
    open var scrollToBottomButtonView = ScrollToBottomButtonView()
    
    // MARK: - View Life Cycle

    open override func viewDidLoad() {
        super.viewDidLoad()
        setupDefaults()
        setupSubviews()
        setupConstraints()
        registerReusableViews()
        setupDelegates()
        addMenuControllerObservers()
        addObservers()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    open override func viewDidLayoutSubviews() {
        // Hack to prevent animation of the contentInset after viewDidAppear
        if isFirstLayout {
            defer { isFirstLayout = false }
            addKeyboardObservers()
            messageCollectionViewBottomInset = keyboardOffsetFrame.height
        }
        adjustScrollViewInset()
    }

    // MARK: - Initializers

    deinit {
        removeKeyboardObservers()
        removeMenuControllerObservers()
        removeObservers()
        clearMemoryCache()
    }

    // MARK: - Methods [Private]

    /// Sets the default values for the MessagesViewController
    private func setupDefaults() {
        extendedLayoutIncludesOpaqueBars = true
        automaticallyAdjustsScrollViewInsets = false
        view.backgroundColor = EdoColor.whiteBackground
        messagesCollectionView.keyboardDismissMode = .interactive
        messagesCollectionView.alwaysBounceVertical = true
    }

    /// Sets the delegate and dataSource of the messagesCollectionView property.
    private func setupDelegates() {
        messagesCollectionView.delegate = self
        messagesCollectionView.dataSource = self
    }

    /// Adds the messagesCollectionView to the controllers root view.
    private func setupSubviews() {
        view.addSubview(messagesCollectionView)
        setupScrollToBottomButton()
    }

    /// Registers all cells and supplementary views of the messagesCollectionView property.
    private func registerReusableViews() {
        messagesCollectionView.register(TextMessageCell.self)
        messagesCollectionView.register(MediaMessageCell.self)
        messagesCollectionView.register(LocationMessageCell.self)
        messagesCollectionView.register(PhotoMessageCell.self)
        messagesCollectionView.register(DocumentMessageCell.self)
        messagesCollectionView.register(GifMessageCell.self)

        messagesCollectionView.register(MessageFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter)
        messagesCollectionView.register(MessageHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
        messagesCollectionView.register(MessageDateHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
    }

    /// Sets the constraints of the `MessagesCollectionView`.
    private func setupConstraints() {
        messagesCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        let top = messagesCollectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: topLayoutGuide.length)
        let bottom = messagesCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        if #available(iOS 11.0, *) {
            let leading = messagesCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor)
            let trailing = messagesCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
            NSLayoutConstraint.activate([top, bottom, trailing, leading])
        } else {
            let leading = messagesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
            let trailing = messagesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            NSLayoutConstraint.activate([top, bottom, trailing, leading])
        }
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(clearMemoryCache), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    @objc private func clearMemoryCache() {
        MessageStyle.bubbleImageCache.removeAllObjects()
    }
    
    // MARK: Scroll to bottom button

    private func updateScrollToBottomButtonBottomConstraint(oldBottomInset old: CGFloat, newBottomInset new: CGFloat) {
        
        guard let bottomConstraint = scrollToBottomButtonBottomConstraint else {
            return
        }
        
        bottomConstraint.constant = bottomConstraint.constant - old + new
        if new >= old {
            view.layoutIfNeeded()
        } else { // only animate drops in inset
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           options: .curveEaseOut,
                           animations: { [weak self] in self?.view.layoutIfNeeded() })
        }
    }
    
    private func setupScrollToBottomButton() {

        view.addSubview(scrollToBottomButtonView)
        
        let padding = messagesCollectionView.scrollIndicatorInsets.right + 8
        
        if #available(iOS 11.0, *) {
            scrollToBottomButtonBottomConstraint =
                view.safeAreaLayoutGuide
                    .bottomAnchor
                    .constraint(equalTo: scrollToBottomButtonView.bottomAnchor,
                                constant: padding + messageCollectionViewBottomInset)
        } else {
            scrollToBottomButtonBottomConstraint =
                NSLayoutConstraint.constraints(withVisualFormat: "V:[buttonView]-(padding)-|",
                                               options: LAYOUT_OPT_NONE,
                                               metrics: ["padding": padding + messageCollectionViewBottomInset],
                                               views: ["buttonView": scrollToBottomButtonView]).first
        }
        
        if let constraint = scrollToBottomButtonBottomConstraint {
            view.addConstraint(constraint)
        }
        
        view.addConstraintsForFloatRight(scrollToBottomButtonView, padding: padding, useSafeArea: true)
        
        scrollToBottomButtonView.translatesAutoresizingMaskIntoConstraints = false
        scrollToBottomButtonView.isHidden = true
        scrollToBottomButtonView.button.addTarget(self,
                                                  action: #selector(didTapScrollToBottomButton),
                                                  for: .touchUpInside)
    }
    
    @objc private func didTapScrollToBottomButton() {
        messagesCollectionView.scrollToBottom(animated: true)
    }
}

// MARK: - UIScrollViewDelegate

extension MessagesViewController: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateScrollToBottomButton()
    }
    
    func updateScrollToBottomButton() {
        let shouldHideButton = messagesCollectionView.isNearBottom(threshold: messagesCollectionView.heightAfterContentInsets / 2)
        if shouldHideButton != scrollToBottomButtonView.isHidden {
            UIView.transition(
                with: scrollToBottomButtonView,
                duration: 0.25,
                options: .transitionCrossDissolve,
                animations: {
                    self.scrollToBottomButtonView.isHidden = !self.scrollToBottomButtonView.isHidden
                }
            )
        }
    }
}
