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

open class MessagesCollectionView: UICollectionView, UIGestureRecognizerDelegate {

    /// Minimum insets of this UICollectionView.
    let minimumTopContentInset: CGFloat = 5
    let minimumBottomContentInset: CGFloat = 5
    
    // MARK: - Properties

    open weak var messagesDataSource: MessagesDataSource?

    open weak var messagesDisplayDelegate: MessagesDisplayDelegate?

    open weak var messagesLayoutDelegate: MessagesLayoutDelegate?

    open weak var messageCellDelegate: MessageCellDelegate?
    
    open weak var voiceMessageCellDelegate: VoiceMessageCellDelegate?

    open var showsDateHeaderAfterTimeInterval: TimeInterval = 3600

    open override var bounds: CGRect {
        didSet {
            if oldValue.size.width != bounds.size.width {
                messagesDisplayDelegate?.boundsDidChange(from: oldValue)
            }
        }
        
        willSet {
            if newValue.size.width != bounds.size.width {
                messagesDisplayDelegate?.boundsWillChange(to: newValue)
            }
        }
    }
    var indexPathForLastItem: IndexPath? {

        let lastSection = numberOfSections - 1
        guard lastSection >= 0, numberOfItems(inSection: lastSection) > 0 else { return nil }
        return IndexPath(item: numberOfItems(inSection: lastSection) - 1, section: lastSection)

    }
    
    var verticalOffsetForBottom: CGFloat {
        let contentSize = collectionViewLayout.collectionViewContentSize.height
        if contentSize <= heightAfterContentInsets {
            return verticalOffsetForTop // content too little to scroll
        }
        var offset = contentSize - bounds.size.height + contentInset.bottom
        if #available(iOS 11.0, *) {
            offset += safeAreaInsets.bottom
        }
        return offset
    }
    
    var verticalOffsetForTop: CGFloat {
        var topInset = contentInset.top
        if #available(iOS 11.0, *) {
            topInset += safeAreaInsets.top
        }
        return -topInset
    }
    
    var heightAfterContentInsets: CGFloat {
        var height = bounds.size.height
        height -= contentInset.top
        height -= contentInset.bottom
        if #available(iOS 11.0, *) {
            height -= safeAreaInsets.top
            height -= safeAreaInsets.bottom
        }
        return height
    }

    // MARK: - Initializers

    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        backgroundColor = .white
        setupGestureRecognizers()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public convenience init() {
        self.init(frame: .zero, collectionViewLayout: MessagesCollectionViewFlowLayout())
    }

    // MARK: - Methods
    
    func setupGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGesture.delaysTouchesBegan = true
        addGestureRecognizer(tapGesture)
    }
    
    @objc
    open func handleTapGesture(_ gesture: UIGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        let touchLocation = gesture.location(in: self)
        guard let indexPath = indexPathForItem(at: touchLocation) else { return }
        
        let cell = cellForItem(at: indexPath) as? MessageCollectionViewCell
        cell?.handleTapGesture(gesture)
    }

    public func scrollToBottom(animated: Bool = false) {
        let collectionViewContentHeight = collectionViewLayout.collectionViewContentSize.height
        
        performBatchUpdates(nil) { _ in
            let bottom = CGRect(0.0, collectionViewContentHeight - 1.0, 1.0, 1.0)
            if !animated {
                self.scrollRectToVisible(bottom, animated: false)
            } else if self.isNearBottom(threshold: self.heightAfterContentInsets * 2) {
                self.scrollRectToVisible(bottom, animated: true)
            } else { // for long scrolls, use transition animations for a smoother effect
                let transition = CATransition()
                transition.duration = 0.2
                transition.type = kCATransitionPush
                transition.subtype = kCATransitionFromTop
                self.layer.add(transition, forKey: "scrollToBottom")
                self.scrollRectToVisible(bottom, animated: false)
            }
        }
    }
    
    /// Checks if the collection view is at most `threshold` distance away from the bottom.
    func isNearBottom(threshold: CGFloat) -> Bool {
        return contentOffset.y >= verticalOffsetForBottom - threshold
    }
    
    /// Checks if the collection view is at most `threshold` distance away from the top.
    func isNearTop(threshold: CGFloat) -> Bool {
        return contentOffset.y <= verticalOffsetForTop + threshold
    }
    
    public func reloadDataAndKeepOffset() {
        // calculate the offset and reloadData
        let beforeContentSize = contentSize
        reloadData()
        layoutIfNeeded()
        let afterContentSize = contentSize
        
        // reset the contentOffset after data is updated
        let newOffset = CGPoint(
            x: contentOffset.x + (afterContentSize.width - beforeContentSize.width),
            y: contentOffset.y + (afterContentSize.height - beforeContentSize.height))
        contentOffset = newOffset

        /* My previous implementation (it works too but above seems more consistent for some reason) */
        /*
        let beforeContentSize = collectionViewLayout.collectionViewContentSize
        if beforeContentSize.height <= heightAfterContentInsets { // content at bottom
            reloadData()
            layoutIfNeeded()
            scrollToBottom()
            return
        }
        let beforeDistanceToBottom = beforeContentSize.height - contentOffset.y - bounds.size.height
        reloadData()
        layoutIfNeeded()
        let newYOffset = contentSize.height - bounds.size.height - beforeDistanceToBottom
        contentOffset.y = newYOffset
         */
    }
    
    // MARK:- UIGestureRecognizerDelegate

    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            if panGesture is SwipeReplyPanGestureRecognizer {
                let velocity = panGesture.velocity(in: panGesture.view)
                if abs(velocity.y) > abs(velocity.x) {
                    return false
                }
                
                if let indexPath = indexPathForItem(at: panGesture.location(in: self)),
                    let cell = cellForItem(at: indexPath) as? MessageCollectionViewCell {
                    let rect = CGRect(x: cell.frame.origin.x,
                                      y: cell.frame.origin.y + cell.messageContainerView.frame.origin.y,
                                      width: cell.frame.size.width,
                                      height: cell.messageContainerView.frame.size.height)
                    return rect.contains(panGesture.location(in: self))
                }
            }
        }

        return true
    }
}
