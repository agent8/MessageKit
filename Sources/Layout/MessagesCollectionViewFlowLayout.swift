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
import AVFoundation

/// The layout object used by `MessagesCollectionView` to determine the size of all
/// framework provided `MessageCollectionViewCell` subclasses.
open class MessagesCollectionViewFlowLayout: UICollectionViewFlowLayout {

    open override class var layoutAttributesClass: AnyClass {
        return MessagesCollectionViewLayoutAttributes.self
    }

    /// The width of an item in the `MessagesCollectionView`.
    internal var itemWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        return collectionView.frame.width - sectionInset.left - sectionInset.right
    }

    /// The font to be used by `TextMessageCell` for `MessageData.text(String)` case.
    ///
    /// Note: The default value of this property is `UIFont.preferredFont(forTextStyle: .body)`
    open var messageLabelFont: UIFont {
        didSet {
            emojiLabelFont = messageLabelFont.withSize(2 * messageLabelFont.pointSize)
        }
    }

    /// The font to be used by `TextMessageCell` for `MessageData.emoji(String)` case.
    ///
    /// Note: The default value of this property is 2x the `messageLabelFont`.
    internal var emojiLabelFont: UIFont

    /// Determines the maximum number of `MessageCollectionViewCell` attributes to cache.
    ///
    /// Note: The default value of this property is 500.
    open var attributesCacheMaxSize: Int = 500 {
        didSet {
            layoutContextCache.countLimit = attributesCacheMaxSize
        }
    }

    typealias MessageID = NSString
    
    /// The cache for `MessageCellLayoutContext`.
    /// The key is the `messageId` of the `MessageType`.
    fileprivate var layoutContextCache = NSCache<MessageID, MessageCellLayoutContext>()

    /// The `MessageCellLayoutContext` for the current cell.
    internal var currentLayoutContext: MessageCellLayoutContext!

    // MARK: - Initializers

    public override init() {

        messageLabelFont = UIFont.preferredFont(forTextStyle: .body)
        emojiLabelFont = messageLabelFont.withSize(2 * messageLabelFont.pointSize)

        super.init()

        sectionInset = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        NotificationCenter.default.addObserver(self, selector: #selector(MessagesCollectionViewFlowLayout.handleOrientationChange(_:)), name: .UIDeviceOrientationDidChange, object: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Open

    // MARK: - Attributes

    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

        guard let attributesArray = super.layoutAttributesForElements(in: rect) as? [MessagesCollectionViewLayoutAttributes] else { return nil }

        attributesArray.forEach { attributes in
            if attributes.representedElementCategory == UICollectionElementCategory.cell {
                configure(attributes: attributes)
            }
        }

        return attributesArray
    }

    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {

        guard let attributes = super.layoutAttributesForItem(at: indexPath) as? MessagesCollectionViewLayoutAttributes else { return nil }

        if attributes.representedElementCategory == UICollectionElementCategory.cell {
            configure(attributes: attributes)
        }

        return attributes

    }

    // MARK: - Layout Invalidation

    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if collectionView?.bounds.width != newBounds.width {
            removeAllCachedAttributes()
            return true
        } else {
            return false
        }
    }

    open override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        guard let flowLayoutContext = context as? UICollectionViewFlowLayoutInvalidationContext else { return context }
        flowLayoutContext.invalidateFlowLayoutDelegateMetrics = shouldInvalidateLayout(forBoundsChange: newBounds)
        return flowLayoutContext
    }

    // MARK: - Avatar Size

    /// Returns the `AvatarPosition` for the `MessageType` at a given `IndexPath`.
    ///
    /// - Parameters:
    ///   - message: The `MessageType` for the given `IndexPath`.
    ///   - indexPath: The `IndexPath` for the given `MessageType`.
    ///
    /// - Note: The default implementation of this method retrieves its value from
    ///         `avatarPosition(for:at:in)` in `MessagesLayoutDelegate`.
    open func avatarPosition(for message: MessageType, at indexPath: IndexPath) -> AvatarPosition {
        var position = messagesLayoutDelegate.avatarPosition(for: message, at: indexPath, in: messagesCollectionView)

        switch position.horizontal {
        case .cellTrailing, .cellLeading:
            break
        case .natural:
            position.horizontal = messagesDataSource.isFromCurrentSender(message: message) ? .cellTrailing : .cellLeading
        }
        return position
    }

    /// Returns the `AvatarSize` for the `MessageType` at a given `IndexPath`.
    ///
    /// - Parameters:
    ///   - message: The `MessageType` for the given `IndexPath`.
    ///   - indexPath: The `IndexPath` for the given `MessageType`.
    /// - Note: The default implementation of this method retrieves its value from
    ///         `avatarSize(for:at:in)` in `MessagesLayoutDelegate`.
    open func avatarSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        return messagesLayoutDelegate.avatarSize(for: message, at: indexPath, in: messagesCollectionView)
    }

    // MARK: - Cell Top Label Size

    /// Returns the `LabelAlignment` of the `MessageCollectionViewCell`'s top label
    /// for the `MessageType` at a given `IndexPath`.
    ///
    /// - Parameters:
    ///   - message: The `MessageType` for the given `IndexPath`.
    ///   - indexPath: The `IndexPath` for the given `MessageType`.
    /// - Note: The default implementation of this method retrieves its value from
    ///         `cellTopLabelAlignment(for:at:in)` in `MessagesLayoutDelegate`.
    open func cellTopLabelAlignment(for message: MessageType, at indexPath: IndexPath) -> LabelAlignment {
        return messagesLayoutDelegate.cellTopLabelAlignment(for: message, at: indexPath, in: messagesCollectionView)
    }

    /// Returns the size of the `MessageCollectionViewCell`'s top label
    /// for the `MessageType` at a given `IndexPath`.
    ///
    /// - Parameters:
    ///   - message: The `MessageType` for the given `IndexPath`.
    ///   - indexPath: The `IndexPath` for the given `MessageType`.
    ///
    /// - Note: The default implementation of this method sizes the label to fit.
    open func cellTopLabelSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        let text = messagesDataSource.cellTopLabelAttributedText(for: message, at: indexPath)
        guard let topLabelText = text else { return .zero }
        let maxWidth = cellTopLabelMaxWidth(for: message, at: indexPath)
        return labelSize(for: topLabelText, considering: maxWidth)
    }

    /// Returns the maximum width of the `MessageCollectionViewCell`'s top label
    /// for the `MessageType` at a given `IndexPath`.
    ///
    /// - Parameters:
    ///   - message: The `MessageType` for the given `IndexPath`.
    ///   - indexPath: The `IndexPath` for the given `MessageType`.
    open func cellTopLabelMaxWidth(for message: MessageType, at indexPath: IndexPath) -> CGFloat {
        let alignment = cellTopLabelAlignment(for: message, at: indexPath)
        let position = avatarPosition(for: message, at: indexPath)
        let avatarWidth = avatarSize(for: message, at: indexPath).width
        let containerSize = messageContainerSize(for: message, at: indexPath)
        let messagePadding = messageContainerPadding(for: message, at: indexPath)

        let avatarHorizontal = position.horizontal
        let avatarVertical = position.vertical

        switch (alignment, avatarHorizontal) {

        case (.cellLeading, _), (.cellTrailing, _):
            let width = itemWidth - alignment.insets.horizontal
            return avatarVertical != .cellTop ? width : width - avatarWidth

        case (.cellCenter, _):
            let width = itemWidth - alignment.insets.horizontal
            return avatarVertical != .cellTop ? width : width - (avatarWidth * 2)

        case (.messageTrailing, .cellLeading):
            let width = containerSize.width + messagePadding.left - alignment.insets.horizontal
            return avatarVertical == .cellTop ? width : width + avatarWidth

        case (.messageLeading, .cellTrailing):
            let width = containerSize.width + messagePadding.right - alignment.insets.horizontal
            return avatarVertical == .cellTop ? width : width + avatarWidth

        case (.messageLeading, .cellLeading):
            return itemWidth - avatarWidth - messagePadding.left - alignment.insets.horizontal

        case (.messageTrailing, .cellTrailing):
            return itemWidth - avatarWidth - messagePadding.right - alignment.insets.horizontal

        case (_, .natural):
            fatalError(MessageKitError.avatarPositionUnresolved)
        }
    }

    // MARK: - Cell Bottom Label Size

    /// Returns the `LabelAlignment` of the `MessageCollectionViewCell`'s bottom label
    /// for the `MessageType` at a given `IndexPath`.
    ///
    /// - Parameters:
    ///   - message: The `MessageType` for the given `IndexPath`.
    ///   - indexPath: The `IndexPath` for the given `MessageType`.
    /// - Note: The default implementation of this method retrieves its value from
    ///         `cellBottomLabelAlignment(for:at:in)` in `MessagesLayoutDelegate`.
    open func cellBottomLabelAlignment(for message: MessageType, at indexPath: IndexPath) -> LabelAlignment {
        return messagesLayoutDelegate.cellBottomLabelAlignment(for: message, at: indexPath, in: messagesCollectionView)
    }

    /// Returns the size of the `MessageCollectionViewCell`'s bottom label
    /// for the `MessageType` at a given `IndexPath`.
    ///
    /// - Parameters:
    ///   - message: The `MessageType` for the given `IndexPath`.
    ///   - indexPath: The `IndexPath` for the given `MessageType`.
    ///
    /// - Note: The default implementation of this method sizes the label to fit.
    open func cellBottomLabelSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        let text = messagesDataSource.cellBottomLabelAttributedText(for: message, at: indexPath)
        guard let bottomLabelText = text else { return .zero }
        let maxWidth = cellBottomLabelMaxWidth(for: message, at: indexPath)
        return labelSize(for: bottomLabelText, considering: maxWidth)
    }

    /// Returns the maximum width of the `MessageCollectionViewCell`'s bottom label
    /// for the `MessageType` at a given `IndexPath`.
    ///
    /// - Parameters:
    ///   - message: The `MessageType` for the given `IndexPath`.
    ///   - indexPath: The `IndexPath` for the given `MessageType`.
    open func cellBottomLabelMaxWidth(for message: MessageType, at indexPath: IndexPath) -> CGFloat {

        let alignment = cellBottomLabelAlignment(for: message, at: indexPath)
        let avatarWidth = avatarSize(for: message, at: indexPath).width
        let containerSize = messageContainerSize(for: message, at: indexPath)
        let messagePadding = messageContainerPadding(for: message, at: indexPath)
        let position = avatarPosition(for: message, at: indexPath)

        let avatarHorizontal = position.horizontal
        let avatarVertical = position.vertical

        switch (alignment, avatarHorizontal) {

        case (.cellLeading, _), (.cellTrailing, _):
            let width = itemWidth - alignment.insets.horizontal
            return avatarVertical != .cellBottom ? width : width - avatarWidth

        case (.cellCenter, _):
            let width = itemWidth - alignment.insets.horizontal
            return avatarVertical != .cellBottom ? width : width - (avatarWidth * 2)

        case (.messageTrailing, .cellLeading):
            let width = containerSize.width + messagePadding.left - alignment.insets.horizontal
            return avatarVertical == .cellBottom ? width : width + avatarWidth

        case (.messageLeading, .cellTrailing):
            let width = containerSize.width + messagePadding.right - alignment.insets.horizontal
            return avatarVertical == .cellBottom ? width : width + avatarWidth

        case (.messageLeading, .cellLeading):
            return itemWidth - avatarWidth - messagePadding.left - alignment.insets.horizontal

        case (.messageTrailing, .cellTrailing):
            return itemWidth - avatarWidth - messagePadding.right - alignment.insets.horizontal

        case (_, .natural):
            fatalError(MessageKitError.avatarPositionUnresolved)
        }
    }

    // MARK: - Message Container Size

    /// Returns the insets of the `MessageLabel` in a `TextMessageCell` for
    /// the `MessageType` at a given `IndexPath`.
    ///
    /// - Parameters:
    ///   - message: The `MessageType` for the given `IndexPath`.
    ///   - indexPath: The `IndexPath` for the given `MessageType`.
    ///
    /// - Note: The default implementation of this method retrieves its value from
    ///         `messageLabelInset(for:at:in)` in `MessagesLayoutDelegate`.
    open func messageLabelInsets(for message: MessageType, at indexPath: IndexPath) -> UIEdgeInsets {
        return messagesLayoutDelegate.messageLabelInset(for: message, at: indexPath, in: messagesCollectionView)
    }

    /// Returns the padding around the `MessageContainerView` in a `MessageCollectionViewCell`
    /// for the `MessageType` at a given `IndexPath`.
    ///
    /// - Parameters:
    ///   - message: The `MessageType` for the given `IndexPath`.
    ///   - indexPath: The `IndexPath` for the given `MessageType`.
    ///
    /// - Note: The default implementation of this method retrieves its value from
    ///         `messagePadding(for:at:in)` in `MessagesLayoutDelegate`.
    open func messageContainerPadding(for message: MessageType, at indexPath: IndexPath) -> UIEdgeInsets {
        return messagesLayoutDelegate.messagePadding(for: message, at: indexPath, in: messagesCollectionView)
    }

    /// Returns the maximum width of the `MessageContainerView` in a `MessageCollectionViewCell`
    /// for the `MessageType` at a given `IndexPath`.
    ///
    /// - Parameters:
    ///   - message: The `MessageType` for the given `IndexPath`.
    ///   - indexPath: The `IndexPath` for the given `MessageType`.
    open func messageContainerMaxWidth(for message: MessageType, at indexPath: IndexPath) -> CGFloat {
        let avatarWidth = avatarSize(for: message, at: indexPath).width
        let messagePadding = messageContainerPadding(for: message, at: indexPath)

        switch message.data {
        case .text, .attributedText:
            let messageInsets = messageLabelInsets(for: message, at: indexPath)
            return itemWidth - avatarWidth - messagePadding.horizontal - messageInsets.horizontal
        default:
            return itemWidth - avatarWidth - messagePadding.horizontal
        }
    }

    /// Returns the size of the `MessageContainerView` in a `MessageCollectionViewCell`
    /// for the `MessageType` at a given `IndexPath`.
    ///
    /// - Parameters:
    ///   - message: The `MessageType` for the given `IndexPath`.
    ///   - indexPath: The `IndexPath` for the given `MessageType`.
    open func messageContainerSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        let maxWidth = messageContainerMaxWidth(for: message, at: indexPath)

        var messageContainerSize: CGSize = .zero

        switch message.data {
        case .text(let text):
            let messageInsets = messageLabelInsets(for: message, at: indexPath)
            messageContainerSize = labelSize(for: text, considering: maxWidth, and: messageLabelFont)
            messageContainerSize.width += messageInsets.horizontal
            messageContainerSize.height += messageInsets.vertical
        case .attributedText(let text):
            let messageInsets = messageLabelInsets(for: message, at: indexPath)
            messageContainerSize = labelSize(for: text, considering: maxWidth)
            messageContainerSize.width += messageInsets.horizontal
            messageContainerSize.height += messageInsets.vertical
        case .emoji(let text):
            let messageInsets = messageLabelInsets(for: message, at: indexPath)
            messageContainerSize = labelSize(for: text, considering: maxWidth, and: emojiLabelFont)
            messageContainerSize.width += messageInsets.horizontal
            messageContainerSize.height += messageInsets.vertical
        case .photo, .video:
            let width = messagesLayoutDelegate.widthForMedia(message: message, at: indexPath, with: maxWidth, in: messagesCollectionView)
            let height = messagesLayoutDelegate.heightForMedia(message: message, at: indexPath, with: maxWidth, in: messagesCollectionView)
            messageContainerSize = CGSize(width: width, height: height)
        case .location:
            let width = messagesLayoutDelegate.widthForLocation(message: message, at: indexPath, with: maxWidth, in: messagesCollectionView)
            let height = messagesLayoutDelegate.heightForLocation(message: message, at: indexPath, with: maxWidth, in: messagesCollectionView)
            messageContainerSize = CGSize(width: width, height: height)
        case .custom:
            fatalError(MessageKitError.customDataUnresolvedSize)
        }

        return messageContainerSize
    }

    // MARK: - Cell Size

    /// Returns the height of a `MessageCollectionViewCell`'s content at a given `IndexPath`
    ///
    /// - Parameters:
    ///   - message: The `MessageType` for the given `IndexPath`.
    ///   - indexPath: The `IndexPath` for the given `MessageType`.
    open func cellContentHeight(for message: MessageType, at indexPath: IndexPath) -> CGFloat {
        let avatarVerticalPosition = avatarPosition(for: message, at: indexPath).vertical
        let avatarHeight = avatarSize(for: message, at: indexPath).height
        let messageContainerHeight = messageContainerSize(for: message, at: indexPath).height
        let bottomLabelHeight = cellBottomLabelSize(for: message, at: indexPath).height
        let topLabelHeight = cellTopLabelSize(for: message, at: indexPath).height
        let messageVerticalPadding = messageContainerPadding(for: message, at: indexPath).vertical

        var cellHeight: CGFloat = 0

        switch avatarVerticalPosition {
        case .cellTop:
            cellHeight += max(avatarHeight, topLabelHeight)
            cellHeight += bottomLabelHeight
            cellHeight += messageContainerHeight
            cellHeight += messageVerticalPadding
        case .cellBottom:
            cellHeight += max(avatarHeight, bottomLabelHeight)
            cellHeight += topLabelHeight
            cellHeight += messageContainerHeight
            cellHeight += messageVerticalPadding
        case .messageTop, .messageCenter, .messageBottom:
            cellHeight += max(avatarHeight, messageContainerHeight)
            cellHeight += messageVerticalPadding
            cellHeight += topLabelHeight
            cellHeight += bottomLabelHeight
        }

        return cellHeight
    }

    /// Returns the size for the `MessageCollectionViewCell` at a given `IndexPath`
    /// considering all of the cell's content.
    ///
    /// - Parameters:
    ///   - indexPath: The `IndexPath` of the cell.
    open func sizeForItem(at indexPath: IndexPath) -> CGSize {
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        let context = cellLayoutContext(for: message, at: indexPath)
        guard let itemHeight = context.itemHeight else {
            fatalError("Unexpectedly received a nil itemHeight")
        }
        return CGSize(width: itemWidth, height: itemHeight)
    }
}

