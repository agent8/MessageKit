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

import Foundation

/// MessageInputBarDelegate is a protocol that can recieve notifications from the MessageInputBar
public protocol MessageInputBarDelegate: AnyObject {
    
    /// Called when the default send button has been selected
    ///
    /// - Parameters:
    ///   - inputBar: The MessageInputBar
    ///   - text: The current text in the MessageInputBar's InputTextView
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String)
    
    /// Called when the instrinsicContentSize of the MessageInputBar has changed. Can be used for adjusting content insets
    /// on other views to make sure the MessageInputBar does not cover up any other view
    ///
    /// - Parameters:
    ///   - inputBar: The MessageInputBar
    ///   - size: The new instrinsicContentSize
    func messageInputBar(_ inputBar: MessageInputBar, didChangeIntrinsicContentTo size: CGSize)
    
    /// Called when the MessageInputBar's InputTextView's text has changed. Useful for adding your own logic without the
    /// need of assigning a delegate or notification
    ///
    /// - Parameters:
    ///   - inputBar: The MessageInputBar
    ///   - text: The current text in the MessageInputBar's InputTextView
    func messageInputBar(_ inputBar: MessageInputBar, textViewTextDidChangeTo text: String)
    
    /// Called when the MessageInputBar's an image is pasted into InputTextView.
    ///
    /// - Parameters:
    ///   - inputBar: The MessageInputBar
    ///   - image: The UIImage pasted
    func messageInputBarTextViewDidPasteImage(_ image: UIImage)
    
    /// Called when a gif is pasted into InputTextView.
    ///
    /// - Parameters:
    ///   - inputBar: The MessageInputBar
    ///   - gif: The Gif pasted
    func messageInputBarTextViewDidPasteGif(_ gif: FLAnimatedImage, type: String)
    
    /// Called when the MessageInputBar's attachment is removed.
    ///
    /// - Parameters:
    ///   - inputBar: The MessageInputBar
    ///   - attachment: The attachment removed
    func messageInputBar(_ inputBar: MessageInputBar, didRemoveAttachment attachment: ChatAttachment)
}

public extension MessageInputBarDelegate {
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {}
    
    func messageInputBar(_ inputBar: MessageInputBar, didChangeIntrinsicContentTo size: CGSize) {}
    
    func messageInputBar(_ inputBar: MessageInputBar, textViewTextDidChangeTo text: String) {}
    
    func messageInputBarTextViewDidPasteImage(_ image: UIImage) {}
    
    func messageInputBarTextViewDidPasteGif(_ gif: FLAnimatedImage, type: String) {}
    
    func messageInputBar(_ inputBar: MessageInputBar, didRemoveAttachment attachment: ChatAttachment) {}
}
