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

open class MessageKitDateFormatter {

    // MARK: - Properties

    public static let shared = MessageKitDateFormatter()

    private let formatter = DateFormatter()

    // MARK: - Initializer

    private init() {}

    // MARK: - Methods
    
    private enum ConfigInfo {
        case today, yesterday, none
    }

    public func string(from date: Date) -> String {
        switch configureDateFormatter(for: date) {
        case .today:
            return "Today \(formatter.string(from: date))"
        case .yesterday:
            return "Yesterday \(formatter.string(from: date))"
        case .none:
            return formatter.string(from: date)
        }
    }

    public func attributedString(from date: Date, with attributes: [NSAttributedStringKey: Any]) -> NSAttributedString {
        let dateString = string(from: date)
        return NSAttributedString(string: dateString, attributes: attributes)
    }
    
    public func iMessageStyle(from date: Date, ofSize size: CGFloat = 10) -> NSAttributedString {
        let dateString = string(from: date)
        let pattern = "(^|\\s*)[0-9]{1,2}:[0-9]{1,2}\\s*((AM|PM)\\s*)?$" // bold everything but the numerical time
        let iMessageDate = NSMutableAttributedString(string: dateString)
        let boldFont: UIFont = .boldSystemFont(ofSize: size)
        let normalFont: UIFont = .systemFont(ofSize: size)
        
        let regex = try? NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
        if let unboldRange = regex?.matches(in: dateString, range: NSRange(dateString.startIndex..., in: dateString)).first {
            iMessageDate.addAttribute(.font, value: boldFont, range: NSMakeRange(0, unboldRange.range.location - 1))
            iMessageDate.addAttribute(.font, value: normalFont, range: unboldRange.range)
            let rangeEndLocation = unboldRange.range.location + unboldRange.range.length
            if rangeEndLocation < iMessageDate.length {
                iMessageDate.addAttribute(.font, value: boldFont, range: NSMakeRange(rangeEndLocation, iMessageDate.length - 1))
            }
        } else {
            iMessageDate.addAttribute(.font, value: normalFont, range: NSMakeRange(0, iMessageDate.length))
        }
        
        let centerStyle = NSMutableParagraphStyle()
        centerStyle.alignment = .center
        iMessageDate.addAttribute(.paragraphStyle, value: centerStyle, range: NSMakeRange(0, iMessageDate.length))
        
        return iMessageDate as NSAttributedString
    }

    private func configureDateFormatter(for date: Date) -> ConfigInfo {
        switch true {
        case Calendar.current.isDateInToday(date):
            formatter.dateFormat = "h:mm a"
            return .today
        case Calendar.current.isDateInYesterday(date):
            formatter.dateFormat = "h:mm a"
            return .yesterday
        case Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear):
            formatter.dateFormat = "EEEE h:mm a"
        case Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year):
            formatter.dateFormat = "E, MMM d, h:mm a"
        default:
            formatter.dateFormat = "MMM d, yyyy, h:mm a"
        }
        return .none
    }
    
}