// MARK: - Cache Invalidation

extension MessagesCollectionViewFlowLayout {

    /// Removes the cached layout information for a given `MessageType`.
    ///
    /// - Parameters:
    ///   - message: The `MessageType` whose cached layout information is to be removed.
    public func removeCachedAttributes(for message: MessageType) {
        removeCachedAttributes(for: message.messageId)
    }

    /// Removes the cached layout information for a `MessageType` with a given `messageId`.
    ///
    /// - Parameters:
    ///   - messageId: The id for the `MessageType` whose cached layout information is to be removed.
    public func removeCachedAttributes(for messageId: String) {
        layoutContextCache.removeObject(forKey: messageId as NSString)
    }

    /// Removes the cached layout information for all `MessageType`s.
    public func removeAllCachedAttributes() {
        layoutContextCache.removeAllObjects()
    }

    @objc
    private func handleOrientationChange(_ notification: Notification) {
        removeAllCachedAttributes()
        invalidateLayout()
    }
}

// MARK: - MessagesCollectionViewLayoutAttributes

extension MessagesCollectionViewFlowLayout {

    private func configure(attributes: MessagesCollectionViewLayoutAttributes) {

        let indexPath = attributes.indexPath
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        let context = cellLayoutContext(for: message, at: indexPath)

        attributes.avatarSize = context.avatarSize!
        attributes.avatarPosition = context.avatarPosition!

        attributes.messageContainerPadding = context.messageContainerPadding!
        attributes.messageContainerSize = context.messageContainerSize!
        attributes.messageLabelInsets = context.messageLabelInsets!

        attributes.topLabelAlignment = context.topLabelAlignment!
        attributes.topLabelSize = context.topLabelSize!

        attributes.bottomLabelAlignment = context.bottomLabelAlignment!
        attributes.bottomLabelSize = context.bottomLabelSize!

        switch message.data {
        case .emoji:
            attributes.messageLabelFont = emojiLabelFont
        case .text:
            attributes.messageLabelFont = messageLabelFont
        case .attributedText(let text):
            guard let font = text.attribute(.font, at: 0, effectiveRange: nil) as? UIFont else { return }
            attributes.messageLabelFont = font
        default:
            break
        }
    }
}

// MARK: - MessageCellLayoutContext

extension MessagesCollectionViewFlowLayout {

    internal func cellLayoutContext(for message: MessageType, at indexPath: IndexPath) -> MessageCellLayoutContext {
        guard let cachedContext = layoutContextCache.object(forKey: message.messageId as NSString) else {
            let newContext = newCellLayoutContext(for: message, at: indexPath)

            if messagesLayoutDelegate.shouldCacheLayoutAttributes(for: message) {
                layoutContextCache.setObject(newContext, forKey: message.messageId as NSString)
            }
            return newContext
        }
        return cachedContext
    }

    internal func newCellLayoutContext(for message: MessageType, at indexPath: IndexPath) -> MessageCellLayoutContext {
        currentLayoutContext = MessageCellLayoutContext()
        currentLayoutContext.avatarPosition = avatarPosition(for: message, at: indexPath)
        currentLayoutContext.avatarSize = avatarSize(for: message, at: indexPath)
        currentLayoutContext.messageContainerPadding = messageContainerPadding(for: message, at: indexPath)
        currentLayoutContext.messageLabelInsets = messageLabelInsets(for: message, at: indexPath)
        currentLayoutContext.messageContainerMaxWidth = messageContainerMaxWidth(for: message, at: indexPath)
        currentLayoutContext.messageContainerSize = messageContainerSize(for: message, at: indexPath)
        currentLayoutContext.topLabelAlignment = cellTopLabelAlignment(for: message, at: indexPath)
        currentLayoutContext.topLabelMaxWidth = cellTopLabelMaxWidth(for: message, at: indexPath)
        currentLayoutContext.topLabelSize = cellTopLabelSize(for: message, at: indexPath)
        currentLayoutContext.bottomLabelAlignment = cellBottomLabelAlignment(for: message, at: indexPath)
        currentLayoutContext.bottomLabelMaxWidth = cellBottomLabelMaxWidth(for: message, at: indexPath)
        currentLayoutContext.bottomLabelSize = cellBottomLabelSize(for: message, at: indexPath)
        currentLayoutContext.itemHeight = cellContentHeight(for: message, at: indexPath)
        return currentLayoutContext
    }
}

// MARK: - Helpers

extension MessagesCollectionViewFlowLayout {

    /// Returns the size required fit a NSAttributedString considering a constrained max width.
    ///
    /// - Parameters:
    ///   - attributedText: The `NSAttributedString` used to calculate a size that fits.
    ///   - maxWidth: The max width available for the label.
    internal func labelSize(for attributedText: NSAttributedString, considering maxWidth: CGFloat) -> CGSize {

        let estimatedHeight = attributedText.height(considering: maxWidth)
        let estimatedWidth = attributedText.width(considering: estimatedHeight)

        let finalHeight = estimatedHeight.rounded(.up)
        let finalWidth = estimatedWidth > maxWidth ? maxWidth : estimatedWidth.rounded(.up)

        return CGSize(width: finalWidth, height: finalHeight)
    }

    /// Returns the size required to fit a String considering a constrained max width.
    ///
    /// - Parameters:
    ///   - text: The `String` used to calculate a size that fits.
    ///   - maxWidth: The max width available for the label.
    internal func labelSize(for text: String, considering maxWidth: CGFloat, and font: UIFont) -> CGSize {

        let estimatedHeight = text.height(considering: maxWidth, and: font)
        let estimatedWidth = text.width(considering: estimatedHeight, and: font)

        let finalHeight = estimatedHeight.rounded(.up)
        let finalWidth = estimatedWidth > maxWidth ? maxWidth : estimatedWidth.rounded(.up)

        return CGSize(width: finalWidth, height: finalHeight)
    }

    /// Convenience property for accessing the layout object's `MessagesCollectionView`.
    internal var messagesCollectionView: MessagesCollectionView {
        guard let messagesCollectionView = collectionView as? MessagesCollectionView else {
            fatalError(MessageKitError.layoutUsedOnForeignType)
        }
        return messagesCollectionView
    }

    /// Convenience property for unwrapping the `MessagesCollectionView`'s `MessagesDataSource`.
    internal var messagesDataSource: MessagesDataSource {
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
            fatalError(MessageKitError.nilMessagesDataSource)
        }
        return messagesDataSource
    }

    /// Convenience property for unwrapping the `MessagesCollectionView`'s `MessagesLayoutDelegate`.
    internal var messagesLayoutDelegate: MessagesLayoutDelegate {
        guard let messagesLayoutDelegate = messagesCollectionView.messagesLayoutDelegate else {
            fatalError(MessageKitError.nilMessagesLayoutDelegate)
        }
        return messagesLayoutDelegate
    }
}
